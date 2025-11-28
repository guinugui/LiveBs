from fastapi import APIRouter, HTTPException, Depends, status
from app.database import db
from app.routers.auth import get_current_user
from app.ai_service import generate_workout_plan
import json
from uuid import uuid4

router = APIRouter(prefix="/workout-plan", tags=["Workout Plan"])

@router.get("/")
def get_saved_workout_plans(current_user = Depends(get_current_user)):
    """Retorna todos os planos de treino salvos do usuário"""
    user_id = current_user['id']
    
    with db.get_db_cursor() as cursor:
        cursor.execute(
            """SELECT id, plan_name, plan_summary, workout_data, markdown_content, created_at, user_id 
               FROM saved_workout_plans 
               WHERE user_id = %s 
               ORDER BY created_at DESC""",
            (user_id,)
        )
        plans = cursor.fetchall()
    
    # CRÍTICO: Priorizar markdown_content sobre workout_data quando disponível
    processed_plans = []
    for plan in plans:
        # Converter lista para dict se necessário (pg8000 retorna lista)
        if isinstance(plan, (list, tuple)):
            plan_dict = {
                'id': plan[0],
                'plan_name': plan[1],
                'plan_summary': plan[2],
                'workout_data': plan[3],
                'markdown_content': plan[4] if len(plan) > 4 else None,
                'created_at': plan[5] if len(plan) > 5 else None,
                'user_id': plan[6] if len(plan) > 6 else None
            }
            plan = plan_dict
        
        # Se tem markdown_content, usar ele como workout_data
        if plan.get('markdown_content'):
            plan['workout_data'] = plan['markdown_content']  # Usar markdown diretamente
            print(f"[WORKOUT_API] ✅ Usando MARKDOWN para plano: {plan.get('plan_name', 'N/A')}")
        elif plan.get('workout_data'):
            workout_data = plan['workout_data']
            if isinstance(workout_data, dict):
                # PostgreSQL retornou dict - converter para JSON string
                plan['workout_data'] = json.dumps(workout_data, ensure_ascii=False)
                print(f"[WORKOUT_API] ✅ Convertido dict para JSON string - Plano: {plan.get('plan_name', 'N/A')}")
            elif isinstance(workout_data, str):
                # Verificar se já é JSON válido
                try:
                    # Tentar fazer parse para validar
                    json.loads(workout_data)
                    print(f"[WORKOUT_API] ✅ JSON string válido - Plano: {plan.get('plan_name', 'N/A')}")
                except json.JSONDecodeError:
                    print(f"[WORKOUT_API] ⚠️ JSON string inválido para plano {plan.get('id', 'unknown')}")
                    print(f"[WORKOUT_API] 📊 Primeiros 200 chars: {str(workout_data)[:200]}...")
            else:
                print(f"[WORKOUT_API] ⚠️ Tipo inesperado para workout_data: {type(workout_data)}")
        
        processed_plans.append(plan)
    
    return processed_plans

@router.post("/", status_code=status.HTTP_201_CREATED)
def create_workout_plan(workout_data: dict, current_user = Depends(get_current_user)):
    """Cria um novo plano de treino baseado no questionário"""
    user_id = current_user['id']
    
    print(f"[WORKOUT_API] 📋 Dados recebidos do questionário: {workout_data}")
    
    try:
        # Verificar se já vem com conteúdo markdown (do AIWorkoutGeneratorPage)
        if 'markdown_content' in workout_data and workout_data['markdown_content']:
            print(f"[WORKOUT_API] 📝 Recebido treino em formato MARKDOWN - {len(workout_data['markdown_content'])} caracteres")
            
            # Salvar diretamente como markdown - não processar com IA
            plan_name_final = f"Treino {'na Academia' if workout_data.get('workout_type') == 'gym' else 'em Casa'} - Semana 1"
            plan_summary_final = f"Treino personalizado gerado por IA para {workout_data.get('days_per_week', 3)} dias por semana"
            markdown_content = workout_data['markdown_content']  # Conteúdo já em markdown
            
            # Salvar no banco usando a nova coluna markdown_content
            plan_id = str(uuid4())
            
            with db.get_db_cursor() as cursor:
                cursor.execute(
                    """INSERT INTO saved_workout_plans 
                       (id, user_id, plan_name, plan_summary, workout_data, markdown_content) 
                       VALUES (%s, %s, %s, %s, %s, %s)
                       RETURNING id, plan_name, plan_summary, workout_data, markdown_content, created_at, user_id""",
                    (
                        plan_id,
                        user_id,
                        plan_name_final,
                        plan_summary_final,
                        json.dumps({"type": "markdown", "source": "ai_generator"}),  # JSON simples para manter compatibilidade
                        markdown_content  # Markdown na coluna específica
                    )
                )
                result = cursor.fetchone()
            
            if result:
                new_plan = {
                    'id': result[0],
                    'plan_name': result[1], 
                    'plan_summary': result[2],
                    'workout_data': result[4] if result[4] else result[3],  # Usar markdown_content se disponível
                    'created_at': result[5],
                    'user_id': result[6]
                }
                
                print(f"✅ Plano MARKDOWN criado: {plan_name_final} para usuário {user_id}")
                return new_plan
            else:
                raise Exception("Erro ao salvar plano markdown no banco de dados")
            
        else:
            # Fluxo original para outros tipos de treino
            # Buscar perfil do usuário para personalizar o treino
            with db.get_db_cursor() as cursor:
                cursor.execute(
                    """SELECT weight, height, age, gender, target_weight, activity_level
                       FROM profiles WHERE user_id = %s""",
                    (user_id,)
                )
                profile = cursor.fetchone()
            
            # Gerar plano com IA (combining profile data with questionnaire)
            combined_data = {**workout_data}  # Start with questionnaire data
            if profile:
                # Add profile data to questionnaire
                combined_data.update({
                    'age': profile.get('age'),
                    'weight': profile.get('weight'), 
                    'height': profile.get('height'),
                    'activity_level': profile.get('activity_level'),
                    'objective': profile.get('objective')
                })
            
            # Gerar plano com IA
            try:
                ai_response = generate_workout_plan(combined_data)
                print(f"✅ Plano de treino gerado com sucesso")
                print(f"📋 Estrutura: {list(ai_response.keys()) if isinstance(ai_response, dict) else 'Não é dict'}")
                
                # Adaptar estrutura da resposta OpenAI para formato esperado pelo banco
                if isinstance(ai_response, dict):
                    # Obter dados do AI ou usar fallbacks
                    workout_type_final = ai_response.get('workout_type', combined_data.get('workout_type', 'home'))
                    
                    # GARANTIR nome correto baseado no tipo
                    if workout_type_final == "home":
                        plan_name_correct = "Treino em Casa - Semana 1"
                        plan_summary_correct = f"Plano de treino em casa personalizado para {combined_data.get('days_per_week', 3)} dias por semana"
                        print(f"[WORKOUT_API] 🏠 CASA: Aplicando nome '{plan_name_correct}'")
                    else:
                        plan_name_correct = "Treino na Academia - Semana 1"  
                        plan_summary_correct = f"Plano de treino na academia personalizado para {combined_data.get('days_per_week', 3)} dias por semana"
                        print(f"[WORKOUT_API] 🏋️ ACADEMIA: Aplicando nome '{plan_name_correct}'")
                    
                    # Construir estrutura final
                    workout_plan = {
                        "plan_name": plan_name_correct,
                        "plan_summary": plan_summary_correct,
                        "days": ai_response.get('days', ai_response.get('workout_schedule', [])),  # Aceitar ambos
                        "week": ai_response.get('week', 1),
                        "fitness_level": combined_data.get('fitness_level', 'intermediario'),
                        "session_duration": combined_data.get('session_duration', 45),
                        "workout_type": workout_type_final
                    }
                    print(f"[WORKOUT_API] ✅ Plano padronizado: {workout_plan['plan_name']} (tipo: {workout_plan['workout_type']})")
                else:
                    raise ValueError("Estrutura de resposta inválida da OpenAI")
                
            except Exception as e:
                print(f"❌ Erro ao gerar plano de treino: {e}")
                # Criar um plano padrão em caso de erro
                workout_plan = {
                    "plan_name": "Plano de Treino Personalizado",
                    "plan_summary": "Plano gerado automaticamente devido a erro na resposta da IA",
                    "workout_schedule": [],
                    "important_notes": ["Plano gerado automaticamente"],
                    "progression_tips": "Consulte um profissional"
                }
            
            # Salvar JSON estruturado (fluxo antigo)
            plan_id = str(uuid4())
            final_workout_data = json.dumps(workout_plan, ensure_ascii=False)
            
            with db.get_db_cursor() as cursor:
                cursor.execute(
                    """INSERT INTO saved_workout_plans 
                       (id, user_id, plan_name, plan_summary, workout_data) 
                       VALUES (%s, %s, %s, %s, %s)
                       RETURNING id, plan_name, plan_summary, workout_data, created_at, user_id""",
                    (
                        plan_id,
                        user_id,
                        workout_plan['plan_name'],
                        workout_plan.get('plan_summary', ''),
                        final_workout_data
                    )
                )
                result = cursor.fetchone()
                
            if result:
                new_plan = {
                    'id': result[0],
                    'plan_name': result[1], 
                    'plan_summary': result[2],
                    'workout_data': result[3],
                    'created_at': result[4],
                    'user_id': result[5]
                }
                
                # Garantir que workout_data seja string JSON para o frontend
                if isinstance(new_plan['workout_data'], dict):
                    new_plan['workout_data'] = json.dumps(new_plan['workout_data'], ensure_ascii=False)
                    print(f"[WORKOUT_API] ✅ Criação - Convertido dict para JSON string")
                
                print(f"✅ Plano de treino JSON criado: {workout_plan['plan_name']} para usuário {user_id}")
                return new_plan
            else:
                raise Exception("Erro ao salvar plano JSON no banco de dados")
        
    except Exception as e:
        print(f"❌ Erro ao criar plano de treino: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro interno: {str(e)}"
        )

@router.get("/{plan_id}")
def get_workout_plan_details(plan_id: str, current_user = Depends(get_current_user)):
    """Retorna detalhes específicos de um plano de treino"""
    user_id = current_user['id']
    
    with db.get_db_cursor() as cursor:
        cursor.execute(
            """SELECT id, plan_name, plan_summary, workout_data, markdown_content, created_at, user_id 
               FROM saved_workout_plans 
               WHERE id = %s AND user_id = %s""",
            (plan_id, user_id)
        )
        plan = cursor.fetchone()
    
    if not plan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Plano de treino não encontrado"
        )
    
    # Converter lista para dict se necessário (pg8000 retorna lista)
    if isinstance(plan, (list, tuple)):
        plan_dict = {
            'id': plan[0],
            'plan_name': plan[1],
            'plan_summary': plan[2],
            'workout_data': plan[3],
            'markdown_content': plan[4] if len(plan) > 4 else None,
            'created_at': plan[5] if len(plan) > 5 else None,
            'user_id': plan[6] if len(plan) > 6 else None
        }
        plan = plan_dict
    
    # CRÍTICO: Priorizar markdown_content sobre workout_data quando disponível
    if isinstance(plan, dict):
        if plan.get('markdown_content'):
            plan['workout_data'] = plan['markdown_content']  # Usar markdown diretamente
            print(f"[WORKOUT_API] ✅ Detalhes - Usando MARKDOWN: {plan.get('plan_name', 'N/A')}")
        elif plan.get('workout_data'):
            if isinstance(plan['workout_data'], dict):
                # PostgreSQL retornou dict - converter para JSON string
                plan['workout_data'] = json.dumps(plan['workout_data'], ensure_ascii=False)
                print(f"[WORKOUT_API] ✅ Detalhes - Convertido dict para JSON string: {plan.get('plan_name', 'N/A')}")
            elif isinstance(plan['workout_data'], str):
                print(f"[WORKOUT_API] ✅ Detalhes - String recebida: {plan.get('plan_name', 'N/A')}")
            else:
                print(f"[WORKOUT_API] ⚠️ Detalhes - Tipo inesperado: {type(plan['workout_data'])}")
    
    return plan

@router.delete("/{plan_id}")
def delete_workout_plan(plan_id: str, current_user = Depends(get_current_user)):
    """Deleta um plano de treino específico"""
    user_id = current_user['id']
    
    with db.get_db_cursor() as cursor:
        # Verificar se o plano existe e pertence ao usuário
        cursor.execute(
            "SELECT id FROM saved_workout_plans WHERE id = %s AND user_id = %s",
            (plan_id, user_id)
        )
        plan = cursor.fetchone()
        
        if not plan:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Plano de treino não encontrado"
            )
        
        # Deletar o plano
        cursor.execute(
            "DELETE FROM saved_workout_plans WHERE id = %s AND user_id = %s",
            (plan_id, user_id)
        )
    
    return {"message": "Plano de treino deletado com sucesso"}