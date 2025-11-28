#!/usr/bin/env python3
"""
Script para limpar todos os planos alimentares
"""

from app.database import db

def main():
    print("🍽️ Limpando todos os planos alimentares...")
    
    with db.get_db_cursor() as cursor:
        # Buscar tabelas relacionadas a planos alimentares
        food_tables = ['saved_meal_plans', 'meal_plans', 'meals', 'meal_logs']
        
        for table_name in food_tables:
            try:
                # Verificar se a tabela existe e quantos registros tem
                cursor.execute(f"""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' AND table_name = '{table_name}'
                """)
                table_exists = cursor.fetchone()
                
                if table_exists:
                    cursor.execute(f'SELECT COUNT(*) FROM {table_name}')
                    count_result = cursor.fetchone()
                    
                    # Extrair o valor do count independente do formato
                    if isinstance(count_result, dict):
                        total_count = count_result.get('COUNT(*)', count_result.get('count', 0))
                    elif isinstance(count_result, (list, tuple)):
                        total_count = count_result[0]
                    else:
                        total_count = count_result
                        
                    print(f'📊 {table_name}: {total_count} registros')
                    
                    if total_count > 0:
                        print(f'🗑️ Limpando tabela {table_name}...')
                        cursor.execute(f'DELETE FROM {table_name}')
                        print(f'✅ Tabela {table_name} limpa!')
                        
                        # Verificar se foi deletado
                        cursor.execute(f'SELECT COUNT(*) FROM {table_name}')
                        new_result = cursor.fetchone()
                        
                        if isinstance(new_result, dict):
                            final_count = new_result.get('COUNT(*)', new_result.get('count', 0))
                        elif isinstance(new_result, (list, tuple)):
                            final_count = new_result[0]
                        else:
                            final_count = new_result
                            
                        print(f'✅ Registros restantes: {final_count}')
                    else:
                        print(f'ℹ️ Tabela {table_name} já estava vazia')
                else:
                    print(f'⚠️ Tabela {table_name} não existe')
                    
            except Exception as e:
                print(f'❌ Erro ao limpar {table_name}: {e}')
        
        print('\n🎉 Limpeza de planos alimentares concluída!')

if __name__ == "__main__":
    main()