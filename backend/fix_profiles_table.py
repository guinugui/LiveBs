#!/usr/bin/env python3
import psycopg2
from psycopg2.extras import RealDictCursor

try:
    conn = psycopg2.connect(
        host='localhost',
        database='livebs_db',
        user='postgres',
        password='admin'
    )
    cursor = conn.cursor()
    
    print('Adicionando coluna goal na tabela profiles...')
    
    # Verificar se a coluna já existe
    cursor.execute("""
        SELECT column_name FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'goal'
    """)
    exists = cursor.fetchone()
    
    if exists:
        print('Coluna goal já existe!')
    else:
        # Adicionar coluna goal
        cursor.execute("""
            ALTER TABLE profiles 
            ADD COLUMN goal VARCHAR(50) DEFAULT 'weight_loss'
        """)
        
        # Atualizar registros existentes
        cursor.execute("""
            UPDATE profiles 
            SET goal = 'weight_loss' 
            WHERE goal IS NULL
        """)
        
        conn.commit()
        print('Coluna goal adicionada com sucesso!')
    
    # Verificar estrutura atualizada
    cursor.execute("""
        SELECT column_name, data_type, is_nullable, column_default 
        FROM information_schema.columns 
        WHERE table_name = 'profiles'
        ORDER BY ordinal_position
    """)
    columns = cursor.fetchall()
    
    print('\n=== ESTRUTURA ATUALIZADA ===')
    for col in columns:
        nullable = "YES" if col[2] == 'YES' else "NO"
        default = col[3] or "None"
        print(f"{col[0]:20} | {col[1]:15} | Nullable: {nullable:3} | Default: {default}")
    
    cursor.close()
    conn.close()
    print('\nSucesso! Tabela profiles atualizada.')

except Exception as e:
    print(f"Erro: {e}")
    if 'conn' in locals():
        conn.rollback()