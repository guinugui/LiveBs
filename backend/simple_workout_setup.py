import psycopg2
import sys

# Configuracoes do banco
DB_CONFIG = {
    "host": "localhost",
    "database": "nutri_ai_db", 
    "user": "postgres",
    "password": "MCguinu02",
    "port": 5432
}

def main():
    try:
        print("Conectando ao banco...")
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        # Testar conexao
        cursor.execute("SELECT version();")
        version = cursor.fetchone()
        print(f"Conectado: {version[0][:50]}...")
        
        # Criar tabela de treinos
        print("Criando tabela saved_workout_plans...")
        
        create_sql = """
        CREATE TABLE IF NOT EXISTS saved_workout_plans (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID,
            plan_name VARCHAR(255) NOT NULL,
            workout_type VARCHAR(50) NOT NULL,
            days_per_week INTEGER NOT NULL,
            plan_content JSONB NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
        
        cursor.execute(create_sql)
        
        # Criar indices
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_workout_user ON saved_workout_plans(user_id);")
        
        conn.commit()
        print("Tabela criada com sucesso!")
        
        # Verificar
        cursor.execute("SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'saved_workout_plans';")
        count = cursor.fetchone()[0]
        print(f"Tabela existe: {count > 0}")
        
        cursor.close()
        conn.close()
        print("Configuracao concluida!")
        
    except Exception as e:
        print(f"Erro: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()