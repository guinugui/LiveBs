from app.database import db

def test_meal_plan_details():
    """Testa busca de detalhes de plano alimentar"""
    
    with db.get_db_cursor() as cursor:
        # Buscar um plano existente
        cursor.execute("""
            SELECT id, plan_number, plan_name, plan_data, created_at
            FROM saved_meal_plans 
            ORDER BY created_at DESC 
            LIMIT 1
        """)
        
        plan = cursor.fetchone()
        
        if not plan:
            print("❌ Nenhum plano encontrado!")
            return
            
        print(f"📋 Plano encontrado: {plan['plan_name']} (ID: {plan['id']})")
        print(f"📅 Criado em: {plan['created_at']}")
        print(f"📊 Tipo do plan_data: {type(plan['plan_data'])}")
        
        # Verificar se plan_data é None
        if plan['plan_data'] is None:
            print("⚠️  plan_data é None!")
            return
            
        # Mostrar estrutura do plan_data
        import json
        if isinstance(plan['plan_data'], str):
            try:
                data = json.loads(plan['plan_data'])
                print(f"📋 Estrutura do plan_data (string decodificada):")
                print(f"   - Keys: {list(data.keys()) if isinstance(data, dict) else 'Não é dict'}")
                if isinstance(data, dict):
                    for key, value in data.items():
                        print(f"   - {key}: {type(value).__name__}")
                        if key == 'days' and isinstance(value, list) and len(value) > 0:
                            print(f"     - Primeiro dia: {list(value[0].keys()) if isinstance(value[0], dict) else 'Não é dict'}")
            except Exception as e:
                print(f"❌ Erro ao decodificar JSON: {e}")
                print(f"📝 Conteúdo raw (primeiros 200 chars): {str(plan['plan_data'])[:200]}...")
        else:
            print(f"📋 Estrutura do plan_data (tipo: {type(plan['plan_data'])}):")
            if isinstance(plan['plan_data'], dict):
                print(f"   - Keys: {list(plan['plan_data'].keys())}")
                for key, value in plan['plan_data'].items():
                    print(f"   - {key}: {type(value).__name__}")

if __name__ == "__main__":
    test_meal_plan_details()