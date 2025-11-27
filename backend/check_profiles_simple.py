import psycopg2

try:
    conn = psycopg2.connect(
        host='localhost',
        database='livebs_db',
        user='postgres',
        password='admin'
    )
    cursor = conn.cursor()
    
    print('=== ESTRUTURA DA TABELA PROFILES ===')
    cursor.execute("""
        SELECT column_name, data_type, is_nullable, column_default 
        FROM information_schema.columns 
        WHERE table_name = 'profiles'
        ORDER BY ordinal_position
    """)
    columns = cursor.fetchall()
    
    if not columns:
        print("Tabela 'profiles' nao encontrada!")
    else:
        for col in columns:
            print(f"{col[0]:20} | {col[1]:15} | Nullable: {col[2]:3} | Default: {col[3] or 'None'}")
    
    print('\n=== DADOS EXISTENTES ===')
    cursor.execute("SELECT COUNT(*) FROM profiles")
    count = cursor.fetchone()[0]
    print(f"Total de registros: {count}")
    
    if count > 0:
        cursor.execute("SELECT * FROM profiles LIMIT 3")
        profiles = cursor.fetchall()
        for profile in profiles:
            print(profile)
    
    cursor.close()
    conn.close()

except Exception as e:
    print(f"Erro: {e}")