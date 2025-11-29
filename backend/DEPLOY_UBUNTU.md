# 🚀 GUIA DE DEPLOY UBUNTU - LIVEBS API

Este guia automatiza completamente o deploy da LiveBs API em um servidor Ubuntu limpo.

## 📋 Pré-requisitos

- Servidor Ubuntu 20.04+ (recomendado: 22.04)
- Usuário com privilégios sudo (NÃO root)
- Mínimo: 2GB RAM, 2 CPU cores, 20GB disco
- Conexão com internet

## 🚀 Deploy Automático (1 comando)

### 1. Clone o repositório
```bash
git clone https://github.com/guinugui/LiveBs.git
cd LiveBs/backend
```

### 2. Execute o deploy automático
```bash
chmod +x deploy_ubuntu.sh
./deploy_ubuntu.sh
```

**⏱️ Tempo estimado: 10-15 minutos**

O script vai automaticamente:
- ✅ Atualizar o sistema
- ✅ Instalar Docker e Docker Compose
- ✅ Configurar PostgreSQL + Redis em containers
- ✅ Criar banco de dados com todas as tabelas
- ✅ Instalar Python e dependências
- ✅ Configurar ambiente virtual
- ✅ Criar arquivo .env de produção
- ✅ Configurar Nginx como load balancer
- ✅ Criar serviços systemd
- ✅ Configurar firewall
- ✅ Iniciar todos os serviços

## 🧪 Teste da Instalação

```bash
chmod +x test_deploy.sh
./test_deploy.sh
```

## 🔑 Configuração Pós-Deploy

### 1. Configure a chave OpenAI
```bash
nano ~/livebs_production/livebs/backend/.env
```
Edite a linha:
```
OPENAI_API_KEY=sk-your-real-openai-key-here
```

### 2. Reinicie os serviços
```bash
sudo systemctl restart livebs-api
sudo systemctl restart livebs-celery
```

## 📊 Endpoints Disponíveis

Após o deploy:
- **API Principal**: `http://SEU_IP:8001`
- **Health Check**: `http://SEU_IP:8001/health`
- **Nginx Proxy**: `http://SEU_IP`
- **Documentação**: `http://SEU_IP:8001/docs`

## 🔧 Gerenciamento de Serviços

### Comandos Systemd
```bash
# Status dos serviços
sudo systemctl status livebs-api
sudo systemctl status livebs-celery

# Reiniciar serviços
sudo systemctl restart livebs-api
sudo systemctl restart livebs-celery

# Ver logs em tempo real
sudo journalctl -u livebs-api -f
sudo journalctl -u livebs-celery -f

# Parar/iniciar
sudo systemctl stop livebs-api
sudo systemctl start livebs-api
```

### Comandos Docker
```bash
# Ver containers
docker ps

# Logs dos containers
docker logs livebs_postgres
docker logs livebs_redis
docker logs livebs_nginx

# Reiniciar containers
cd ~/livebs_production/docker
docker-compose restart

# Parar tudo
docker-compose down

# Iniciar tudo
docker-compose up -d
```

## 📈 Performance e Capacidade

### Configuração Padrão:
- **4 workers Gunicorn**
- **Pool PostgreSQL**: 10-100 conexões
- **Redis cache**: Ativo
- **Rate limiting**: 60 req/min por IP
- **Token limits**: 50k/usuário/dia

### Capacidade Esperada:
- **1000+ usuários simultâneos**
- **~100ms tempo de resposta**
- **99.9% uptime**

## 🔒 Segurança Implementada

- ✅ Firewall UFW configurado
- ✅ Fail2ban ativo contra ataques
- ✅ Headers de segurança no Nginx
- ✅ Credenciais em variáveis de ambiente
- ✅ Rate limiting por IP
- ✅ Conexões PostgreSQL limitadas

## 📁 Estrutura de Arquivos

```
~/livebs_production/
├── docker/
│   ├── docker-compose.yml    # Containers PostgreSQL + Redis + Nginx
│   ├── init.sql              # Script de inicialização do banco
│   └── nginx.conf            # Configuração do load balancer
├── livebs/                   # Código clonado do GitHub
│   └── backend/
│       ├── .env              # Configurações de produção
│       ├── venv/             # Ambiente virtual Python
│       └── ...
└── credentials.txt           # Senhas geradas (manter seguro!)
```

## 🆘 Troubleshooting

### Problema: API não inicia
```bash
# Ver logs detalhados
sudo journalctl -u livebs-api -n 50

# Verificar se o banco está acessível
docker exec -it livebs_postgres psql -U livebs_user -d livebs_db -c "SELECT 1;"

# Testar conexão Python
cd ~/livebs_production/livebs/backend
source venv/bin/activate
python -c "from app.database import db; print('OK')"
```

### Problema: Containers não iniciam
```bash
# Ver logs do Docker Compose
cd ~/livebs_production/docker
docker-compose logs

# Reiniciar containers
docker-compose down
docker-compose up -d
```

### Problema: Nginx não acessa API
```bash
# Verificar se API está rodando localmente
curl http://localhost:8001/health

# Ver logs do Nginx
docker logs livebs_nginx

# Testar configuração
docker exec -it livebs_nginx nginx -t
```

## 📞 Suporte

Se encontrar problemas:

1. Execute `./test_deploy.sh` para diagnóstico
2. Verifique logs com `sudo journalctl -u livebs-api -n 50`
3. Teste containers com `docker ps`

## 🔄 Atualizações

Para atualizar o código:
```bash
cd ~/livebs_production/livebs
git pull
sudo systemctl restart livebs-api
sudo systemctl restart livebs-celery
```

---

**🎉 Com este deploy, sua LiveBs API estará pronta para produção!**