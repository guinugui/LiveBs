"""
Migration: Adiciona campos de timestamp para sistema de atualização semanal
- created_at na tabela users (se não existir)
- last_profile_update na tabela profiles
"""

import psycopg2
from psycopg2.extras import RealDictCursor
import sys
import os

# Adiciona o diretório pai ao path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.config import settings

def run_migration():
    """Executa a migração"""
    # Parse database URL
    connection_params = settings.database_url.replace('postgresql://', '')
    parts = connection_params.split('@')
    user_pass = parts[0].split(':')
    host_db = parts[1].split('/')
    host_port = host_db[0].split(':')
    
    params = {
        'user': user_pass[0],
        'password': user_pass[1],
        'host': host_port[0],
        'port': host_port[1] if len(host_port) > 1 else '5432',
        'database': host_db[1]
    }
    
    conn = psycopg2.connect(**params, cursor_factory=RealDictCursor)
    cursor = conn.cursor()
    
    try:
        print("Iniciando migration...")
        
        # Verifica se a coluna created_at já existe na tabela users
        cursor.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'created_at'
        """)
        
        if not cursor.fetchone():
            print("Adicionando coluna created_at na tabela users...")
            cursor.execute("""
                ALTER TABLE users 
                ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            """)
            print("✓ Coluna created_at adicionada")
        else:
            print("✓ Coluna created_at já existe")
        
        # Verifica se a coluna last_profile_update já existe na tabela profiles
        cursor.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'profiles' AND column_name = 'last_profile_update'
        """)
        
        if not cursor.fetchone():
            print("Adicionando coluna last_profile_update na tabela profiles...")
            cursor.execute("""
                ALTER TABLE profiles 
                ADD COLUMN last_profile_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            """)
            print("✓ Coluna last_profile_update adicionada")
        else:
            print("✓ Coluna last_profile_update já existe")
        
        conn.commit()
        print("\n✅ Migration concluída com sucesso!")
        
    except Exception as e:
        conn.rollback()
        print(f"\n❌ Erro na migration: {e}")
        raise
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    run_migration()
