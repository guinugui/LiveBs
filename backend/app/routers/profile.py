from fastapi import APIRouter, HTTPException, Depends, status
from app.schemas import ProfileCreate, ProfileUpdate, ProfileResponse
from app.database import db
from app.routers.auth import get_current_user
from uuid import UUID

router = APIRouter(prefix="/profile", tags=["Profile"])

def calculate_bmi(weight: float, height: float) -> float:
    """Calcula IMC"""
    height_m = height / 100
    return round(weight / (height_m ** 2), 2)

def calculate_daily_calories(profile: dict) -> int:
    """Calcula calorias diárias usando fórmula de Harris-Benedict"""
    # TMB (Taxa Metabólica Basal)
    if profile['gender'].lower() == 'male':
        tmb = 88.362 + (13.397 * profile['weight']) + (4.799 * profile['height']) - (5.677 * profile['age'])
    else:
        tmb = 447.593 + (9.247 * profile['weight']) + (3.098 * profile['height']) - (4.330 * profile['age'])
    
    # Multiplicador de atividade
    activity_multipliers = {
        'sedentary': 1.2,
        'light': 1.375,
        'moderate': 1.55,
        'active': 1.725,
        'very_active': 1.9
    }
    
    multiplier = activity_multipliers.get(profile['activity_level'], 1.2)
    daily_calories = tmb * multiplier
    
    # Déficit calórico para perda de peso (500 kcal/dia = ~0.5kg/semana)
    return int(daily_calories - 500)

@router.post("", response_model=ProfileResponse, status_code=status.HTTP_201_CREATED)
def create_profile(profile: ProfileCreate, current_user = Depends(get_current_user)):
    """Cria perfil do usuário"""
    user_id = current_user['id']
    
    with db.get_db_cursor() as cursor:
        # Verifica se já existe perfil
        cursor.execute("SELECT id FROM profiles WHERE user_id = %s", (user_id,))
        if cursor.fetchone():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Perfil já existe para este usuário"
            )
        
        # Calcula calorias diárias
        daily_calories = calculate_daily_calories({
            'weight': profile.weight,
            'height': profile.height,
            'age': profile.age,
            'gender': profile.gender,
            'activity_level': profile.activity_level
        })
        
        # Cria perfil
        cursor.execute(
            """INSERT INTO profiles (user_id, weight, height, age, gender, target_weight, 
                                     activity_level, daily_calories)
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
               RETURNING id, user_id, weight, height, age, gender, target_weight, 
                         activity_level, daily_calories, created_at""",
            (user_id, profile.weight, profile.height, profile.age, profile.gender,
             profile.target_weight, profile.activity_level, daily_calories)
        )
        new_profile = cursor.fetchone()
        profile_id = new_profile['id']
        
        # Adiciona restrições alimentares
        for restriction in profile.dietary_restrictions:
            cursor.execute(
                "INSERT INTO dietary_restrictions (profile_id, restriction) VALUES (%s, %s)",
                (profile_id, restriction)
            )
        
        # Adiciona preferências
        for preference in profile.dietary_preferences:
            cursor.execute(
                "INSERT INTO dietary_preferences (profile_id, preference) VALUES (%s, %s)",
                (profile_id, preference)
            )
    
    # Busca perfil completo
    return get_profile(current_user)

@router.get("", response_model=ProfileResponse)
def get_profile(current_user = Depends(get_current_user)):
    """Retorna perfil do usuário"""
    user_id = current_user['id']
    
    with db.get_db_cursor() as cursor:
        cursor.execute(
            """SELECT id, user_id, weight, height, age, gender, target_weight, 
                      activity_level, daily_calories
               FROM profiles WHERE user_id = %s""",
            (user_id,)
        )
        profile = cursor.fetchone()
        
        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Perfil não encontrado"
            )
        
        # Busca restrições
        cursor.execute(
            "SELECT restriction FROM dietary_restrictions WHERE profile_id = %s",
            (profile['id'],)
        )
        restrictions = [row['restriction'] for row in cursor.fetchall()]
        
        # Busca preferências
        cursor.execute(
            "SELECT preference FROM dietary_preferences WHERE profile_id = %s",
            (profile['id'],)
        )
        preferences = [row['preference'] for row in cursor.fetchall()]
    
    bmi = calculate_bmi(profile['weight'], profile['height'])
    
    return {
        **profile,
        'bmi': bmi,
        'dietary_restrictions': restrictions,
        'dietary_preferences': preferences
    }

@router.put("", response_model=ProfileResponse)
def update_profile(profile_update: ProfileUpdate, current_user = Depends(get_current_user)):
    """Atualiza perfil do usuário"""
    user_id = current_user['id']
    
    with db.get_db_cursor() as cursor:
        # Busca perfil atual
        cursor.execute(
            "SELECT id, weight, height, age, gender, activity_level FROM profiles WHERE user_id = %s",
            (user_id,)
        )
        current_profile = cursor.fetchone()
        
        if not current_profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Perfil não encontrado"
            )
        
        # Atualiza campos fornecidos
        update_data = profile_update.model_dump(exclude_unset=True)
        
        if update_data:
            # Recalcula calorias se necessário
            if any(k in update_data for k in ['weight', 'height', 'age', 'activity_level']):
                profile_for_calc = {
                    'weight': update_data.get('weight', current_profile['weight']),
                    'height': update_data.get('height', current_profile['height']),
                    'age': update_data.get('age', current_profile['age']),
                    'gender': current_profile['gender'],
                    'activity_level': update_data.get('activity_level', current_profile['activity_level'])
                }
                update_data['daily_calories'] = calculate_daily_calories(profile_for_calc)
            
            # Monta query dinâmica
            set_clause = ", ".join([f"{k} = %s" for k in update_data.keys()])
            values = list(update_data.values()) + [user_id]
            
            cursor.execute(
                f"UPDATE profiles SET {set_clause} WHERE user_id = %s",
                values
            )
    
    return get_profile(current_user)
