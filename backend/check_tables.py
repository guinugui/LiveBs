from app.database import db

with db.get_db_cursor() as cursor:
    # Listar todas as tabelas
    cursor.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public'
        ORDER BY table_name;
    """)
    
    tables = cursor.fetchall()
    print('Tabelas existentes:')
    for table in tables:
        print(f'  - {table["table_name"]}')
    
    # Verificar estrutura da tabela de perfis se existir
    cursor.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name LIKE '%profile%';
    """)
    
    profile_tables = cursor.fetchall()
    if profile_tables:
        print(f'\nTabelas de perfil encontradas: {profile_tables}')
        
        # Mostrar estrutura da primeira tabela de perfil
        table_name = profile_tables[0]['table_name']
        cursor.execute(f"""
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = '{table_name}'
            ORDER BY ordinal_position;
        """)
        
        columns = cursor.fetchall()
        print(f'\nEstrutura da tabela {table_name}:')
        for col in columns:
            print(f'  - {col["column_name"]}: {col["data_type"]}')