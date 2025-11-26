from app.database import db

def check_user_meal_plans():
    """Verifica planos alimentares para gui@gmail.com"""
    
    with db.get_db_cursor() as cursor:
        # Primeiro, buscar o usuário pelo email
        cursor.execute("""
            SELECT id, email, name, created_at 
            FROM users 
            WHERE email = %s
        """, ("gui@gmail.com",))
        
        user = cursor.fetchone()
        
        if not user:
            print("❌ Usuário gui@gmail.com não encontrado!")
            
            # Listar todos os usuários para ver quais existem
            cursor.execute("SELECT id, email, name FROM users ORDER BY created_at DESC LIMIT 10")
            all_users = cursor.fetchall()
            print("\n📋 Usuários existentes:")
            for u in all_users:
                print(f"   - {u['email']} (ID: {u['id']})")
            return
            
        print("✅ Usuário gui@gmail.com encontrado:")
        print(f"   ID: {user['id']}")
        print(f"   Email: {user['email']}")
        print(f"   Nome: {user['name']}")
        print(f"   Criado em: {user['created_at']}")
        
        user_id = user['id']
        
        # Buscar planos alimentares deste usuário
        cursor.execute("""
            SELECT id, plan_number, plan_name, created_at, updated_at
            FROM saved_meal_plans 
            WHERE user_id = %s
            ORDER BY plan_number
        """, (user_id,))
        
        plans = cursor.fetchall()
        
        print(f"\n📋 PLANOS ALIMENTARES ({len(plans)} encontrados):")
        
        if not plans:
            print("   Nenhum plano alimentar encontrado para este usuário.")
        else:
            for plan in plans:
                print(f"   - Nome: {plan['plan_name']}")
                print(f"     ID: {plan['id']}")
                print(f"     Número: {plan['plan_number']}")
                print(f"     Criado: {plan['created_at']}")
                print()

if __name__ == "__main__":
    check_user_meal_plans()