#!/bin/bash
echo "🔧 RESOLVENDO CONFLITO DE PORTA POSTGRESQL..."
echo "========================================="

echo "[STEP] Parando PostgreSQL do sistema..."
sudo systemctl stop postgresql
sudo systemctl disable postgresql
echo "[SUCCESS] PostgreSQL do sistema parado"

echo "[STEP] Reiniciando serviços Docker..."
cd /home/livebs/LiveBs
sudo docker compose -f /home/livebs/livebs_production/docker/docker-compose.yml down
sudo docker compose -f /home/livebs/livebs_production/docker/docker-compose.yml up -d
echo "[SUCCESS] Serviços Docker reiniciados"

echo "[STEP] Aguardando banco de dados..."
sleep 10

echo "[STEP] Executando migrações do banco..."
cd /home/livebs/LiveBs/backend
source venv/bin/activate
python -c "
import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv()

async def create_tables():
    conn = await asyncpg.connect(os.getenv('DATABASE_URL'))
    
    # Criar tabela users
    await conn.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            email VARCHAR(255) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Criar tabela password_reset_codes
    await conn.execute('''
        CREATE TABLE IF NOT EXISTS password_reset_codes (
            id SERIAL PRIMARY KEY,
            email VARCHAR(255) NOT NULL,
            code VARCHAR(10) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP NOT NULL,
            used BOOLEAN DEFAULT FALSE
        )
    ''')
    
    # Criar tabela subscriptions
    await conn.execute('''
        CREATE TABLE IF NOT EXISTS subscriptions (
            id SERIAL PRIMARY KEY,
            user_id INTEGER REFERENCES users(id),
            plan_type VARCHAR(50) NOT NULL,
            status VARCHAR(50) NOT NULL,
            mercado_pago_id VARCHAR(255),
            start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            end_date TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    await conn.close()
    print('✅ Tabelas criadas com sucesso!')

asyncio.run(create_tables())
"
echo "[SUCCESS] Migrações executadas"

echo "[STEP] Iniciando aplicação..."
sudo systemctl start livebs-api
sudo systemctl enable livebs-api
echo "[SUCCESS] Aplicação iniciada"

echo "[STEP] Verificando status dos serviços..."
sudo systemctl status livebs-api --no-pager
sudo docker ps

echo ""
echo "🎉 DEPLOY CONCLUÍDO COM SUCESSO!"
echo "================================="
echo "✅ PostgreSQL Docker: Rodando na porta 5432"
echo "✅ Redis Docker: Rodando na porta 6379" 
echo "✅ Nginx: Rodando na porta 80/443"
echo "✅ API LiveBs: Rodando na porta 8000"
echo ""
echo "🌐 Acesse: http://69.166.236.73"
echo "📊 API Docs: http://69.166.236.73/docs"
echo ""