from app.database import db
import json

# Criar tabela para salvar planos alimentares
with db.get_db_cursor() as cursor:
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS saved_meal_plans (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            plan_number INTEGER NOT NULL,
            plan_name VARCHAR(100) NOT NULL,
            plan_data JSONB NOT NULL,
            created_at TIMESTAMP DEFAULT NOW(),
            updated_at TIMESTAMP DEFAULT NOW(),
            UNIQUE(user_id, plan_number)
        );
    """)
    
    print("Tabela saved_meal_plans criada com sucesso!")
    
    # Verificar se criou
    cursor.execute("""
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'saved_meal_plans'
        ORDER BY ordinal_position;
    """)
    
    columns = cursor.fetchall()
    print(f'\nEstrutura da tabela saved_meal_plans:')
    for col in columns:
        print(f'  - {col["column_name"]}: {col["data_type"]}')