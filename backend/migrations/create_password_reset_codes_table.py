"""
Migration: Cria tabela para códigos de recuperação de senha
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
        print("Iniciando migration para códigos de recuperação de senha...")
        
        # Verifica se a tabela já existe
        cursor.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_name = 'password_reset_codes'
            );
        """)
        
        result = cursor.fetchone()
        table_exists = result['exists'] if result else False
        
        if not table_exists:
            print("Criando tabela password_reset_codes...")
            cursor.execute("""
                CREATE TABLE password_reset_codes (
                    id SERIAL PRIMARY KEY,
                    email VARCHAR(255) NOT NULL,
                    code VARCHAR(6) NOT NULL,
                    expires_at TIMESTAMP NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
            
            # Criar índice para email
            cursor.execute("""
                CREATE INDEX idx_password_reset_codes_email ON password_reset_codes(email);
            """)
            
            print("✓ Tabela password_reset_codes criada")
        else:
            print("✓ Tabela password_reset_codes já existe")
        
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