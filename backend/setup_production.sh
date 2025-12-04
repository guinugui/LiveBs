#!/bin/bash

# Script de Setup para Produção - LiveBs Backend
# Configura HTTPS, Nginx, SSL e ambiente de produção no Ubuntu

set -e  # Parar em caso de erro

echo "🚀 SETUP PRODUÇÃO - LiveBs Backend"
echo "=================================="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variáveis de configuração
PROJECT_NAME="livebs"
DOMAIN="${DOMAIN:-your-domain.com}"  # Defina sua domain
EMAIL="${EMAIL:-admin@your-domain.com}"  # Defina seu email
PORT="${PORT:-8001}"
PROJECT_DIR="${PROJECT_DIR:-/opt/livebs}"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar se comando existe
check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 não está instalado!"
        return 1
    fi
    return 0
}

# 1. Atualizar sistema
update_system() {
    log_info "Atualizando sistema Ubuntu..."
    sudo apt update
    sudo apt upgrade -y
    log_success "Sistema atualizado"
}

# 2. Instalar dependências
install_dependencies() {
    log_info "Instalando dependências..."
    
    # Python e pip
    sudo apt install -y python3 python3-pip python3-venv
    
    # Nginx
    sudo apt install -y nginx
    
    # Certbot para SSL
    sudo apt install -y certbot python3-certbot-nginx
    
    # PostgreSQL
    sudo apt install -y postgresql postgresql-contrib
    
    # Git, curl, etc
    sudo apt install -y git curl htop ufw
    
    log_success "Dependências instaladas"
}

# 3. Configurar firewall
configure_firewall() {
    log_info "Configurando firewall..."
    
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 'Nginx Full'
    sudo ufw --force enable
    
    log_success "Firewall configurado"
}

# 4. Configurar PostgreSQL
setup_postgresql() {
    log_info "Configurando PostgreSQL..."
    
    # Criar usuário e banco
    sudo -u postgres createuser --interactive --pwprompt livebs
    sudo -u postgres createdb -O livebs livebs_production
    
    log_success "PostgreSQL configurado"
}

# 5. Clonar projeto
setup_project() {
    log_info "Configurando projeto..."
    
    # Criar diretório
    sudo mkdir -p $PROJECT_DIR
    sudo chown -R $USER:$USER $PROJECT_DIR
    
    # Clonar se não existir
    if [ ! -d "$PROJECT_DIR/.git" ]; then
        git clone https://github.com/guinugui/LiveBs.git $PROJECT_DIR
    fi
    
    cd $PROJECT_DIR/backend
    
    # Criar ambiente virtual
    python3 -m venv venv
    source venv/bin/activate
    
    # Instalar dependências Python
    pip install -r requirements.txt
    
    log_success "Projeto configurado"
}

# 6. Configurar variáveis de ambiente
setup_environment() {
    log_info "Configurando variáveis de ambiente..."
    
    cd $PROJECT_DIR/backend
    
    # Criar arquivo .env.production
    cat > .env.production << EOF
# Produção - LiveBs Backend
DATABASE_URL=postgresql://livebs:PASSWORD_AQUI@localhost/livebs_production
JWT_SECRET_KEY=$(openssl rand -hex 32)
MERCADOPAGO_ACCESS_TOKEN=SEU_TOKEN_PRODUCAO_AQUI
ENVIRONMENT=production
DEBUG=False
DOMAIN=$DOMAIN
EOF

    log_warning "⚠️  EDITE o arquivo .env.production com suas credenciais reais!"
    log_success "Arquivo de ambiente criado"
}

# 7. Configurar Nginx
setup_nginx() {
    log_info "Configurando Nginx..."
    
    # Remover configuração padrão
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Criar configuração do LiveBs
    sudo tee /etc/nginx/sites-available/livebs << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # SSL Configuration (será configurado pelo Certbot)
    
    # Logs
    access_log /var/log/nginx/livebs_access.log;
    error_log /var/log/nginx/livebs_error.log;
    
    # Proxy para aplicação FastAPI
    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Webhook específico do Mercado Pago
    location /webhook/mercadopago {
        proxy_pass http://127.0.0.1:$PORT/webhook/mercadopago;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Headers específicos para webhooks
        proxy_set_header Content-Type \$content_type;
        proxy_set_header Content-Length \$content_length;
    }
    
    # Gzip
    gzip on;
    gzip_types text/plain application/json application/xml text/css application/javascript;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
EOF

    # Habilitar site
    sudo ln -sf /etc/nginx/sites-available/livebs /etc/nginx/sites-enabled/
    
    # Testar configuração
    sudo nginx -t
    
    # Recarregar Nginx
    sudo systemctl reload nginx
    
    log_success "Nginx configurado"
}

# 8. Configurar SSL com Let's Encrypt
setup_ssl() {
    log_info "Configurando SSL com Let's Encrypt..."
    
    # Obter certificado SSL
    sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email $EMAIL
    
    # Configurar renovação automática
    echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
    
    log_success "SSL configurado"
}

# 9. Criar serviço systemd
setup_systemd() {
    log_info "Configurando serviço systemd..."
    
    sudo tee /etc/systemd/system/livebs.service << EOF
[Unit]
Description=LiveBs FastAPI Backend
After=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$PROJECT_DIR/backend
Environment=PATH=$PROJECT_DIR/backend/venv/bin
EnvironmentFile=$PROJECT_DIR/backend/.env.production
ExecStart=$PROJECT_DIR/backend/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port $PORT --workers 4
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    # Recarregar systemd
    sudo systemctl daemon-reload
    
    # Habilitar e iniciar serviço
    sudo systemctl enable livebs
    sudo systemctl start livebs
    
    log_success "Serviço systemd configurado"
}

# 10. Executar migrações do banco
run_migrations() {
    log_info "Executando migrações do banco..."
    
    cd $PROJECT_DIR/backend
    source venv/bin/activate
    
    # Executar migration de assinatura
    python -c "
import asyncio
import asyncpg
import os
from dotenv import load_dotenv

async def run_migration():
    load_dotenv('.env.production')
    conn = await asyncpg.connect(os.getenv('DATABASE_URL'))
    
    with open('migration_subscription.sql', 'r') as f:
        sql = f.read()
        
    await conn.execute(sql)
    await conn.close()
    print('Migration executada com sucesso!')

asyncio.run(run_migration())
"
    
    log_success "Migrações executadas"
}

# 11. Verificar status
check_status() {
    log_info "Verificando status dos serviços..."
    
    echo "📊 Status dos Serviços:"
    echo "======================="
    
    # Nginx
    if systemctl is-active --quiet nginx; then
        log_success "✅ Nginx: Ativo"
    else
        log_error "❌ Nginx: Inativo"
    fi
    
    # LiveBs
    if systemctl is-active --quiet livebs; then
        log_success "✅ LiveBs: Ativo"
    else
        log_error "❌ LiveBs: Inativo"
    fi
    
    # PostgreSQL
    if systemctl is-active --quiet postgresql; then
        log_success "✅ PostgreSQL: Ativo"
    else
        log_error "❌ PostgreSQL: Inativo"
    fi
    
    # Testar endpoint
    if curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN/ | grep -q "200"; then
        log_success "✅ API: Respondendo"
    else
        log_warning "⚠️  API: Pode não estar respondendo"
    fi
}

# Menu principal
show_menu() {
    echo ""
    echo "Escolha uma opção:"
    echo "1. 🔧 Setup completo (recomendado)"
    echo "2. 📦 Instalar apenas dependências"
    echo "3. 🌐 Configurar apenas Nginx + SSL"
    echo "4. 🚀 Configurar apenas serviço"
    echo "5. 📊 Verificar status"
    echo "6. 🔄 Restart serviços"
    echo "7. 📋 Ver logs"
    echo "0. ❌ Sair"
}

# Função principal
main() {
    # Verificar se está rodando como root
    if [ "$EUID" -eq 0 ]; then 
        log_error "Não execute este script como root!"
        exit 1
    fi
    
    # Verificar variáveis obrigatórias
    if [ "$DOMAIN" = "your-domain.com" ] || [ "$EMAIL" = "admin@your-domain.com" ]; then
        log_warning "⚠️  Configure as variáveis DOMAIN e EMAIL antes de executar!"
        echo "Exemplo:"
        echo "export DOMAIN=api.livebs.com.br"
        echo "export EMAIL=admin@livebs.com.br"
        echo "./setup_production.sh"
        exit 1
    fi
    
    while true; do
        show_menu
        read -p "Digite sua opção: " choice
        
        case $choice in
            1)
                log_info "Iniciando setup completo..."
                update_system
                install_dependencies
                configure_firewall
                setup_postgresql
                setup_project
                setup_environment
                setup_nginx
                setup_ssl
                setup_systemd
                run_migrations
                check_status
                log_success "🎉 Setup completo finalizado!"
                ;;
            2)
                update_system
                install_dependencies
                ;;
            3)
                setup_nginx
                setup_ssl
                ;;
            4)
                setup_systemd
                ;;
            5)
                check_status
                ;;
            6)
                log_info "Reiniciando serviços..."
                sudo systemctl restart nginx
                sudo systemctl restart livebs
                log_success "Serviços reiniciados"
                ;;
            7)
                echo "📋 Logs do LiveBs:"
                sudo journalctl -u livebs -f --lines=20
                ;;
            0)
                log_info "Saindo..."
                exit 0
                ;;
            *)
                log_error "Opção inválida!"
                ;;
        esac
    done
}

# Executar
main