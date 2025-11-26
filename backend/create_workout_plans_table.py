#!/usr/bin/env python3
"""
Script para criar a tabela saved_workout_plans
"""
import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

def create_workout_plans_table():
    """Cria a tabela saved_workout_plans se não existir"""
    
    connection = None
    cursor = None
    
    try:
        # Conectar ao banco
        connection = psycopg2.connect(
            host=os.getenv("DB_HOST", "localhost"),
            database=os.getenv("DB_NAME", "livebs"),
            user=os.getenv("DB_USER", "postgres"),
            password=os.getenv("DB_PASSWORD", "123"),
            port=os.getenv("DB_PORT", "5432")
        )
        
        cursor = connection.cursor()
        
        # SQL para criar a tabela
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS saved_workout_plans (
            id VARCHAR PRIMARY KEY,
            user_id UUID NOT NULL,
            plan_name VARCHAR(255) NOT NULL,
            plan_number INTEGER NOT NULL,
            workout_type VARCHAR(50) NOT NULL DEFAULT 'home', -- 'home' ou 'gym'
            days_per_week INTEGER NOT NULL DEFAULT 3,
            plan_content JSON NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            
            -- Chave estrangeira para users
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            
            -- Índices para performance
            INDEX idx_saved_workout_plans_user_id (user_id),
            INDEX idx_saved_workout_plans_created_at (created_at)
        );
        """
        
        print("🔨 Criando tabela saved_workout_plans...")
        cursor.execute(create_table_sql)
        
        # Commit das mudanças
        connection.commit()
        print("✅ Tabela saved_workout_plans criada com sucesso!")
        
        # Verificar se a tabela foi criada
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'saved_workout_plans'
        """)
        
        if cursor.fetchone():
            print("✅ Verificação: Tabela saved_workout_plans existe no banco")
            
            # Mostrar estrutura da tabela
            cursor.execute("""
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns 
                WHERE table_name = 'saved_workout_plans'
                ORDER BY ordinal_position
            """)
            
            columns = cursor.fetchall()
            print("\n📋 Estrutura da tabela saved_workout_plans:")
            for col in columns:
                print(f"  - {col[0]} ({col[1]}) - Null: {col[2]} - Default: {col[3]}")
                
        else:
            print("❌ Erro: Tabela não foi encontrada após criação")
            
    except Exception as e:
        print(f"❌ Erro ao criar tabela: {e}")
        if connection:
            connection.rollback()
            
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

if __name__ == "__main__":
    print("🚀 Iniciando criação da tabela saved_workout_plans...")
    create_workout_plans_table()
    print("🏁 Script finalizado.")