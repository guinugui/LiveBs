from fastapi import APIRouter, Depends, HTTPException
from app.routers.auth import get_current_user
from app.ai_service import generate_workout_plan
from app.database import db
from app.routers.profile import get_profile

router = APIRouter(prefix="/workout-plans", tags=["workout-plans"])

@router.post("", response_model=dict)
def create_workout_plan(
    request_data: dict,
    current_user = Depends(get_current_user)
):
    """Cria plano de treino personalizado com IA"""
    user_id = current_user['id']
    
    try:
        # Busca perfil do usuário
        profile = get_profile(current_user)
        user_profile = {
            'weight': profile['weight'],
            'height': profile['height'],
            'age': profile['age'],
            'target_weight': profile['target_weight'],
            'activity_level': profile['activity_level'],
            'daily_calories': profile['daily_calories'],
            'dietary_restrictions': profile['dietary_restrictions'],
            'dietary_preferences': profile['dietary_preferences']
        }
        
        # Adiciona dados específicos do treino
        user_profile.update({
            'workout_days_per_week': request_data.get('workout_days_per_week', 4),
            'muscular_problems': request_data.get('muscular_problems', []),
            'fitness_goals': request_data.get('fitness_goals', ['muscle_gain'])
        })
        
        # Gera plano com IA
        workout_plan = generate_workout_plan(user_profile)
        
        # Retorna o plano diretamente
        return {
            "id": workout_plan["id"],
            "user_id": user_id,
            "title": workout_plan["title"],
            "description": workout_plan["description"],
            "total_days": workout_plan["total_days"],
            "weekly_schedule": workout_plan["weekly_schedule"],
            "created_at": workout_plan["created_at"],
            "content": workout_plan["content"],
            "workouts": workout_plan["workouts"]
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao gerar plano de treino: {str(e)}")

@router.get("", response_model=dict)
def get_active_workout_plan(current_user = Depends(get_current_user)):
    """Retorna plano de treino ativo (mock por enquanto)"""
    user_id = current_user['id']
    
    # Por enquanto, retorna um plano mock
    # Futuramente, implementar salvamento no banco
    return {
        "message": "Plano de treino ativo",
        "user_id": user_id,
        "status": "active"
    }