#!/usr/bin/env python3
"""
Script para verificar o estado do banco de dados LiveBs
"""

import psycopg2
from psycopg2.extras import RealDictCursor
import sys
import os

def check_database():
    try:
        # Conectar ao banco
        conn = psycopg2.connect(
            host='localhost',
            port=5432,
            database='livebs_db',
            user='postgres',
            password='guinu02'
        )
        
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        print('=== CONEXÃO COM BANCO DE DADOS ===')
        print('✅ Conexão estabelecida com sucesso!')
        
        # Listar todas as tabelas
        print('\n=== TABELAS EXISTENTES ===')
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            ORDER BY table_name;
        """)
        
        tables = cursor.fetchall()
        for table in tables:
            print(f'📋 {table["table_name"]}')
        
        print(f'\n📊 Total de tabelas: {len(tables)}')
        
        # Verificar tabelas específicas necessárias para IA
        required_tables = [
            'users', 'profiles', 'meal_plans', 'meals', 
            'dietary_restrictions', 'dietary_preferences',
            'chat_messages', 'weight_logs', 'water_logs', 'meal_logs'
        ]
        
        existing_table_names = [t['table_name'] for t in tables]
        
        print('\n=== VERIFICAÇÃO DE TABELAS NECESSÁRIAS ===')
        missing_tables = []
        
        for table in required_tables:
            if table in existing_table_names:
                print(f'✅ {table} - EXISTE')
            else:
                print(f'❌ {table} - NÃO EXISTE')
                missing_tables.append(table)
        
        if missing_tables:
            print(f'\n⚠️  TABELAS FALTANDO: {len(missing_tables)}')
            print('Para criar as tabelas, execute o script schema.sql')
        else:
            print('\n🎉 TODAS AS TABELAS NECESSÁRIAS EXISTEM!')
        
        # Verificar se há dados de usuários
        if 'users' in existing_table_names:
            cursor.execute("SELECT COUNT(*) as count FROM users")
            user_count = cursor.fetchone()['count']
            print(f'\n👥 Usuários cadastrados: {user_count}')
        
        conn.close()
        return len(missing_tables) == 0
        
    except psycopg2.Error as e:
        print(f'❌ Erro de conexão com o banco: {e}')
        return False
    except Exception as e:
        print(f'❌ Erro inesperado: {e}')
        return False

if __name__ == "__main__":
    success = check_database()
    sys.exit(0 if success else 1)