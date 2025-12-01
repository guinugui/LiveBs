from datetime import datetime, timedelta
from typing import Optional
import os
from app.async_database import async_db
import json

class TokenManager:
    """Gerenciador de tokens diários para controle de uso da IA"""
    
    def __init__(self):
        self.daily_limit = int(os.getenv('DAILY_TOKEN_LIMIT', 100000))
        self.warning_threshold = int(os.getenv('TOKEN_WARNING_THRESHOLD', 80000))
    
    def _get_today_key(self, user_id: str) -> str:
        """Gera chave para tokens do dia atual"""
        today = datetime.now().strftime('%Y-%m-%d')
        return f"livebs:tokens:{user_id}:{today}"
    
    async def get_user_tokens_today(self, user_id: str) -> dict:
        """Retorna uso de tokens do usuário hoje"""
        key = self._get_today_key(user_id)
        cached = await async_db.cache_get(key)
        
        if cached:
            data = json.loads(cached)
        else:
            data = {
                'used_tokens': 0,
                'requests_count': 0,
                'first_request_time': None,
                'last_request_time': None
            }
        
        return {
            **data,
            'remaining_tokens': max(0, self.daily_limit - data['used_tokens']),
            'is_warning': data['used_tokens'] >= self.warning_threshold,
            'is_limit_reached': data['used_tokens'] >= self.daily_limit,
            'daily_limit': self.daily_limit
        }
    
    async def add_token_usage(self, user_id: str, tokens_used: int, request_type: str = "ai_request") -> dict:
        """Adiciona uso de tokens e retorna status atual"""
        key = self._get_today_key(user_id)
        current_data = await self.get_user_tokens_today(user_id)
        
        # Atualizar dados
        new_data = {
            'used_tokens': current_data['used_tokens'] + tokens_used,
            'requests_count': current_data['requests_count'] + 1,
            'first_request_time': current_data['first_request_time'] or datetime.now().isoformat(),
            'last_request_time': datetime.now().isoformat(),
            'last_request_type': request_type
        }
        
        # Salvar no cache até o final do dia
        end_of_day = datetime.now().replace(hour=23, minute=59, second=59)
        ttl = int((end_of_day - datetime.now()).total_seconds())
        
        await async_db.cache_set(key, json.dumps(new_data, default=str), ttl)
        
        # Retornar status atualizado
        return {
            **new_data,
            'remaining_tokens': max(0, self.daily_limit - new_data['used_tokens']),
            'is_warning': new_data['used_tokens'] >= self.warning_threshold,
            'is_limit_reached': new_data['used_tokens'] >= self.daily_limit,
            'daily_limit': self.daily_limit,
            'tokens_added': tokens_used
        }
    
    async def can_use_tokens(self, user_id: str, tokens_needed: int) -> tuple[bool, dict]:
        """Verifica se usuário pode usar tokens solicitados"""
        current_status = await self.get_user_tokens_today(user_id)
        
        can_use = (current_status['used_tokens'] + tokens_needed) <= self.daily_limit
        
        return can_use, current_status
    
    async def get_admin_token_stats(self) -> dict:
        """Estatísticas gerais de uso de tokens (admin)"""
        # Esta é uma implementação simples - em produção seria melhor usar uma query agregada
        try:
            # Buscar algumas chaves de exemplo para estatísticas básicas
            today = datetime.now().strftime('%Y-%m-%d')
            
            # Em produção, implementar busca mais eficiente
            return {
                'total_users_active_today': 0,  # Implementar contagem real
                'total_tokens_used_today': 0,   # Implementar soma real
                'average_tokens_per_user': 0,   # Implementar cálculo real
                'date': today,
                'daily_limit_per_user': self.daily_limit
            }
        except Exception as e:
            return {'error': str(e)}
    
    # Métodos de compatibilidade para testes
    async def get_available_tokens(self, user_id: str) -> int:
        """Retorna tokens disponíveis para o usuário (compatibilidade)"""
        status = await self.get_user_tokens_today(user_id)
        return status['remaining_tokens']
    
    async def consume_tokens(self, user_id: str, tokens_used: int) -> bool:
        """Consome tokens do usuário (compatibilidade)"""
        can_use, _ = await self.can_use_tokens(user_id, tokens_used)
        
        if can_use:
            await self.add_token_usage(user_id, tokens_used)
            return True
        
        return False

# Instância global - recriar para garantir novos valores
def create_token_manager():
    """Função para criar nova instância com valores atualizados"""
    return TokenManager()

token_manager = create_token_manager()

# Debug: Mostrar configurações atuais
print(f"[TOKEN_MANAGER] 🎯 Limite diário configurado: {token_manager.daily_limit:,} tokens")
print(f"[TOKEN_MANAGER] ⚠️ Aviso em: {token_manager.warning_threshold:,} tokens")