#!/bin/bash

# Script para iniciar múltiplas instâncias da LiveBs API para produção
# Execute como: ./start_cluster.sh

echo "🚀 INICIANDO CLUSTER LIVEBS API"

# Definir portas para as instâncias
PORTS=(8000 8001 8002 8003)
AI_SERVICE_PORT=9000

# Função para parar processos existentes
cleanup() {
    echo "🛑 Parando processos existentes..."
    for port in "${PORTS[@]}"; do
        pkill -f "port.*$port" 2>/dev/null || true
    done
    pkill -f "port.*$AI_SERVICE_PORT" 2>/dev/null || true
}

# Função para iniciar uma instância da API
start_api_instance() {
    local port=$1
    echo "🌐 Iniciando API na porta $port..."
    
    API_PORT=$port python start_production.py &
    echo $! > "api_${port}.pid"
    
    # Aguardar a API iniciar
    sleep 3
}

# Função para iniciar microserviço de IA
start_ai_microservice() {
    echo "🧠 Iniciando microserviço de IA na porta $AI_SERVICE_PORT..."
    
    cd microservices
    python -m uvicorn ai_service:app --host 127.0.0.1 --port $AI_SERVICE_PORT &
    echo $! > "../ai_service.pid"
    cd ..
    
    sleep 3
}

# Função para verificar se Redis está rodando
check_redis() {
    echo "🔍 Verificando Redis..."
    if redis-cli ping > /dev/null 2>&1; then
        echo "✅ Redis está rodando"
    else
        echo "❌ Redis não está rodando. Iniciando..."
        # Para Windows: redis-server
        # Para Linux/Mac: sudo systemctl start redis
        redis-server --daemonize yes --port 6379
        sleep 2
    fi
}

# Função para iniciar workers Celery
start_celery_workers() {
    echo "🔄 Iniciando workers Celery..."
    
    # Worker para IA
    celery -A app.celery_config worker --loglevel=info --queues=ai_processing --concurrency=2 &
    echo $! > "celery_ai.pid"
    
    # Worker para meal planning
    celery -A app.celery_config worker --loglevel=info --queues=meal_planning --concurrency=2 &
    echo $! > "celery_meal.pid"
    
    sleep 2
}

# Função para verificar status
check_status() {
    echo "📊 Status do cluster:"
    
    for port in "${PORTS[@]}"; do
        if curl -s "http://127.0.0.1:$port/health" > /dev/null; then
            echo "✅ API porta $port: OK"
        else
            echo "❌ API porta $port: FALHOU"
        fi
    done
    
    if curl -s "http://127.0.0.1:$AI_SERVICE_PORT/health" > /dev/null; then
        echo "✅ AI Service: OK"
    else
        echo "❌ AI Service: FALHOU"
    fi
}

# Função principal
main() {
    # Limpeza
    cleanup
    
    # Verificar dependências
    check_redis
    
    # Iniciar microserviço de IA
    start_ai_microservice
    
    # Iniciar múltiplas instâncias da API
    for port in "${PORTS[@]}"; do
        start_api_instance $port
    done
    
    # Iniciar workers Celery
    start_celery_workers
    
    echo ""
    echo "⏳ Aguardando inicialização completa..."
    sleep 10
    
    # Verificar status
    check_status
    
    echo ""
    echo "🎉 CLUSTER INICIADO COM SUCESSO!"
    echo ""
    echo "📡 Endpoints disponíveis:"
    echo "   - API Principal: http://127.0.0.1:8000-8003"
    echo "   - AI Service: http://127.0.0.1:9000"
    echo "   - Health Check: http://127.0.0.1:8000/health"
    echo "   - Metrics: http://127.0.0.1:8000/metrics"
    echo ""
    echo "🔧 Para parar o cluster: ./stop_cluster.sh"
    echo "📊 Para monitorar: ./monitor_cluster.sh"
    
    # Manter o script rodando
    wait
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi