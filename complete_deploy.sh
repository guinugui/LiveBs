#!/bin/bash
echo "🔧 NAVEGAÇÃO E EXECUÇÃO DO DEPLOY"
echo "================================="

echo "[STEP] Navegando para o diretório correto..."
cd /home/livebs/LiveBs

echo "[STEP] Verificando status do Git..."
pwd
git status

echo "[STEP] Fazendo pull das últimas mudanças..."
git pull

echo "[STEP] Parando PostgreSQL do sistema..."
sudo systemctl stop postgresql
sudo systemctl disable postgresql
echo "[SUCCESS] PostgreSQL do sistema parado"

echo "[STEP] Parando containers existentes..."
sudo docker compose -f /home/livebs/livebs_production/docker/docker-compose.yml down 2>/dev/null || true

echo "[STEP] Iniciando serviços Docker..."
sudo docker compose -f /home/livebs/livebs_production/docker/docker-compose.yml up -d

echo "[STEP] Aguardando banco de dados inicializar..."
sleep 15

echo "[STEP] Ativando ambiente virtual e executando migrações..."
cd /home/livebs/LiveBs/backend
source venv/bin/activate

echo "[INFO] Testando conexão com banco..."
python -c "
import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv()

async def test_and_migrate():
    try:
        # Testar conexão
        conn = await asyncpg.connect(os.getenv('DATABASE_URL'))
        print('✅ Conexão com banco estabelecida')
        
        # Criar tabelas
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
        print('✅ Tabelas criadas/verificadas com sucesso!')
        
    except Exception as e:
        print(f'❌ Erro: {e}')
        
asyncio.run(test_and_migrate())
"

echo "[STEP] Iniciando serviço da aplicação..."
sudo systemctl restart livebs-api
sudo systemctl enable livebs-api

echo "[STEP] Verificando status final..."
echo "==================================="
echo "🐳 Docker Containers:"
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "🚀 Serviços System:"
sudo systemctl status livebs-api --no-pager -l
echo ""
echo "🔥 Logs da aplicação (últimas 20 linhas):"
sudo journalctl -u livebs-api -n 20 --no-pager

echo ""
echo "🎉 DEPLOY FINALIZADO!"
echo "===================="
echo "✅ API: http://69.166.236.73:8000"
echo "📚 Docs: http://69.166.236.73:8000/docs"
echo "🐘 PostgreSQL: Container rodando na porta 5432"
echo "🔴 Redis: Container rodando na porta 6379"
echo "🌍 Nginx: Proxy reverso ativo"
echo ""