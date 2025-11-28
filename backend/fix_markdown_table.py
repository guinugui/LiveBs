#!/usr/bin/env python3
"""
Script para adicionar coluna markdown_content à tabela saved_workout_plans
"""

from app.database import db

def main():
    print("🔧 Verificando e atualizando estrutura da tabela saved_workout_plans...")
    
    with db.get_db_cursor() as cursor:
        # Verificar estrutura atual
        cursor.execute("""
        SELECT column_name, data_type, is_nullable 
        FROM information_schema.columns 
        WHERE table_name = 'saved_workout_plans'
        ORDER BY ordinal_position
        """)
        cols = cursor.fetchall()
        print('\n=== COLUNAS ATUAIS ===')
        for col in cols:
            if isinstance(col, dict):
                print(f'{col["column_name"]}: {col["data_type"]} (nullable: {col["is_nullable"]})')
            else:
                # pg8000 retorna lista
                print(f'{col[0]}: {col[1]} (nullable: {col[2]})')
        
        # Verificar se já existe coluna markdown_content
        cursor.execute("""
        SELECT column_name FROM information_schema.columns 
        WHERE table_name = 'saved_workout_plans' 
        AND column_name = 'markdown_content'
        """)
        has_markdown = cursor.fetchone()
        
        if not has_markdown:
            print('\n=== ADICIONANDO COLUNA MARKDOWN ===')
            cursor.execute('ALTER TABLE saved_workout_plans ADD COLUMN markdown_content TEXT')
            print('✅ Coluna markdown_content adicionada!')
        else:
            print('✅ Coluna markdown_content já existe!')
            
        # Verificar alguns registros existentes
        cursor.execute("""
        SELECT id, plan_name, 
               CASE 
                 WHEN LENGTH(workout_data::text) > 100 THEN LEFT(workout_data::text, 100) || '...'
                 ELSE workout_data::text
               END as workout_preview
        FROM saved_workout_plans 
        ORDER BY created_at DESC 
        LIMIT 3
        """)
        records = cursor.fetchall()
        
        print('\n=== REGISTROS EXISTENTES ===')
        for record in records:
            print(f"ID: {record[0]}")
            print(f"Nome: {record[1]}")  
            print(f"Preview: {record[2]}")
            print("---")

if __name__ == "__main__":
    main()