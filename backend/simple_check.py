import psycopg2
from psycopg2.extras import RealDictCursor

try:
    conn = psycopg2.connect(
        host='localhost',
        port=5432,
        database='livebs_db',
        user='postgres',
        password='guinu02'
    )
    
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    print('✅ Conectado ao banco!')
    
    cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'")
    tables = [row['table_name'] for row in cursor.fetchall()]
    
    print(f'Tabelas existentes: {tables}')
    
    required = ['users', 'profiles', 'meal_plans', 'meals', 'dietary_restrictions', 'dietary_preferences']
    missing = [t for t in required if t not in tables]
    
    if missing:
        print(f'FALTAM: {missing}')
    else:
        print('TODAS AS TABELAS EXISTEM!')
        
    conn.close()
    
except Exception as e:
    print(f'ERRO: {e}')