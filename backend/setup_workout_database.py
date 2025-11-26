import psycopg2
import os
from datetime import datetime

# Configurações do banco com a senha correta
DB_CONFIG = {
    "host": "localhost",
    "database": "nutri_ai_db",
    "user": "postgres", 
    "password": "MCguinu02",
    "port": 5432
}

def test_connection():
    """Testa a conexão com o banco de dados"""
    try:
        print("🔌 Testando conexão com PostgreSQL...")
        
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        # Teste simples
        cursor.execute("SELECT version();")
        version = cursor.fetchone()
        print(f"✅ Conectado ao PostgreSQL: {version[0]}")
        
        cursor.close()
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Erro na conexão: {e}")
        return False

def create_workout_plans_table():
    """Cria a tabela saved_workout_plans"""
    try:
        print("🏗️ Criando tabela saved_workout_plans...")
        
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        # SQL para criar a tabela
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS saved_workout_plans (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID REFERENCES users(id) ON DELETE CASCADE,
            plan_name VARCHAR(255) NOT NULL,
            workout_type VARCHAR(50) NOT NULL,  -- 'casa' ou 'academia' 
            days_per_week INTEGER NOT NULL,
            plan_content JSONB NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
        
        cursor.execute(create_table_sql)
        
        # Criar índices para performance
        indexes_sql = [
            "CREATE INDEX IF NOT EXISTS idx_workout_plans_user_id ON saved_workout_plans(user_id);",
            "CREATE INDEX IF NOT EXISTS idx_workout_plans_created_at ON saved_workout_plans(created_at);",
            "CREATE INDEX IF NOT EXISTS idx_workout_plans_workout_type ON saved_workout_plans(workout_type);"
        ]
        
        for idx_sql in indexes_sql:
            cursor.execute(idx_sql)
        
        conn.commit()
        print("✅ Tabela saved_workout_plans criada com sucesso!")
        
        # Verificar se a tabela foi criada
        cursor.execute("""
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'saved_workout_plans'
            ORDER BY ordinal_position;
        """)
        
        columns = cursor.fetchall()
        print("📋 Colunas da tabela:")
        for col in columns:
            print(f"   - {col[0]} ({col[1]})")
            
        cursor.close()
        conn.close()
        
        return True
        
    except Exception as e:
        print(f"❌ Erro ao criar tabela: {e}")
        return False

def verify_existing_tables():
    """Verifica as tabelas existentes no banco"""
    try:
        print("📊 Verificando tabelas existentes...")
        
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
            ORDER BY table_name;
        """)
        
        tables = cursor.fetchall()
        print("📋 Tabelas encontradas:")
        for table in tables:
            print(f"   - {table[0]}")
            
        cursor.close()
        conn.close()
        
        return True
        
    except Exception as e:
        print(f"❌ Erro ao verificar tabelas: {e}")
        return False

def main():
    """Função principal"""
    print("🚀 CONFIGURAÇÃO DO BANCO DE DADOS PARA TREINOS")
    print("=" * 50)
    
    # 1. Testar conexão
    if not test_connection():
        print("❌ Falha na conexão. Verifique se o PostgreSQL está rodando e a senha está correta.")
        return
    
    # 2. Verificar tabelas existentes
    verify_existing_tables()
    
    # 3. Criar tabela de treinos
    if create_workout_plans_table():
        print("✅ Configuração concluída com sucesso!")
    else:
        print("❌ Falha na configuração da tabela.")
    
    print("=" * 50)

if __name__ == "__main__":
    main()