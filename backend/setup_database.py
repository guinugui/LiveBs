#!/usr/bin/env python3
"""
Script para criar as tabelas do banco de dados se elas não existirem
"""

import psycopg2
from psycopg2.extras import RealDictCursor
import os

def create_tables():
    """Cria as tabelas necessárias para o sistema IA LiveBs"""
    
    # SQL para criar todas as tabelas necessárias
    create_tables_sql = """
    -- Tabela de Usuários
    CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        name VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Tabela de Perfis
    CREATE TABLE IF NOT EXISTS profiles (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        weight DECIMAL(5,2), -- kg
        height DECIMAL(5,2), -- cm
        age INTEGER,
        gender VARCHAR(20), -- 'male', 'female', 'other'
        target_weight DECIMAL(5,2),
        activity_level VARCHAR(50), -- 'sedentary', 'light', 'moderate', 'active', 'very_active'
        daily_calories INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id)
    );

    -- Tabela de Restrições Alimentares
    CREATE TABLE IF NOT EXISTS dietary_restrictions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
        restriction VARCHAR(100) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Tabela de Preferências Alimentares
    CREATE TABLE IF NOT EXISTS dietary_preferences (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
        preference VARCHAR(100) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Tabela de Mensagens do Chat
    CREATE TABLE IF NOT EXISTS chat_messages (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        message TEXT NOT NULL,
        role VARCHAR(20) NOT NULL, -- 'user' ou 'assistant'
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Tabela de Planos Alimentares
    CREATE TABLE IF NOT EXISTS meal_plans (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        day_number INTEGER NOT NULL, -- 1 a 7
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Tabela de Refeições
    CREATE TABLE IF NOT EXISTS meals (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        meal_plan_id UUID REFERENCES meal_plans(id) ON DELETE CASCADE,
        meal_type VARCHAR(50) NOT NULL, -- 'breakfast', 'lunch', 'dinner', 'snack'
        name VARCHAR(255) NOT NULL,
        calories INTEGER,
        protein DECIMAL(5,2), -- gramas
        carbs DECIMAL(5,2), -- gramas
        fat DECIMAL(5,2), -- gramas
        recipe TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Tabela de Registro de Peso
    CREATE TABLE IF NOT EXISTS weight_logs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        weight DECIMAL(5,2) NOT NULL,
        logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        notes TEXT
    );

    -- Tabela de Registro de Água
    CREATE TABLE IF NOT EXISTS water_logs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        amount DECIMAL(4,2) NOT NULL, -- litros
        logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Tabela de Registro de Refeições Consumidas
    CREATE TABLE IF NOT EXISTS meal_logs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        meal_name VARCHAR(255) NOT NULL,
        calories INTEGER,
        photo_url TEXT,
        logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        notes TEXT
    );
    """
    
    try:
        print("🔗 Conectando ao banco de dados...")
        
        conn = psycopg2.connect(
            host='localhost',
            port=5432,
            database='livebs_db',
            user='postgres',
            password='guinu02'
        )
        
        cursor = conn.cursor()
        
        print("✅ Conexão estabelecida!")
        print("📋 Criando tabelas...")
        
        # Execute o SQL para criar as tabelas
        cursor.execute(create_tables_sql)
        
        print("✅ Tabelas criadas com sucesso!")
        
        # Criar índices para melhor performance
        indices_sql = """
        CREATE INDEX IF NOT EXISTS idx_profiles_user ON profiles(user_id);
        CREATE INDEX IF NOT EXISTS idx_restrictions_profile ON dietary_restrictions(profile_id);
        CREATE INDEX IF NOT EXISTS idx_preferences_profile ON dietary_preferences(profile_id);
        CREATE INDEX IF NOT EXISTS idx_meal_plans_user ON meal_plans(user_id);
        CREATE INDEX IF NOT EXISTS idx_meals_plan ON meals(meal_plan_id);
        CREATE INDEX IF NOT EXISTS idx_chat_user_created ON chat_messages(user_id, created_at);
        CREATE INDEX IF NOT EXISTS idx_weight_user_logged ON weight_logs(user_id, logged_at);
        CREATE INDEX IF NOT EXISTS idx_water_user_logged ON water_logs(user_id, logged_at);
        CREATE INDEX IF NOT EXISTS idx_meal_logs_user_logged ON meal_logs(user_id, logged_at);
        """
        
        cursor.execute(indices_sql)
        print("📊 Índices criados!")
        
        # Commit as mudanças
        conn.commit()
        
        # Verificar se as tabelas foram criadas
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            ORDER BY table_name;
        """)
        
        tables = cursor.fetchall()
        print(f"\n🎉 SUCESSO! {len(tables)} tabelas disponíveis:")
        for table in tables:
            print(f"   📋 {table[0]}")
        
        cursor.close()
        conn.close()
        
        return True
        
    except psycopg2.Error as e:
        print(f"❌ Erro do PostgreSQL: {e}")
        return False
    except Exception as e:
        print(f"❌ Erro inesperado: {e}")
        return False

if __name__ == "__main__":
    print("🚀 CRIANDO ESTRUTURA DO BANCO DE DADOS LIVEBS")
    print("=" * 50)
    
    success = create_tables()
    
    if success:
        print("\n✅ BANCO DE DADOS PRONTO PARA USO!")
        print("Agora você pode executar o backend com segurança.")
    else:
        print("\n❌ FALHA NA CRIAÇÃO DAS TABELAS!")
        print("Verifique a conexão com PostgreSQL.")