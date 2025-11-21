import psycopg2
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.config import settings

# Parse database URL
connection_params = settings.database_url.replace('postgresql://', '')
parts = connection_params.split('@')
user_pass = parts[0].split(':')
host_db = parts[1].split('/')
host_port = host_db[0].split(':')

params = {
    'user': user_pass[0],
    'password': user_pass[1],
    'host': host_port[0],
    'port': host_port[1] if len(host_port) > 1 else '5432',
    'database': host_db[1]
}

conn = psycopg2.connect(**params)
cursor = conn.cursor()

try:
    # Atualiza created_at para hoje
    cursor.execute("""
        UPDATE users 
        SET created_at = CURRENT_TIMESTAMP 
        WHERE email = 'gui@gmail.com'
    """)
    conn.commit()
    
    # Verifica resultado
    cursor.execute("""
        SELECT created_at, EXTRACT(DOW FROM created_at) as day 
        FROM users 
        WHERE email = 'gui@gmail.com'
    """)
    result = cursor.fetchone()
    
    day_names = {
        0: 'Domingo',
        1: 'Segunda-feira',
        2: 'Terça-feira',
        3: 'Quarta-feira',
        4: 'Quinta-feira',
        5: 'Sexta-feira',
        6: 'Sábado'
    }
    
    print(f'✅ Atualizado com sucesso!')
    print(f'Data de criação: {result[0]}')
    print(f'Dia da semana: {day_names[int(result[1])]}')
    print(f'\n💡 Agora o aviso de atualização aparecerá toda {day_names[int(result[1])]}')
    
except Exception as e:
    conn.rollback()
    print(f'❌ Erro: {e}')
finally:
    cursor.close()
    conn.close()
