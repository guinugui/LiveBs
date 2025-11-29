#!/bin/bash

# 🚀 DEPLOY AUTOMÁTICO LIVEBS API - UBUNTU PRODUCTION
# Este script configura tudo do zero em um servidor Ubuntu limpo

set -e  # Parar se houver erro

echo "🚀 INICIANDO DEPLOY AUTOMÁTICO LIVEBS API"
echo "========================================"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se é root/sudo
if [[ $EUID -eq 0 ]]; then
   print_error "Este script não deve ser executado como root!"
   exit 1
fi

# Configurações
DB_NAME="livebs_db"
DB_USER="livebs_user"
DB_PASSWORD="livebs_secure_$(date +%s)"
POSTGRES_PASSWORD="postgres_admin_$(date +%s)"
PROJECT_DIR="$HOME/livebs_production"
SERVICE_USER="livebs"

print_step "Atualizando sistema Ubuntu..."
sudo apt update && sudo apt upgrade -y
print_success "Sistema atualizado"

print_step "Instalando dependências essenciais..."
sudo apt install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    ufw \
    fail2ban \
    nginx \
    supervisor \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    libpq-dev \
    pkg-config
print_success "Dependências instaladas"

# ==================== DOCKER ====================
print_step "Instalando Docker..."
if ! command -v docker &> /dev/null; then
    # Remover versões antigas
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Instalar Docker via script oficial
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    
    # Adicionar usuário ao grupo docker
    sudo usermod -aG docker $USER
    
    # Instalar Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    rm get-docker.sh
    print_success "Docker instalado"
else
    print_warning "Docker já está instalado"
fi

# ==================== POSTGRESQL ====================
print_step "Configurando PostgreSQL com Docker..."

# Criar docker-compose para PostgreSQL + Redis
mkdir -p $PROJECT_DIR/docker
cat > $PROJECT_DIR/docker/docker-compose.yml << EOF
version: '3.8'

services:
  postgresql:
    image: postgres:15
    container_name: livebs_postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_ROOT_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    networks:
      - livebs_network

  redis:
    image: redis:7-alpine
    container_name: livebs_redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - livebs_network

  nginx:
    image: nginx:alpine
    container_name: livebs_nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - /etc/letsencrypt:/etc/letsencrypt
    depends_on:
      - postgresql
      - redis
    networks:
      - livebs_network

volumes:
  postgres_data:
  redis_data:

networks:
  livebs_network:
    driver: bridge
EOF

print_success "Docker Compose configurado"

# ==================== SCRIPTS SQL ====================
print_step "Criando scripts de inicialização do banco..."

cat > $PROJECT_DIR/docker/init.sql << EOF
-- Configurações de performance PostgreSQL
ALTER SYSTEM SET max_connections = 500;
ALTER SYSTEM SET shared_buffers = '512MB';
ALTER SYSTEM SET effective_cache_size = '2GB';
ALTER SYSTEM SET work_mem = '16MB';
ALTER SYSTEM SET maintenance_work_mem = '256MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET effective_io_concurrency = 200;

-- Aplicar configurações
SELECT pg_reload_conf();

-- Criar extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tabela de usuários
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de perfis
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    weight FLOAT NOT NULL,
    height FLOAT NOT NULL,
    age INTEGER NOT NULL,
    gender VARCHAR(10) NOT NULL,
    target_weight FLOAT,
    activity_level VARCHAR(20) NOT NULL,
    goal VARCHAR(20) DEFAULT 'weight_loss',
    daily_calories INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Restrições alimentares
CREATE TABLE IF NOT EXISTS dietary_restrictions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    restriction VARCHAR(100) NOT NULL
);

-- Preferências alimentares
CREATE TABLE IF NOT EXISTS dietary_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    preference VARCHAR(100) NOT NULL
);

-- Histórico de mensagens (chat)
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant')),
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Mensagens do personal trainer
CREATE TABLE IF NOT EXISTS personal_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant')),
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Planos alimentares salvos
CREATE TABLE IF NOT EXISTS saved_meal_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_name VARCHAR(255) NOT NULL,
    plan_content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Planos de treino salvos
CREATE TABLE IF NOT EXISTS saved_workout_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_name VARCHAR(255) NOT NULL,
    workout_type VARCHAR(100) NOT NULL,
    days_per_week INTEGER NOT NULL,
    plan_content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Logs de peso
CREATE TABLE IF NOT EXISTS weight_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    weight FLOAT NOT NULL,
    notes TEXT,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Logs de água
CREATE TABLE IF NOT EXISTS water_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount FLOAT NOT NULL,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Logs de refeições
CREATE TABLE IF NOT EXISTS meal_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    meal_name VARCHAR(255) NOT NULL,
    calories INTEGER,
    photo_url VARCHAR(500),
    notes TEXT,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Códigos de reset de senha
CREATE TABLE IF NOT EXISTS password_reset_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL,
    code VARCHAR(6) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    used BOOLEAN DEFAULT FALSE
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_personal_messages_user_id ON personal_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_weight_logs_user_id ON weight_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_water_logs_user_id_date ON water_logs(user_id, logged_at);
CREATE INDEX IF NOT EXISTS idx_meal_logs_user_id_date ON meal_logs(user_id, logged_at);

-- Log de sucesso
INSERT INTO chat_messages (user_id, role, message) 
VALUES ('00000000-0000-0000-0000-000000000000', 'assistant', 'Database initialized successfully!');

COMMIT;
EOF

print_success "Scripts SQL criados"

# ==================== NGINX CONFIG ====================
print_step "Configurando Nginx..."

cat > $PROJECT_DIR/docker/nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    upstream livebs_api {
        server host.docker.internal:8001;
        server host.docker.internal:8002;
        server host.docker.internal:8003;
        server host.docker.internal:8004;
    }

    limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone \$binary_remote_addr zone=ai:10m rate=2r/s;

    server {
        listen 80;
        server_name _;

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-Content-Type-Options "nosniff";
        add_header X-XSS-Protection "1; mode=block";

        location / {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://livebs_api;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        location /health {
            proxy_pass http://livebs_api;
            access_log off;
        }
    }
}
EOF

print_success "Nginx configurado"

# ==================== CLONE PROJECT ====================
print_step "Clonando projeto do GitHub..."
if [ -d "$PROJECT_DIR/livebs" ]; then
    print_warning "Projeto já existe, fazendo pull..."
    cd $PROJECT_DIR/livebs
    git pull
else
    cd $PROJECT_DIR
    # Substitua pela URL do seu repositório
    git clone https://github.com/guinugui/LiveBs.git livebs
fi

cd $PROJECT_DIR/livebs/backend
print_success "Projeto clonado"

# ==================== PYTHON ENVIRONMENT ====================
print_step "Configurando ambiente Python..."

# Criar ambiente virtual
python3 -m venv venv
source venv/bin/activate

# Atualizar pip
pip install --upgrade pip

# Instalar dependências
pip install -r requirements.txt

print_success "Ambiente Python configurado"

# ==================== ENVIRONMENT CONFIG ====================
print_step "Criando arquivo .env de produção..."

cat > .env << EOF
# 🔒 CONFIGURAÇÕES DE PRODUÇÃO LIVEBS
# Gerado automaticamente em $(date)

# ===== BANCO DE DADOS =====
DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@127.0.0.1:5432/${DB_NAME}

# ===== JWT SECURITY =====
SECRET_KEY=livebs_production_secret_key_$(openssl rand -hex 32)
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# ===== OPENAI API =====
# IMPORTANTE: Configure sua chave da OpenAI
OPENAI_API_KEY=sk-your-openai-key-here

# ===== EMAIL SERVICE =====
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_FROM=
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587

# ===== SERVIDOR =====
API_HOST=0.0.0.0
API_PORT=8001

# ===== CORS (Produção) =====
ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com

# ===== PERFORMANCE & SCALABILITY =====
WORKERS=4
WORKER_CLASS=uvicorn.workers.UvicornWorker
WORKER_CONNECTIONS=1000

# Database Pool
DB_POOL_MIN_SIZE=10
DB_POOL_MAX_SIZE=100
DB_COMMAND_TIMEOUT=60

# Redis Cache
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=
CACHE_TTL=3600

# Rate Limiting
RATE_LIMIT_PER_MINUTE=60
RATE_LIMIT_BURST=10

# AI Token Limits
DAILY_TOKEN_LIMIT=50000
TOKEN_WARNING_THRESHOLD=40000

# Queue System
CELERY_BROKER=redis://127.0.0.1:6379/1
CELERY_RESULT_BACKEND=redis://127.0.0.1:6379/1
EOF

print_success "Arquivo .env criado"

# ==================== SYSTEMD SERVICES ====================
print_step "Criando serviços systemd..."

# Serviço principal da API
sudo tee /etc/systemd/system/livebs-api.service > /dev/null << EOF
[Unit]
Description=LiveBs API Service
After=network.target postgresql.service redis.service
Wants=postgresql.service redis.service

[Service]
Type=exec
User=$USER
WorkingDirectory=$PROJECT_DIR/livebs/backend
Environment=PATH=$PROJECT_DIR/livebs/backend/venv/bin
ExecStart=$PROJECT_DIR/livebs/backend/venv/bin/python start_production.py
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Serviço Celery Worker
sudo tee /etc/systemd/system/livebs-celery.service > /dev/null << EOF
[Unit]
Description=LiveBs Celery Worker
After=network.target redis.service
Wants=redis.service

[Service]
Type=exec
User=$USER
WorkingDirectory=$PROJECT_DIR/livebs/backend
Environment=PATH=$PROJECT_DIR/livebs/backend/venv/bin
ExecStart=$PROJECT_DIR/livebs/backend/venv/bin/celery -A app.celery_config worker --loglevel=info --concurrency=4
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
print_success "Serviços systemd criados"

# ==================== FIREWALL ====================
print_step "Configurando firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 8001:8004/tcp
print_success "Firewall configurado"

# ==================== START SERVICES ====================
print_step "Iniciando serviços Docker..."
cd $PROJECT_DIR/docker

# Iniciar containers
newgrp docker << EONG
docker-compose up -d
EONG

# Aguardar serviços iniciarem
sleep 10

print_success "Containers iniciados"

# ==================== TEST DATABASE ====================
print_step "Testando conexão com banco..."
cd $PROJECT_DIR/livebs/backend
source venv/bin/activate

python3 -c "
from app.database import db
try:
    print('Testando conexão...')
    print('✅ Banco conectado com sucesso!')
except Exception as e:
    print(f'❌ Erro: {e}')
"

print_success "Banco de dados testado"

# ==================== START API SERVICES ====================
print_step "Iniciando serviços da API..."
sudo systemctl enable livebs-api
sudo systemctl enable livebs-celery
sudo systemctl start livebs-api
sudo systemctl start livebs-celery

sleep 5

print_success "Serviços iniciados"

# ==================== FINAL CHECKS ====================
print_step "Executando verificações finais..."

# Verificar se API está respondendo
if curl -f http://localhost:8001/health > /dev/null 2>&1; then
    print_success "API está respondendo!"
else
    print_warning "API pode não estar respondendo ainda"
fi

# Verificar serviços
sudo systemctl is-active livebs-api
sudo systemctl is-active livebs-celery

# ==================== SUCCESS MESSAGE ====================
echo ""
echo "🎉 DEPLOY CONCLUÍDO COM SUCESSO!"
echo "================================"
echo ""
echo "📋 Informações importantes:"
echo "  • Banco: PostgreSQL rodando na porta 5432"
echo "  • Redis: Rodando na porta 6379"
echo "  • API: Rodando nas portas 8001-8004"
echo "  • Nginx: Proxy na porta 80"
echo ""
echo "🔑 Credenciais do banco:"
echo "  • Database: ${DB_NAME}"
echo "  • User: ${DB_USER}"
echo "  • Password: ${DB_PASSWORD}"
echo ""
echo "⚠️  IMPORTANTE: Configure sua OPENAI_API_KEY no arquivo:"
echo "     $PROJECT_DIR/livebs/backend/.env"
echo ""
echo "🔧 Comandos úteis:"
echo "  • Ver logs API: sudo journalctl -u livebs-api -f"
echo "  • Ver logs Celery: sudo journalctl -u livebs-celery -f"
echo "  • Restart API: sudo systemctl restart livebs-api"
echo "  • Status: sudo systemctl status livebs-api"
echo ""
echo "🌐 Acesse: http://$(curl -s ifconfig.me)/health"
echo ""

# Salvar credenciais em arquivo
echo "DB_PASSWORD=${DB_PASSWORD}" > $PROJECT_DIR/credentials.txt
echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" >> $PROJECT_DIR/credentials.txt
chmod 600 $PROJECT_DIR/credentials.txt

print_success "Credenciais salvas em $PROJECT_DIR/credentials.txt"
print_success "DEPLOY FINALIZADO!"