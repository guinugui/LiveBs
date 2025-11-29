#!/usr/bin/env python3
"""
Script de produção para iniciar LiveBs API com alta performance
Configurado para suportar 1000+ usuários simultâneos
"""

import os
import sys
from pathlib import Path

# Adicionar diretório do projeto ao PYTHONPATH
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

def main():
    """Iniciar servidor com configurações otimizadas"""
    
    # Configurações via environment variables
    workers = int(os.getenv('WORKERS', 4))
    host = os.getenv('API_HOST', '0.0.0.0')
    port = int(os.getenv('API_PORT', 8000))
    worker_class = os.getenv('WORKER_CLASS', 'uvicorn.workers.UvicornWorker')
    worker_connections = int(os.getenv('WORKER_CONNECTIONS', 1000))
    
    print("🚀 INICIANDO LIVEBS API - HIGH PERFORMANCE")
    print(f"📊 Workers: {workers}")
    print(f"🌐 Host: {host}:{port}")
    print(f"⚡ Worker Class: {worker_class}")
    print(f"🔗 Connections per worker: {worker_connections}")
    print("-" * 50)
    
    # Comando gunicorn otimizado
    cmd = [
        "gunicorn",
        "app.main_async:app",
        f"--workers={workers}",
        f"--worker-class={worker_class}",
        f"--worker-connections={worker_connections}",
        f"--bind={host}:{port}",
        "--access-logfile=-",  # Log no stdout
        "--error-logfile=-",   # Errors no stderr
        "--log-level=info",
        "--preload",           # Preload app para melhor performance
        "--max-requests=1000", # Restart worker após N requests
        "--max-requests-jitter=50",
        "--timeout=60",        # Timeout para requests
        "--keep-alive=2",      # Keep-alive connections
    ]
    
    print(f"🔥 Executando: {' '.join(cmd)}")
    os.execvp("gunicorn", cmd)

if __name__ == "__main__":
    main()