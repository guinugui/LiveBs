"""
Microserviço dedicado para IA - separado da API principal
Responsável apenas por processamento de IA (OpenAI)
"""

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
import openai
import os
from dotenv import load_dotenv
from pydantic import BaseModel
from typing import Optional, List
import json
import redis
from datetime import datetime

load_dotenv()

# Configuração OpenAI
openai.api_key = os.getenv('OPENAI_API_KEY')

app = FastAPI(
    title="LiveBs AI Microservice",
    description="Microserviço dedicado para processamento de IA",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://127.0.0.1:8000", "http://localhost:8000"],  # Apenas API principal
    allow_credentials=True,
    allow_methods=["POST"],
    allow_headers=["*"],
)

# Redis para cache
redis_client = redis.Redis(
    host=os.getenv('REDIS_HOST', '127.0.0.1'),
    port=int(os.getenv('REDIS_PORT', 6379)),
    db=2,  # DB diferente da API principal
    decode_responses=True
)

class ChatRequest(BaseModel):
    message: str
    user_context: Optional[dict] = None
    max_tokens: Optional[int] = 1000

class MealPlanRequest(BaseModel):
    user_profile: dict
    dietary_restrictions: Optional[List[str]] = []
    
class WorkoutRequest(BaseModel):
    prompt: str
    user_profile: Optional[dict] = None

class AIResponse(BaseModel):
    response: str
    tokens_used: int
    cached: bool = False
    generated_at: str

def get_cache_key(request_type: str, content: str) -> str:
    """Gera chave de cache baseada no conteúdo"""
    import hashlib
    content_hash = hashlib.md5(content.encode()).hexdigest()[:12]
    return f"ai_cache:{request_type}:{content_hash}"

@app.post("/chat", response_model=AIResponse)
async def process_chat(request: ChatRequest):
    """Processar mensagem de chat com IA"""
    
    # Verificar cache
    cache_key = get_cache_key("chat", request.message)
    cached_response = redis_client.get(cache_key)
    
    if cached_response:
        data = json.loads(cached_response)
        return AIResponse(**data, cached=True)
    
    try:
        # Prompt otimizado para nutricionista
        system_prompt = """Você é uma nutricionista especializada em emagrecimento saudável. 
        Responda de forma clara, prática e motivacional. 
        Se não souber algo específico, seja honesta e sugira consultar um profissional."""
        
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": request.message}
            ],
            max_tokens=request.max_tokens,
            temperature=0.7
        )
        
        ai_response = response.choices[0].message.content
        tokens_used = response.usage.total_tokens
        
        # Salvar no cache (1 hora)
        result = {
            "response": ai_response,
            "tokens_used": tokens_used,
            "generated_at": datetime.now().isoformat()
        }
        
        redis_client.setex(cache_key, 3600, json.dumps(result))
        
        return AIResponse(**result)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro na IA: {str(e)}")

@app.post("/meal-plan", response_model=AIResponse)
async def generate_meal_plan(request: MealPlanRequest):
    """Gerar plano alimentar personalizado"""
    
    # Cache baseado no perfil do usuário
    cache_content = json.dumps(request.user_profile, sort_keys=True)
    cache_key = get_cache_key("meal_plan", cache_content)
    cached_response = redis_client.get(cache_key)
    
    if cached_response:
        data = json.loads(cached_response)
        return AIResponse(**data, cached=True)
    
    try:
        # Prompt detalhado para plano alimentar
        prompt = f"""
        Crie um plano alimentar semanal personalizado baseado nos dados:
        
        Perfil: {request.user_profile}
        Restrições: {request.dietary_restrictions}
        
        Formato: JSON com 7 dias, cada dia com café da manhã, almoço, lanche e jantar.
        Inclua calorias aproximadas por refeição e dicas nutricionais.
        """
        
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "Você é uma nutricionista expert. Crie planos alimentares detalhados e saudáveis."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=2000,
            temperature=0.5
        )
        
        ai_response = response.choices[0].message.content
        tokens_used = response.usage.total_tokens
        
        # Cache por 12 horas (planos mudam menos)
        result = {
            "response": ai_response,
            "tokens_used": tokens_used,
            "generated_at": datetime.now().isoformat()
        }
        
        redis_client.setex(cache_key, 43200, json.dumps(result))
        
        return AIResponse(**result)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao gerar plano: {str(e)}")

@app.post("/workout", response_model=AIResponse)
async def generate_workout(request: WorkoutRequest):
    """Gerar plano de treino"""
    
    cache_key = get_cache_key("workout", request.prompt)
    cached_response = redis_client.get(cache_key)
    
    if cached_response:
        data = json.loads(cached_response)
        return AIResponse(**data, cached=True)
    
    try:
        system_prompt = """Você é um personal trainer expert. 
        Crie treinos seguros, progressivos e adaptados ao nível do usuário.
        Inclua aquecimento, exercícios principais e alongamento."""
        
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": request.prompt}
            ],
            max_tokens=1500,
            temperature=0.6
        )
        
        ai_response = response.choices[0].message.content
        tokens_used = response.usage.total_tokens
        
        # Cache por 24 horas
        result = {
            "response": ai_response,
            "tokens_used": tokens_used,
            "generated_at": datetime.now().isoformat()
        }
        
        redis_client.setex(cache_key, 86400, json.dumps(result))
        
        return AIResponse(**result)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao gerar treino: {str(e)}")

@app.get("/health")
def health_check():
    """Health check do microserviço"""
    try:
        # Testar Redis
        redis_client.ping()
        redis_status = "ok"
    except:
        redis_status = "error"
    
    return {
        "service": "ai_microservice",
        "status": "healthy",
        "redis": redis_status,
        "openai_configured": bool(os.getenv('OPENAI_API_KEY'))
    }

@app.get("/cache/stats")
def cache_stats():
    """Estatísticas do cache"""
    try:
        info = redis_client.info("memory")
        return {
            "cache_size_mb": info.get("used_memory", 0) // (1024*1024),
            "cache_keys": redis_client.dbsize()
        }
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=9000)