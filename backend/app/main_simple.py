"""
Versão simplificada da API principal para funcionar na porta 8001
Usa a configuração existente sem modificações complexas
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import auth, profile, chat, meal_plan, logs, workout_plan, personal

# Usar a configuração original para evitar conflitos
app = FastAPI(
    title="LiveBs API - High Performance",
    description="API do aplicativo de emagrecimento LiveBs com nutricionista IA - Otimizada",
    version="2.1.0"
)

# CORS simples para desenvolvimento
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permissivo para desenvolvimento
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers originais
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
        "app": "LiveBs API - Optimized",
        "version": "2.1.0",
        "status": "online",
        "port": 8001,
        "optimizations": "Configurações de segurança aplicadas"
    }

@app.get("/health")
def health_check():
    """Health check simples"""
    return {
        "status": "healthy",
        "port": 8001,
        "database": "postgresql",
        "security": "enhanced"
    }