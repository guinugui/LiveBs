#!/bin/bash

# 🧪 SCRIPT DE TESTE PARA VERIFICAR SE TUDO ESTÁ FUNCIONANDO
# Execute após o deploy para validar a instalação

echo "🧪 TESTANDO INSTALAÇÃO LIVEBS"
echo "============================"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

test_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

test_fail() {
    echo -e "${RED}❌ $1${NC}"
}

test_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

PROJECT_DIR="$HOME/livebs_production"

echo "1. Testando Docker..."
if docker --version > /dev/null 2>&1; then
    test_success "Docker instalado"
else
    test_fail "Docker não encontrado"
fi

echo "2. Testando containers..."
if docker ps | grep -q livebs_postgres; then
    test_success "PostgreSQL container rodando"
else
    test_fail "PostgreSQL container não está rodando"
fi

if docker ps | grep -q livebs_redis; then
    test_success "Redis container rodando"
else
    test_fail "Redis container não está rodando"
fi

echo "3. Testando conectividade de rede..."
if nc -z localhost 5432; then
    test_success "PostgreSQL acessível na porta 5432"
else
    test_fail "PostgreSQL não acessível"
fi

if nc -z localhost 6379; then
    test_success "Redis acessível na porta 6379"
else
    test_fail "Redis não acessível"
fi

echo "4. Testando ambiente Python..."
if [ -f "$PROJECT_DIR/livebs/backend/venv/bin/python" ]; then
    test_success "Ambiente virtual Python criado"
else
    test_fail "Ambiente virtual não encontrado"
fi

echo "5. Testando serviços systemd..."
if systemctl is-active --quiet livebs-api; then
    test_success "Serviço livebs-api ativo"
else
    test_warning "Serviço livebs-api não está ativo"
fi

if systemctl is-active --quiet livebs-celery; then
    test_success "Serviço livebs-celery ativo"
else
    test_warning "Serviço livebs-celery não está ativo"
fi

echo "6. Testando API endpoints..."
if curl -f -s http://localhost:8001/health > /dev/null; then
    test_success "API endpoint /health respondendo"
    
    # Testar conteúdo da resposta
    HEALTH_RESPONSE=$(curl -s http://localhost:8001/health)
    echo "   Resposta: $HEALTH_RESPONSE"
else
    test_fail "API endpoint /health não está respondendo"
fi

if curl -f -s http://localhost:8001/ > /dev/null; then
    test_success "API root endpoint respondendo"
else
    test_fail "API root endpoint não está respondendo"
fi

echo "7. Testando Nginx..."
if curl -f -s http://localhost:80/health > /dev/null; then
    test_success "Nginx proxy funcionando"
else
    test_warning "Nginx proxy pode não estar funcionando"
fi

echo "8. Verificando logs..."
echo "   Últimas 5 linhas do log da API:"
sudo journalctl -u livebs-api --no-pager -n 5

echo ""
echo "9. Testando banco de dados..."
cd $PROJECT_DIR/livebs/backend
source venv/bin/activate

python3 -c "
import asyncio
from app.async_database import async_db

async def test_db():
    try:
        await async_db.connect()
        result = await async_db.execute_one('SELECT COUNT(*) as tables FROM information_schema.tables WHERE table_schema = \\'public\\'')
        print(f'✅ Banco conectado - {result[\"tables\"]} tabelas encontradas')
        await async_db.disconnect()
    except Exception as e:
        print(f'❌ Erro no banco: {e}')

asyncio.run(test_db())
"

echo ""
echo "10. Informações do sistema..."
echo "   CPU: $(nproc) cores"
echo "   RAM: $(free -h | awk '/^Mem:/ {print $2}')"
echo "   Disco: $(df -h / | awk 'NR==2{print $4}')"
echo "   Uptime: $(uptime -p)"

echo ""
echo "📊 RESUMO DOS TESTES"
echo "==================="
echo "Se todos os itens estão ✅, sua instalação está perfeita!"
echo "Se há itens ⚠️  ou ❌, verifique os logs:"
echo ""
echo "🔍 Comandos de debug úteis:"
echo "  • docker ps                          # Ver containers"
echo "  • docker logs livebs_postgres        # Logs PostgreSQL"
echo "  • docker logs livebs_redis           # Logs Redis"
echo "  • sudo journalctl -u livebs-api -f  # Logs API em tempo real"
echo "  • sudo systemctl status livebs-api  # Status do serviço"
echo "  • curl -v http://localhost:8001/health # Testar API manualmente"
echo ""
echo "🌐 URL pública: http://$(curl -s ifconfig.me)/health"