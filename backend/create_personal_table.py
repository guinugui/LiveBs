#!/usr/bin/env python3
"""
Cria tabela para mensagens do Personal Trainer Virtual
"""

from app.database import db

def create_personal_messages_table():
    """Cria a tabela personal_messages se não existir"""
    
    with db.get_db_cursor() as cursor:
        # Criar tabela personal_messages
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS personal_messages (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant')),
                message TEXT NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
        """)
        
        # Criar índices para performance
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_personal_messages_user_id 
            ON personal_messages(user_id)
        """)
        
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_personal_messages_created_at 
            ON personal_messages(created_at)
        """)
        
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_personal_messages_user_created 
            ON personal_messages(user_id, created_at)
        """)
        
        print("✅ Tabela personal_messages criada com sucesso!")

if __name__ == "__main__":
    create_personal_messages_table()