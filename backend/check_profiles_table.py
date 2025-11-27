#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import psycopg2
from psycopg2.extras import RealDictCursor

try:
    conn = psycopg2.connect(
        host='localhost',
        database='livebs_db',
        user='postgres',
        password='admin'
    )
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    print('=== ESTRUTURA DA TABELA PROFILES ===')
    cursor.execute("""
        SELECT column_name, data_type, is_nullable, column_default 
        FROM information_schema.columns 
        WHERE table_name = 'profiles'
        ORDER BY ordinal_position
    """)
    columns = cursor.fetchall()
    
    for col in columns:
        nullable = "YES" if col['is_nullable'] == 'YES' else "NO"
        default = col['column_default'] or "None"
        print(f"{col['column_name']:20} | {col['data_type']:15} | Nullable: {nullable:3} | Default: {default}")
    
    print('\n=== CONSTRAINTS DA TABELA ===')
    cursor.execute("""
        SELECT conname, contype, pg_get_constraintdef(oid) as definition
        FROM pg_constraint 
        WHERE conrelid = 'profiles'::regclass
    """)
    constraints = cursor.fetchall()
    
    for constraint in constraints:
        print(f"Nome: {constraint['conname']}")
        print(f"Tipo: {constraint['contype']}")
        print(f"Definição: {constraint['definition']}")
        print("---")
    
    conn.close()
    
except Exception as e:
    print(f'Erro: {e}')