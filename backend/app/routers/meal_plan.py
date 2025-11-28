from fastapi import APIRouter, HTTPException, Depends, status
import json
from datetime import datetime

from app.database import db
from app.routers.auth import get_current_user
from app.ai_service import generate_meal_plan
from app.schemas import MealPlanResponse

router = APIRouter(prefix="/meal-plan", tags=["Meal Plan"])

@router.post("", status_code=status.HTTP_201_CREATED)
def create_meal_plan(current_user = Depends(get_current_user)):
    """Gera e salva novo plano alimentar usando IA"""
    print(f"[DEBUG] ===== FUNÇÃO CREATE_MEAL_PLAN INICIADA =====")
    user_id = current_user['id']
    print(f"[DEBUG] User ID recebido: {user_id}")
    
    # Busca perfil do usuário no banco
    with db.get_db_cursor() as cursor:
        cursor.execute("""
            SELECT weight, height, age, target_weight, activity_level, daily_calories
            FROM profiles 
            WHERE user_id = %s
        """, (user_id,))
        
        profile_row = cursor.fetchone()
        
        if not profile_row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Perfil do usuário não encontrado. Configure seu perfil primeiro."
            )
    
    user_profile = {
        'weight': profile_row['weight'],
        'height': profile_row['height'], 
        'age': profile_row['age'],
        'target_weight': profile_row['target_weight'],
        'activity_level': profile_row['activity_level'],
        'daily_calories': profile_row['daily_calories'],
        'dietary_restrictions': [],  # Por enquanto vazio
        'dietary_preferences': []    # Por enquanto vazio
    }
    
    # Buscar planos anteriores para evitar repetições
    print(f"[DEBUG] ===== BUSCANDO PLANOS ANTERIORES =====")
    print(f"[DEBUG] User ID para busca: {user_id}")
    previous_plans = []
    with db.get_db_cursor() as cursor:
        print(f"[DEBUG] Executando query para buscar planos anteriores...")
        cursor.execute("""
            SELECT plan_data, plan_name, created_at
            FROM saved_meal_plans 
            WHERE user_id = %s 
            ORDER BY created_at DESC 
            LIMIT 3
        """, (user_id,))
        print(f"[DEBUG] Query executada com sucesso")
        
        previous_plans_rows = cursor.fetchall()
        for row in previous_plans_rows:
            previous_plans.append({
                'plan_name': row['plan_name'],
                'plan_data': row['plan_data'],
                'created_at': row['created_at'].isoformat()
            })
    
    print(f"[DEBUG] Encontrados {len(previous_plans)} planos anteriores")
    
    # Debug detalhado dos planos anteriores
    if previous_plans:
        print(f"[DEBUG] ===== PLANOS ANTERIORES ENCONTRADOS =====")
        for i, plan in enumerate(previous_plans):
            print(f"[DEBUG] Plano {i+1}: {plan['plan_name']} (criado em {plan['created_at']})")
            print(f"[DEBUG] Tipo dos dados: {type(plan['plan_data'])}")
    else:
        print(f"[DEBUG] Nenhum plano anterior encontrado - será o primeiro plano")
    
    # Gera plano com IA e salva no banco
    try:
        print(f"[DEBUG] Gerando plano para usuário {user_id}")
        print(f"[DEBUG] Perfil: {user_profile}")
        
        ai_plan = generate_meal_plan(user_profile, previous_plans)
        
        print(f"[DEBUG] Plano gerado com sucesso")
        print(f"[DEBUG] Tipo do plano: {type(ai_plan)}")
        print(f"[DEBUG] Keys do plano: {list(ai_plan.keys()) if isinstance(ai_plan, dict) else 'Not dict'}")
        
        if isinstance(ai_plan, dict) and 'days' in ai_plan:
            print(f"[DEBUG] Número de dias: {len(ai_plan['days'])}")
        
        # Salvar o plano no banco de dados
        with db.get_db_cursor() as cursor:
            # Verificar quantos planos o usuário já tem
            cursor.execute(
                "SELECT COUNT(*) FROM saved_meal_plans WHERE user_id = %s",
                (user_id,)
            )
            result = cursor.fetchone()
            # Tratamento robusta para tupla ou dict
            if result:
                if isinstance(result, dict):
                    plan_count = result.get('count', result.get('COUNT(*)', 0))
                else:
                    plan_count = result[0]
            else:
                plan_count = 0
            
            # Se já tem 10 ou mais planos, deletar o mais antigo
            if plan_count >= 10:
                print(f"[DEBUG] Usuário tem {plan_count} planos, deletando o mais antigo...")
                # Buscar o ID do plano mais antigo
                cursor.execute(
                    "SELECT id FROM saved_meal_plans WHERE user_id = %s ORDER BY created_at ASC LIMIT 1",
                    (user_id,)
                )
                oldest_plan = cursor.fetchone()
                if oldest_plan:
                    if isinstance(oldest_plan, dict):
                        oldest_plan_id = oldest_plan['id']
                    else:
                        oldest_plan_id = oldest_plan[0]
                    cursor.execute(
                        "DELETE FROM saved_meal_plans WHERE id = %s",
                        (oldest_plan_id,)
                    )
                    print(f"[DEBUG] Plano mais antigo deletado (ID: {oldest_plan_id})")
            
            # Descobrir o próximo número do plano
            cursor.execute(
                "SELECT COALESCE(MAX(plan_number), 0) + 1 FROM saved_meal_plans WHERE user_id = %s",
                (user_id,)
            )
            result = cursor.fetchone()
            if result:
                if isinstance(result, dict):
                    next_number = list(result.values())[0] if result else 1
                else:
                    next_number = result[0]
            else:
                next_number = 1
            
            # Inserir o plano
            plan_name = f"Plano Alimentar {next_number:02d}"
            cursor.execute("""
                INSERT INTO saved_meal_plans (user_id, plan_number, plan_name, plan_data)
                VALUES (%s, %s, %s, %s)
                RETURNING id
            """, (user_id, next_number, plan_name, json.dumps(ai_plan)))
            
            plan_id = cursor.fetchone()[0]  # pg8000 retorna lista, não dict
            print(f"[DEBUG] Plano salvo com ID: {plan_id}, nome: {plan_name}")
        
        return {
            "id": str(plan_id),
            "plan_name": plan_name,
            "plan_number": next_number,
            "plan_data": ai_plan,
            "message": f"Plano '{plan_name}' criado com sucesso!"
        }
        
    except Exception as e:
        print(f"[DEBUG] Erro ao gerar plano: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao gerar plano alimentar: {str(e)}"
        )

@router.get("")
def get_saved_meal_plans(current_user = Depends(get_current_user)):
    """Retorna lista de planos alimentares salvos do usuário"""
    user_id = current_user['id']
    
    with db.get_db_cursor() as cursor:
        cursor.execute("""
            SELECT id, plan_number, plan_name, created_at
            FROM saved_meal_plans 
            WHERE user_id = %s 
            ORDER BY plan_number DESC
        """, (user_id,))
        
        plans = cursor.fetchall()
    
    if not plans:
        return {
            "plans": [],
            "message": "Nenhum plano alimentar encontrado. Crie seu primeiro plano!"
        }
    
    return {
        "plans": [
            {
                "id": str(plan['id']),
                "plan_number": plan['plan_number'],
                "plan_name": plan['plan_name'],
                "created_at": plan['created_at'].isoformat()
            }
            for plan in plans
        ]
    }

@router.get("/{plan_id}")
def get_meal_plan_details(plan_id: str, current_user = Depends(get_current_user)):
    """Retorna detalhes completos de um plano alimentar específico"""
    user_id = current_user['id']
    
    with db.get_db_cursor() as cursor:
        cursor.execute("""
            SELECT id, plan_number, plan_name, plan_data, created_at
            FROM saved_meal_plans 
            WHERE id = %s AND user_id = %s
        """, (plan_id, user_id))
        
        plan = cursor.fetchone()
    
    if not plan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Plano alimentar não encontrado"
        )
    
    return {
        "id": str(plan['id']),
        "plan_number": plan['plan_number'],
        "plan_name": plan['plan_name'],
        "plan_data": plan['plan_data'],
        "created_at": plan['created_at'].isoformat()
    }

@router.delete("/{plan_id}")
def delete_meal_plan(plan_id: str, current_user = Depends(get_current_user)):
    """Deleta um plano alimentar salvo específico"""
    user_id = current_user['id']
    
    with db.get_db_cursor() as cursor:
        # Verificar se o plano existe e pertence ao usuário
        cursor.execute(
            "SELECT plan_name FROM saved_meal_plans WHERE id = %s AND user_id = %s",
            (plan_id, user_id)
        )
        plan = cursor.fetchone()
        
        if not plan:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Plano alimentar não encontrado"
            )
        
        # Deletar o plano
        cursor.execute(
            "DELETE FROM saved_meal_plans WHERE id = %s AND user_id = %s",
            (plan_id, user_id)
        )
    
    return {"message": f"Plano '{plan['plan_name']}' deletado com sucesso"}
