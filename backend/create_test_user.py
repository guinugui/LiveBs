from app.database import db
from app.auth import get_password_hash
import uuid

# Criar usuário de teste
with db.get_db_cursor() as cursor:
    # Verificar se usuário já existe
    cursor.execute("SELECT id FROM users WHERE email = 'test@example.com'")
    existing_user = cursor.fetchone()
    
    if existing_user:
        print("Usuário de teste já existe!")
        user_id = existing_user['id']
    else:
        # Criar novo usuário
        user_id = str(uuid.uuid4())
        hashed_password = get_password_hash("123456")
        
        cursor.execute("""
            INSERT INTO users (id, email, password_hash, name) 
            VALUES (%s, %s, %s, %s)
        """, (user_id, "test@example.com", hashed_password, "Usuario Teste"))
        
        print("Usuário de teste criado!")
    
    # Verificar se perfil já existe
    cursor.execute("SELECT id FROM profiles WHERE user_id = %s", (user_id,))
    existing_profile = cursor.fetchone()
    
    if not existing_profile:
        # Criar perfil de teste
        cursor.execute("""
            INSERT INTO profiles (user_id, weight, height, age, gender, target_weight, activity_level, daily_calories)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (user_id, 130.0, 187.0, 24, 'male', 80.0, 'active', 3969))
        
        print("Perfil de teste criado!")
    else:
        print("Perfil de teste já existe!")

print(f"User ID: {user_id}")
print("Email: test@example.com")
print("Senha: 123456")