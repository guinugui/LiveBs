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
    
    return plans

@router.post("/", status_code=status.HTTP_201_CREATED)
def create_workout_plan(workout_data: dict, current_user = Depends(get_current_user)):
    """Cria um novo plano de treino baseado no questionário"""
    user_id = current_user['id']
    
    try:
        # Buscar perfil do usuário para personalizar o treino
        with db.get_db_cursor() as cursor:
            cursor.execute(
                """SELECT weight, height, age, gender, target_weight, activity_level
                   FROM profiles WHERE user_id = %s""",
                (user_id,)
            )
            profile = cursor.fetchone()
        
        # Gerar plano com IA
        workout_plan_json = generate_workout_plan(
            user_profile=profile,
            questionnaire_data=workout_data
        )
        
        # Limpar e converter JSON string para dict
        try:
            # Tentar extrair apenas o JSON válido (remover texto extra)
            start_brace = workout_plan_json.find('{')
            end_brace = workout_plan_json.rfind('}') + 1
            
            if start_brace != -1 and end_brace > start_brace:
                clean_json = workout_plan_json[start_brace:end_brace]
                workout_plan = json.loads(clean_json)
            else:
                raise ValueError("JSON não encontrado na resposta")
                
        except (json.JSONDecodeError, ValueError) as e:
            print(f"❌ Erro ao fazer parse do JSON: {e}")
            print(f"Resposta recebida: {workout_plan_json[:500]}...")
            
            # Criar um plano padrão em caso de erro
            workout_plan = {
                "plan_name": "Plano de Treino Personalizado",
                "plan_summary": "Plano gerado automaticamente devido a erro na resposta da IA",
                "workout_schedule": [],
                "important_notes": ["Plano gerado automaticamente"],
                "progression_tips": "Consulte um profissional"
            }
        
        # Salvar no banco
        plan_id = str(uuid4())
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
                    json.dumps(workout_plan, ensure_ascii=False)
                )
            )
            new_plan = cursor.fetchone()
        
        print(f"✅ Plano de treino criado: {workout_plan['plan_name']} para usuário {user_id}")
        return new_plan
        
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