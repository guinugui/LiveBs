import psycopg2
import os
import locale

# Configurar encoding
os.environ['PYTHONIOENCODING'] = 'utf-8'
locale.setlocale(locale.LC_ALL, 'C')

def test_connection():
    try:
        conn_string = "host='localhost' dbname='nutri_ai_db' user='postgres' password='MCguinu02' port='5432'"
        
        print("Testando conexao...")
        conn = psycopg2.connect(conn_string)
        cursor = conn.cursor()
        
        cursor.execute("SELECT 1 as test;")
        result = cursor.fetchone()
        print(f"Conexao OK: {result}")
        
        # Criar tabela
        print("Criando tabela...")
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS saved_workout_plans (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID,
                plan_name VARCHAR(255) NOT NULL,
                workout_type VARCHAR(50) NOT NULL,
                days_per_week INTEGER NOT NULL,
                plan_content JSONB NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        
        conn.commit()
        print("Tabela criada!")
        
        cursor.close()
        conn.close()
        
        return True
    except Exception as e:
        print(f"Erro: {str(e)}")
        return False

if __name__ == "__main__":
    test_connection()