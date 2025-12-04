#!/usr/bin/env python3
import asyncio
import asyncpg

async def test_connection():
    """Teste simples de conexão com PostgreSQL"""
    try:
        print("🔌 Testando conexão PostgreSQL...")
        conn = await asyncpg.connect('postgresql://postgres:MCguinu02@127.0.0.1:5432/livebs_db')
        print("✅ Conexão estabelecida com sucesso!")
        
        # Testar uma query simples
        result = await conn.fetchval("SELECT current_database()")
        print(f"📊 Banco conectado: {result}")
        
        # Verificar se tabela users existe
        table_exists = await conn.fetchval("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name = 'users'
            )
        """)
        print(f"👥 Tabela 'users' existe: {'SIM' if table_exists else 'NÃO'}")
        
        if table_exists:
            user_count = await conn.fetchval("SELECT COUNT(*) FROM users")
            print(f"📊 Total de usuários: {user_count}")
        
        await conn.close()
        print("🔌 Conexão fechada")
        
    except Exception as e:
        print(f"❌ Erro na conexão: {e}")

if __name__ == "__main__":
    asyncio.run(test_connection())