#!/usr/bin/env python3
"""
Script para limpar o histórico do Personal Virtual
"""

from app.database import db

def main():
    print("🔍 Verificando tabelas existentes...")
    
    with db.get_db_cursor() as cursor:
        # Listar todas as tabelas
        cursor.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        ORDER BY table_name
        """)
        tables = cursor.fetchall()
        print('📋 Tabelas encontradas:')
        for table in tables:
            table_name = table[0] if isinstance(table, (list, tuple)) else table.get('table_name', str(table))
            print(f'  - {table_name}')
        
        # Verificar se existe tabela com "personal" no nome
        personal_tables = [t for t in tables if 'personal' in str(t).lower()]
        if personal_tables:
            print(f'\n📱 Tabelas relacionadas ao Personal Virtual:')
            for table in personal_tables:
                table_name = table[0] if isinstance(table, (list, tuple)) else table.get('table_name', str(table))
                print(f'  - {table_name}')
                
                try:
                    cursor.execute(f'SELECT COUNT(*) FROM {table_name}')
                    count_result = cursor.fetchone()
                    
                    # Extrair o valor do count independente do formato
                    if isinstance(count_result, dict):
                        total_count = count_result.get('COUNT(*)', count_result.get('count', 0))
                    elif isinstance(count_result, (list, tuple)):
                        total_count = count_result[0]
                    else:
                        total_count = count_result
                        
                    print(f'    📊 Registros: {total_count}')
                    
                    if total_count > 0:
                        print(f'    🗑️ Limpando tabela {table_name}...')
                        cursor.execute(f'DELETE FROM {table_name}')
                        print(f'    ✅ Tabela {table_name} limpa!')
                        
                        # Verificar novamente
                        cursor.execute(f'SELECT COUNT(*) FROM {table_name}')
                        new_result = cursor.fetchone()
                        
                        if isinstance(new_result, dict):
                            final_count = new_result.get('COUNT(*)', new_result.get('count', 0))
                        elif isinstance(new_result, (list, tuple)):
                            final_count = new_result[0]
                        else:
                            final_count = new_result
                            
                        print(f'    ✅ Registros restantes: {final_count}')
                    else:
                        print(f'    ℹ️ Tabela {table_name} já estava vazia')
                except Exception as e:
                    print(f'    ❌ Erro ao acessar {table_name}: {e}')
        else:
            print('\n❓ Não encontrei tabelas relacionadas ao Personal Virtual')
            print('🔍 Procurando por tabelas com "chat" ou "message" no nome...')
            
            chat_tables = []
            for table in tables:
                table_name = table[0] if isinstance(table, (list, tuple)) else table.get('table_name', str(table))
                if any(word in table_name.lower() for word in ['chat', 'message', 'history', 'conversation']):
                    chat_tables.append(table_name)
            
            if chat_tables:
                print('💬 Possíveis tabelas de chat encontradas:')
                for table_name in chat_tables:
                    print(f'  - {table_name}')
                    try:
                        cursor.execute(f'SELECT COUNT(*) FROM {table_name}')
                        count = cursor.fetchone()
                        total_count = count[0] if count else 0
                        print(f'    📊 Registros: {total_count}')
                        
                        if total_count > 0:
                            print(f'    🗑️ Limpando tabela {table_name}...')
                            cursor.execute(f'DELETE FROM {table_name}')
                            print(f'    ✅ Tabela {table_name} limpa!')
                    except Exception as e:
                        print(f'    ❌ Erro ao limpar {table_name}: {e}')
            else:
                print('❌ Nenhuma tabela de chat encontrada')

if __name__ == "__main__":
    main()