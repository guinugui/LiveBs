import asyncio
from typing import Optional, Dict, Any
import json
import hashlib
from datetime import datetime, timedelta

class MockRedis:
    """Redis falso em memória para desenvolvimento sem Redis instalado"""
    
    def __init__(self):
        self._data = {}
        self._expires = {}
        print("[MOCK_REDIS] 🔧 Usando Redis simulado em memória")
    
    def _is_expired(self, key: str) -> bool:
        """Verifica se chave expirou"""
        if key in self._expires:
            return datetime.now() > self._expires[key]
        return False
    
    def _cleanup_expired(self, key: str):
        """Remove chave expirada"""
        if self._is_expired(key):
            self._data.pop(key, None)
            self._expires.pop(key, None)
    
    def get(self, key: str) -> Optional[str]:
        """Buscar valor"""
        self._cleanup_expired(key)
        return self._data.get(key)
    
    def setex(self, key: str, ttl: int, value: str):
        """Definir valor com TTL"""
        self._data[key] = value
        self._expires[key] = datetime.now() + timedelta(seconds=ttl)
    
    def set(self, key: str, value: str):
        """Definir valor sem TTL"""
        self._data[key] = value
        self._expires.pop(key, None)  # Remove TTL se existir
    
    def delete(self, key: str):
        """Deletar chave"""
        self._data.pop(key, None)
        self._expires.pop(key, None)
    
    def ping(self):
        """Health check"""
        return True
    
    def close(self):
        """Fechar conexão"""
        pass
    
    def dbsize(self):
        """Número de chaves"""
        # Limpar expiradas primeiro
        expired_keys = [k for k in self._expires.keys() if self._is_expired(k)]
        for k in expired_keys:
            self._cleanup_expired(k)
        return len(self._data)
    
    def info(self, section: str = None):
        """Informações do Redis"""
        return {
            "used_memory": len(str(self._data)),
            "connected_clients": 1,
            "total_commands_processed": 0
        }

# Cache manager que funciona sem Redis
class CacheManagerNoRedis:
    """Cache manager que funciona sem Redis instalado"""
    
    def __init__(self):
        self.mock_redis = MockRedis()
        self.default_ttl = 3600
        print("[CACHE] 🔧 Usando cache em memória (sem Redis)")
        
    def _make_key(self, prefix: str, identifier: str) -> str:
        """Cria chave padronizada para cache"""
        return f"livebs:{prefix}:{identifier}"
    
    def _hash_content(self, content: str) -> str:
        """Cria hash do conteúdo para chave de cache"""
        return hashlib.md5(content.encode()).hexdigest()[:12]
    
    async def get_user_profile(self, user_id: str) -> Optional[Dict]:
        """Cache do perfil do usuário"""
        key = self._make_key("profile", user_id)
        cached = self.mock_redis.get(key)
        
        if cached:
            return json.loads(cached)
        return None
    
    async def set_user_profile(self, user_id: str, profile_data: Dict, ttl: int = None):
        """Salvar perfil no cache"""
        key = self._make_key("profile", user_id)
        value = json.dumps(profile_data, default=str)
        
        if ttl:
            self.mock_redis.setex(key, ttl, value)
        else:
            self.mock_redis.setex(key, self.default_ttl, value)
    
    async def get_ai_response(self, prompt_hash: str) -> Optional[Dict]:
        """Cache de respostas da IA"""
        key = self._make_key("ai_response", prompt_hash)
        cached = self.mock_redis.get(key)
        
        if cached:
            return json.loads(cached)
        return None
    
    async def set_ai_response(self, prompt: str, response_data: Dict, ttl: int = None):
        """Salvar resposta da IA no cache"""
        prompt_hash = self._hash_content(prompt)
        key = self._make_key("ai_response", prompt_hash)
        value = json.dumps(response_data, default=str)
        
        # Cache de IA tem TTL maior (24h)
        self.mock_redis.setex(key, ttl or 86400, value)
        return prompt_hash
    
    async def invalidate_user_cache(self, user_id: str):
        """Invalidar todo cache do usuário"""
        keys_to_delete = [
            self._make_key("profile", user_id),
            self._make_key("meal_plan", f"{user_id}:latest"),
        ]
        
        for key in keys_to_delete:
            self.mock_redis.delete(key)

# Instância global para desenvolvimento
cache_manager_dev = CacheManagerNoRedis()