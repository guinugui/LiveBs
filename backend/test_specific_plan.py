from app.database import db
import json

def test_specific_plan():
    """Testa o plano específico que está sendo usado no app"""
    plan_id = '292ee40f-fb90-44f7-a6a4-faad87a9c66e'  # ID do log do Flutter
    
    with db.get_db_cursor() as cursor:
        cursor.execute("""
            SELECT id, plan_number, plan_name, plan_data, created_at
            FROM saved_meal_plans 
            WHERE id = %s
        """, (plan_id,))
        
        plan = cursor.fetchone()
        
        if not plan:
            print(f"❌ Plano {plan_id} não encontrado!")
            return
            
        print(f"📋 Plano: {plan['plan_name']}")
        print(f"🆔 ID: {plan['id']}")
        
        plan_data = plan['plan_data']
        print(f"📊 Tipo: {type(plan_data)}")
        
        if isinstance(plan_data, dict):
            print("🔍 Estrutura completa:")
            print(json.dumps(plan_data, indent=2, ensure_ascii=False, default=str))
            
            if 'days' in plan_data:
                days = plan_data['days']
                print(f"\n📅 Dias encontrados: {len(days)}")
                
                if len(days) > 0:
                    first_day = days[0]
                    print(f"📋 Primeiro dia - keys: {list(first_day.keys()) if isinstance(first_day, dict) else 'Não é dict'}")
                    
                    if isinstance(first_day, dict) and 'meals' in first_day:
                        meals = first_day['meals']
                        print(f"🍽️ Refeições encontradas: {list(meals.keys()) if isinstance(meals, dict) else 'Não é dict'}")
                        
                        # Mostrar uma refeição de exemplo
                        if isinstance(meals, dict) and len(meals) > 0:
                            first_meal_type = list(meals.keys())[0]
                            first_meal = meals[first_meal_type]
                            print(f"\n🥗 Exemplo - {first_meal_type}:")
                            print(json.dumps(first_meal, indent=2, ensure_ascii=False, default=str))

if __name__ == "__main__":
    test_specific_plan()