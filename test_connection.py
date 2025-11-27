import psycopg2

try:
    conn = psycopg2.connect(
        host='localhost',
        database='nutri_ai_app', 
        user='postgres',
        password='postgres',
        client_encoding='utf8'
    )
    print('Conexao PostgreSQL OK!')
    
    # Testa uma query simples
    cursor = conn.cursor()
    cursor.execute("SELECT version();")
    version = cursor.fetchone()
    print(f'PostgreSQL Version: {version[0][:50]}...')
    
    cursor.close()
    conn.close()
    print('Teste de conexao concluido com sucesso!')
    
except Exception as e:
    print(f'Erro na conexao: {str(e)}')