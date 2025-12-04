from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import auth, profile, chat, meal_plan, logs, workout_plan, personal, tokens, subscription
from app.config import settings
from app.subscription_middleware import SubscriptionMiddleware

app = FastAPI(
    title="LiveBs API",
    description="API do aplicativo de emagrecimento LiveBs com nutricionista IA",
    version="1.0.0"
)

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

# Adicionar middleware de verificação de assinatura
# app.add_middleware(SubscriptionMiddleware)  # Descomente para ativar verificação

# Routers
app.include_router(auth.router)
app.include_router(profile.router)
app.include_router(chat.router)
app.include_router(meal_plan.router)
app.include_router(workout_plan.router)
app.include_router(personal.router)
app.include_router(logs.router)
app.include_router(tokens.router)
app.include_router(subscription.router)

@app.get("/")
def root():
    return {
        "app": "LiveBs API",
        "version": "1.0.0",
        "status": "online"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}

# Webhook do Mercado Pago agora está no router subscription
