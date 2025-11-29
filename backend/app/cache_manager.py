from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import json
import hashlib
from app.async_database import async_db

class CacheManager:
    """Gerenciador de cache Redis para otimizar performance"""
    
    def __init__(self):
        self.default_ttl = 3600  # 1 hora
        
    def _make_key(self, prefix: str, identifier: str) -> str:
        """Cria chave padronizada para cache"""
        return f"livebs:{prefix}:{identifier}"
    
    def _hash_content(self, content: str) -> str:
        """Cria hash do conteúdo para chave de cache"""
        return hashlib.md5(content.encode()).hexdigest()[:12]
    
    async def get_user_profile(self, user_id: str) -> Optional[Dict]:
        """Cache do perfil do usuário"""
        key = self._make_key("profile", user_id)
        cached = await async_db.cache_get(key)
        
        if cached:
            return json.loads(cached)
        return None
    
    async def set_user_profile(self, user_id: str, profile_data: Dict, ttl: int = None):
        """Salvar perfil no cache"""
        key = self._make_key("profile", user_id)
        value = json.dumps(profile_data, default=str)
        await async_db.cache_set(key, value, ttl or self.default_ttl)
    
    async def get_ai_response(self, prompt_hash: str) -> Optional[Dict]:
        """Cache de respostas da IA"""
        key = self._make_key("ai_response", prompt_hash)
        cached = await async_db.cache_get(key)
        
        if cached:
            return json.loads(cached)
        return None
    
    async def set_ai_response(self, prompt: str, response_data: Dict, ttl: int = None):
        """Salvar resposta da IA no cache"""
        prompt_hash = self._hash_content(prompt)
        key = self._make_key("ai_response", prompt_hash)
        value = json.dumps(response_data, default=str)
        
        # Cache de IA tem TTL maior (24h) pois é caro de gerar
        await async_db.cache_set(key, value, ttl or 86400)
        return prompt_hash
    
    async def get_meal_plan(self, user_id: str, plan_type: str = "latest") -> Optional[Dict]:
        """Cache do plano alimentar"""
        key = self._make_key("meal_plan", f"{user_id}:{plan_type}")
        cached = await async_db.cache_get(key)
        
        if cached:
            return json.loads(cached)
        return None
    
    async def set_meal_plan(self, user_id: str, plan_data: Dict, plan_type: str = "latest"):
        """Salvar plano alimentar no cache"""
        key = self._make_key("meal_plan", f"{user_id}:{plan_type}")
        value = json.dumps(plan_data, default=str)
        await async_db.cache_set(key, value, 43200)  # 12 horas
    
    async def get_workout_plan(self, user_id: str, plan_id: str) -> Optional[Dict]:
        """Cache do plano de treino"""
        key = self._make_key("workout", f"{user_id}:{plan_id}")
        cached = await async_db.cache_get(key)
        
        if cached:
            return json.loads(cached)
        return None
    
    async def set_workout_plan(self, user_id: str, plan_id: str, plan_data: Dict):
        """Salvar plano de treino no cache"""
        key = self._make_key("workout", f"{user_id}:{plan_id}")
        value = json.dumps(plan_data, default=str)
        await async_db.cache_set(key, value, 86400)  # 24 horas
    
    async def invalidate_user_cache(self, user_id: str):
        """Invalidar todo cache do usuário"""
        keys_to_delete = [
            self._make_key("profile", user_id),
            self._make_key("meal_plan", f"{user_id}:latest"),
        ]
        
        for key in keys_to_delete:
            await async_db.cache_delete(key)
    
    async def get_stats_cache(self, key: str) -> Optional[Any]:
        """Cache genérico para estatísticas"""
        cache_key = self._make_key("stats", key)
        cached = await async_db.cache_get(cache_key)
        
        if cached:
            return json.loads(cached)
        return None
    
    async def set_stats_cache(self, key: str, data: Any, ttl: int = 300):
        """Salvar estatísticas no cache (TTL curto - 5min)"""
        cache_key = self._make_key("stats", key)
        value = json.dumps(data, default=str)
        await async_db.cache_set(cache_key, value, ttl)

# Instância global
cache_manager = CacheManager()