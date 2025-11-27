import pg8000.native

try:
    conn = pg8000.native.Connection('postgres', password='MCguinu02', database='livebs_db')
    
    # Verificar se a coluna goal existe
    result = conn.run("SELECT column_name FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'goal'")
    
    if result:
        print('✅ Coluna goal já existe!')
    else:
        print('➕ Adicionando coluna goal...')
        conn.run('ALTER TABLE profiles ADD COLUMN goal VARCHAR(50)')
        
        print('🔄 Atualizando registros existentes...')
        conn.run("UPDATE profiles SET goal = 'weight_loss' WHERE goal IS NULL")
        
        print('⚙️ Definindo valor padrão...')
        conn.run("ALTER TABLE profiles ALTER COLUMN goal SET DEFAULT 'weight_loss'")
        
        print('✅ Coluna goal configurada com sucesso!')
    
    # Verificar estrutura final
    columns = conn.run("SELECT column_name FROM information_schema.columns WHERE table_name = 'profiles' ORDER BY ordinal_position")
    print('\n📋 Colunas da tabela profiles:')
    for col in columns:
        print(f'  - {col[0]}')
        
except Exception as e:
    print(f'❌ Erro: {e}')
finally:
    if 'conn' in locals():
        conn.close()