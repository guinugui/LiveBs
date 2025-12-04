"""
Script para aplicar migration de assinatura
"""
import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv()

async def apply_migration():
    """Aplicar migration para adicionar campos de assinatura"""
    try:
        # Conectar ao banco
        conn = await asyncpg.connect(os.getenv("DATABASE_URL"))
        print("✅ Conectado ao banco PostgreSQL")
        
        # Ler migration SQL
        with open("migration_subscription.sql", "r", encoding="utf-8") as f:
            migration_sql = f.read()
        
        # Executar migration
        await conn.execute(migration_sql)
        print("✅ Migration aplicada com sucesso!")
        
        # Verificar se as colunas foram criadas
        result = await conn.fetch("""
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns 
            WHERE table_name = 'users' 
            AND column_name IN ('subscription_status', 'subscription_payment_id', 'subscription_date')
            ORDER BY column_name
        """)
        
        print("\n📊 Colunas de assinatura criadas:")
        for row in result:
            print(f"  - {row['column_name']}: {row['data_type']} (default: {row['column_default']})")
        
        # Verificar usuários existentes
        user_count = await conn.fetchval("SELECT COUNT(*) FROM users")
        pending_count = await conn.fetchval("SELECT COUNT(*) FROM users WHERE subscription_status = 'pending'")
        
        print(f"\n👥 Usuários no sistema: {user_count}")
        print(f"⏳ Usuários com status 'pending': {pending_count}")
        
        await conn.close()
        print("\n🎉 Migration concluída!")
        
    except Exception as e:
        print(f"❌ Erro ao aplicar migration: {e}")

if __name__ == "__main__":
    asyncio.run(apply_migration())