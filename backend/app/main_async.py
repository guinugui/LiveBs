import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from app.routers import auth, profile, chat, meal_plan, logs, workout_plan, personal
from app.config import settings
from app.async_database import async_db
import redis

# Rate limiter
limiter = Limiter(key_func=get_remote_address)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gerenciar ciclo de vida da aplicação"""
    # Startup
    print("[STARTUP] 🚀 Iniciando LiveBs API High Performance...")
    
    # Conectar ao banco e Redis
    await async_db.connect()
    
    yield
    
    # Shutdown
    print("[SHUTDOWN] 🛑 Desconectando...")
    await async_db.disconnect()

app = FastAPI(
    title="LiveBs API - High Performance",
    description="API do aplicativo de emagrecimento LiveBs com nutricionista IA - Otimizada para alta carga",
    version="2.0.0",
    lifespan=lifespan
)

# Rate limiting
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS - configuração segura via .env
allowed_origins = settings.get_allowed_origins()
print(f"[CORS] 🔒 Origins permitidas: {allowed_origins}")

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
        "app": "LiveBs API - High Performance",
        "version": "2.0.0",
        "status": "online",
        "features": ["async_db", "redis_cache", "rate_limiting", "workers"]
    }

@app.get("/health")
async def health_check():
    """Health check com status do banco e cache"""
    try:
        # Testar PostgreSQL
        result = await async_db.execute_one("SELECT 1")
        pg_status = "ok" if result else "error"
        
        # Testar Redis
        cache_test = await async_db.cache_get("health_check")
        await async_db.cache_set("health_check", "ok", 60)
        redis_status = "ok"
        
    except Exception as e:
        pg_status = f"error: {str(e)}"
        redis_status = f"error: {str(e)}"
    
    return {
        "status": "healthy",
        "postgresql": pg_status,
        "redis": redis_status,
        "workers": os.getenv('WORKERS', '1')
    }

@app.get("/metrics")
async def get_metrics():
    """Métricas básicas do sistema"""
    try:
        # Pool info
        pool_info = {
            "size": async_db.pool.get_size() if async_db.pool else 0,
            "min_size": async_db.min_size,
            "max_size": async_db.max_size
        }
        
        # Redis info
        redis_info = await async_db.redis_client.info("memory") if async_db.redis_client else {}
        
        return {
            "database_pool": pool_info,
            "redis_memory_mb": redis_info.get("used_memory", 0) // (1024*1024),
            "cache_ttl": os.getenv('CACHE_TTL', 3600)
        }
    except Exception as e:
        return {"error": str(e)}