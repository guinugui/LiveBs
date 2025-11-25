"""Script para verificar tabelas do banco de dados"""
from app.database import db

print("🔍 Verificando banco de dados...")

with db.get_db_cursor() as cursor:
    # Verifica tabelas existentes
    cursor.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public'
        ORDER BY table_name
    """)
    tables = cursor.fetchall()
    
    if tables:
        print(f"\n✅ Total de tabelas encontradas: {len(tables)}")
        print("\n📋 Tabelas existentes:")
        for table in tables:
            print(f"  - {table['table_name']}")
    else:
        print("\n❌ Nenhuma tabela encontrada no banco de dados")
        print("Execute o schema.sql para criar as tabelas")
    
    # Verifica especificamente as tabelas de meal plan
    print("\n🔍 Verificando tabelas de meal plan...")
    cursor.execute("""
        SELECT table_name, column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name IN ('meal_plans', 'meals')
        ORDER BY table_name, ordinal_position
    """)
    columns = cursor.fetchall()
    
    if columns:
        print("\n✅ Estrutura das tabelas meal_plans e meals:")
        current_table = None
        for col in columns:
            if current_table != col['table_name']:
                current_table = col['table_name']
                print(f"\n  📊 {current_table}:")
            print(f"    - {col['column_name']} ({col['data_type']})")
    else:
        print("\n❌ Tabelas meal_plans ou meals não encontradas")

print("\n✅ Verificação concluída!")
