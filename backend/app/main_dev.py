"""
Versão simplificada do main para desenvolvimento SEM Redis
Mantém todas as funcionalidades, mas usa cache em memória
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import auth, profile, chat, meal_plan, logs, workout_plan, personal
from app.config import settings
from app.async_database import async_db
import os

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gerenciar ciclo de vida da aplicação"""
    # Startup
    print("[STARTUP] 🚀 Iniciando LiveBs API (Modo Desenvolvimento)...")
    
    # Conectar ao banco (Redis será MockRedis se não disponível)
    try:
        await async_db.connect()
        print("[STARTUP] ✅ Banco e cache conectados")
    except Exception as e:
        print(f"[STARTUP] ⚠️ Erro na conexão: {e}")
        print("[STARTUP] 🔄 Continuando sem cache...")
    
    yield
    
    # Shutdown
    print("[SHUTDOWN] 🛑 Desconectando...")
    try:
        await async_db.disconnect()
    except:
        pass

app = FastAPI(
    title="LiveBs API - Development",
    description="API do aplicativo de emagrecimento LiveBs - Modo Desenvolvimento",
    version="2.0.0-dev",
    lifespan=lifespan
)

# CORS - configuração para desenvolvimento
allowed_origins = ["*"]  # Permissivo para desenvolvimento
print(f"[CORS] 🔓 Modo desenvolvimento - Origins: {allowed_origins}")

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(auth.router)
app.include_router(profile.router)
app.include_router(chat.router)
app.include_router(meal_plan.router)
app.include_router(workout_plan.router)
app.include_router(personal.router)
app.include_router(logs.router)

@app.get("/")
def root():
    return {
        "app": "LiveBs API - Development Mode",
        "version": "2.0.0-dev",
        "status": "online",
        "mode": "development",
        "features": ["async_db", "mock_cache", "no_redis_required"]
    }

@app.get("/health")
async def health_check():
    """Health check simplificado para desenvolvimento"""
    try:
        # Testar PostgreSQL
        result = await async_db.execute_one("SELECT 1")
        pg_status = "ok" if result else "error"
        
        # Testar Cache (mock ou real)
        try:
            await async_db.cache_set("health_check", "ok", 60)
            cache_test = await async_db.cache_get("health_check")
            cache_status = "ok" if cache_test == "ok" else "error"
        except:
            cache_status = "mock_fallback"
        
    except Exception as e:
        pg_status = f"error: {str(e)}"
        cache_status = "error"
    
    return {
        "status": "healthy",
        "postgresql": pg_status,
        "cache": cache_status,
        "redis_type": "mock" if hasattr(async_db.redis_client, '_data') else "real",
        "workers": os.getenv('WORKERS', '1'),
        "note": "Modo desenvolvimento - Redis não obrigatório"
    }

@app.get("/dev-info")
def dev_info():
    """Informações específicas para desenvolvimento"""
    return {
        "message": "🔧 Modo Desenvolvimento Ativo",
        "redis_status": "mock" if hasattr(async_db.redis_client, '_data') else "real",
        "cache_type": "Em memória (será perdido ao reiniciar)" if hasattr(async_db.redis_client, '_data') else "Redis persistente",
        "performance": "Reduzida (1 worker, cache temporário)",
        "next_steps": [
            "Para produção: instale Redis",
            "Docker: docker run -d -p 6379:6379 redis:alpine",
            "WSL: wsl --install Ubuntu && sudo apt install redis-server",
            "Windows: baixar de https://github.com/tporadowski/redis/releases"
        ]
    }