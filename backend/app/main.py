from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import auth, profile, chat, meal_plan, logs

app = FastAPI(
    title="LiveBs API",
    description="API do aplicativo de emagrecimento LiveBs com nutricionista IA",
    version="1.0.0"
)

# CORS - permite requisições do Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Em produção, especificar domínios
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(auth.router)
app.include_router(profile.router)
app.include_router(chat.router)
app.include_router(meal_plan.router)
app.include_router(logs.router)

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
