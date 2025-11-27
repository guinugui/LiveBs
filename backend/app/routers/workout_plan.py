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
            """SELECT id, plan_name, plan_summary, workout_data, created_at, user_id 
               FROM saved_workout_plans 
               WHERE user_id = %s 
               ORDER BY created_at DESC""",
            (user_id,)
        )
        plans = cursor.fetchall()
    
    # CRÍTICO: Garantir que workout_data seja sempre string JSON para o frontend
    for plan in plans:
        if 'workout_data' in plan:
            if isinstance(plan['workout_data'], dict):
                # PostgreSQL retornou dict - converter para JSON string
                plan['workout_data'] = json.dumps(plan['workout_data'], ensure_ascii=False)
                print(f"[WORKOUT_API] ✅ Convertido dict para JSON string - Plano: {plan.get('plan_name', 'N/A')}")
            elif isinstance(plan['workout_data'], str):
                # Verificar se já é JSON válido
                try:
                    # Tentar fazer parse para validar
                    json.loads(plan['workout_data'])
                    print(f"[WORKOUT_API] ✅ JSON string válido - Plano: {plan.get('plan_name', 'N/A')}")
                except json.JSONDecodeError:
                    print(f"[WORKOUT_API] ⚠️ JSON string inválido para plano {plan.get('id', 'unknown')}")
                    print(f"[WORKOUT_API] 📊 Primeiros 200 chars: {str(plan['workout_data'])[:200]}...")
            else:
                print(f"[WORKOUT_API] ⚠️ Tipo inesperado para workout_data: {type(plan['workout_data'])}")
    
    return plans

@router.post("/", status_code=status.HTTP_201_CREATED)
def create_workout_plan(workout_data: dict, current_user = Depends(get_current_user)):
    """Cria um novo plano de treino baseado no questionário"""
    user_id = current_user['id']
    
    print(f"[WORKOUT_API] 📋 Dados recebidos do questionário: {workout_data}")
    
    try:
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
            if isinstance(ai_response, dict) and 'days' in ai_response:
                week_number = ai_response.get('week', 1)
                workout_plan = {
                    "plan_name": f"Plano de Treino Semanal {week_number}",
                    "plan_summary": f"Treino personalizado para {combined_data.get('days_per_week', 4)} dias por semana",
                    "workout_schedule": ai_response.get('days', []),
                    "week": week_number,
                    "fitness_level": combined_data.get('fitness_level', 'intermediario'),
                    "session_duration": combined_data.get('session_duration', 45),
                    "workout_type": combined_data.get('workout_type', 'home')
                }
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
        
        # Salvar no banco - SEMPRE como string JSON
        plan_id = str(uuid4())
        
        # Garantir que workout_plan seja convertido para string JSON
        if isinstance(workout_plan, dict):
            workout_data_json = json.dumps(workout_plan, ensure_ascii=False)
        else:
            workout_data_json = str(workout_plan)
            
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
                    workout_data_json
                )
            )
            result = cursor.fetchone()
            
        # Construir resposta no formato esperado
        if result:
            # pg8000 retorna lista: [id, plan_name, plan_summary, workout_data, created_at, user_id]
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
            
            print(f"✅ Plano de treino criado: {workout_plan['plan_name']} para usuário {user_id}")
            return new_plan
        else:
            raise Exception("Erro ao salvar plano no banco de dados")
        
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
            """SELECT id, plan_name, plan_summary, workout_data, created_at, user_id 
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
    
    # CRÍTICO: Garantir que workout_data seja string JSON para o frontend
    if plan and 'workout_data' in plan:
        if isinstance(plan['workout_data'], dict):
            # PostgreSQL retornou dict - converter para JSON string
            plan['workout_data'] = json.dumps(plan['workout_data'], ensure_ascii=False)
            print(f"[WORKOUT_API] ✅ Detalhes - Convertido dict para JSON string: {plan.get('plan_name', 'N/A')}")
        elif isinstance(plan['workout_data'], str):
            print(f"[WORKOUT_API] ✅ Detalhes - JSON string recebido: {plan.get('plan_name', 'N/A')}")
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