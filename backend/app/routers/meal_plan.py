from fastapi import APIRouter, HTTPException, Depends, status
from app.schemas import MealPlanResponse, MealPlanDayResponse, MealResponse
from app.database import db
from app.routers.auth import get_current_user
from app.routers.profile import get_profile
from app.ai_service import generate_meal_plan

router = APIRouter(prefix="/meal-plan", tags=["Meal Plan"])

@router.post("", response_model=MealPlanResponse, status_code=status.HTTP_201_CREATED)
def create_meal_plan(current_user = Depends(get_current_user)):
    """Gera novo plano alimentar usando IA"""
    user_id = current_user['id']
    
    # Busca perfil do usuário
    profile = get_profile(current_user)
    user_profile = {
        'weight': profile.weight,
        'height': profile.height,
        'age': profile.age,
        'target_weight': profile.target_weight,
        'activity_level': profile.activity_level,
        'daily_calories': profile.daily_calories,
        'dietary_restrictions': profile.dietary_restrictions,
        'dietary_preferences': profile.dietary_preferences
    }
    
    # Gera plano com IA
    ai_plan = generate_meal_plan(user_profile)
    
    with db.get_db_cursor() as cursor:
        # Desativa planos antigos
        cursor.execute(
            "UPDATE meal_plans SET is_active = false WHERE user_id = %s",
            (user_id,)
        )
        
        # Cria novos planos
        for day_data in ai_plan['days']:
            day_number = day_data['day']
            
            # Cria registro do dia
            cursor.execute(
                """INSERT INTO meal_plans (user_id, day_number, is_active) 
                   VALUES (%s, %s, true) RETURNING id""",
                (user_id, day_number)
            )
            plan_id = cursor.fetchone()['id']
            
            # Cria refeições do dia (com 2 opções cada)
            for meal_data in day_data['meals']:
                meal_type = meal_data['type']
                
                # Salva cada opção
                for option in meal_data.get('options', []):
                    ingredients = option.get('ingredients', '')
                    recipe = option.get('recipe', '')
                    full_recipe = f"Ingredientes:\n{ingredients}\n\nModo de Preparo:\n{recipe}"
                    
                    cursor.execute(
                        """INSERT INTO meals (meal_plan_id, meal_type, name, calories, 
                                              protein, carbs, fat, recipe)
                           VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
                        (plan_id, meal_type, option['name'], 
                         option['calories'], option['protein'], 
                         option['carbs'], option['fat'], full_recipe)
                    )
    
    return get_active_meal_plan(current_user)

@router.get("", response_model=MealPlanResponse)
def get_active_meal_plan(current_user = Depends(get_current_user)):
    """Retorna plano alimentar ativo"""
    user_id = current_user['id']
    
    with db.get_db_cursor() as cursor:
        # Busca planos ativos
        cursor.execute(
            """SELECT mp.id, mp.day_number,
                      m.id as meal_id, m.meal_type, m.name, m.calories, 
                      m.protein, m.carbs, m.fat, m.recipe
               FROM meal_plans mp
               LEFT JOIN meals m ON m.meal_plan_id = mp.id
               WHERE mp.user_id = %s AND mp.is_active = true
               ORDER BY mp.day_number, 
                        CASE m.meal_type
                            WHEN 'breakfast' THEN 1
                            WHEN 'morning_snack' THEN 2
                            WHEN 'lunch' THEN 3
                            WHEN 'afternoon_snack' THEN 4
                            WHEN 'dinner' THEN 5
                        END""",
            (user_id,)
        )
        rows = cursor.fetchall()
    
    if not rows:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Nenhum plano alimentar ativo encontrado"
        )
    
    # Organiza em dias
    days_dict = {}
    for row in rows:
        day_num = row['day_number']
        if day_num not in days_dict:
            days_dict[day_num] = []
        
        if row['meal_id']:  # Se tem refeição
            days_dict[day_num].append({
                'id': row['meal_id'],
                'meal_type': row['meal_type'],
                'name': row['name'],
                'calories': row['calories'],
                'protein': row['protein'],
                'carbs': row['carbs'],
                'fat': row['fat'],
                'recipe': row['recipe']
            })
    
    # Monta resposta
    plan = [
        {'day_number': day, 'meals': meals}
        for day, meals in sorted(days_dict.items())
    ]
    
    return {'plan': plan}

@router.delete("")
def delete_meal_plan(current_user = Depends(get_current_user)):
    """Deleta plano alimentar ativo"""
    user_id = current_user['id']
    
    with db.get_db_cursor() as cursor:
        cursor.execute(
            "UPDATE meal_plans SET is_active = false WHERE user_id = %s",
            (user_id,)
        )
    
    return {"message": "Plano alimentar deletado com sucesso"}
