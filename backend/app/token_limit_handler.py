"""
🚨 TOKEN LIMIT HANDLER - Sistema de controle de tokens
Trata limites diários de tokens de IA e retorna mensagens adequadas para o usuário
"""

from functools import wraps
from app.token_manager import token_manager
from fastapi import HTTPException, status
from typing import Callable, Any
import asyncio

class TokenLimitError(Exception):
    """Exception personalizada para limites de token"""
    def __init__(self, message: str, remaining_tokens: int, daily_limit: int, reset_time: str):
        self.message = message
        self.remaining_tokens = remaining_tokens
        self.daily_limit = daily_limit
        self.reset_time = reset_time
        super().__init__(message)

def estimate_tokens(text: str) -> int:
    """Estima tokens baseado no texto (aproximadamente 4 chars = 1 token)"""
    return len(text) // 4 + 50  # +50 tokens de margem para sistema

async def check_and_consume_tokens(user_id: str, estimated_tokens: int) -> dict:
    """
    Verifica se usuário pode consumir tokens e consome se possível
    Retorna informações sobre o status dos tokens
    """
    # Verificar se pode usar tokens
    can_use, current_status = await token_manager.can_use_tokens(user_id, estimated_tokens)
    
    if not can_use:
        # Preparar mensagem de erro personalizada
        remaining = current_status['remaining_tokens']
        used_today = current_status['used_tokens']
        limit = current_status['daily_limit']
        
        # Diferentes mensagens baseadas na situação
        if remaining == 0:
            error_message = (
                "🚫 **Limite Diário Atingido!**\n\n"
                f"Você já utilizou seus **{limit:,} tokens** disponíveis hoje.\n\n"
                "**O que você pode fazer:**\n"
                "• ✨ Aguarde até amanhã para novos tokens\n"
                "• 📱 Continue navegando no app normalmente\n"
                "• 💡 Use as funcionalidades que não dependem de IA\n\n"
                "**Seus tokens serão renovados automaticamente às 00:00** 🕛"
            )
        else:
            error_message = (
                f"⚠️ **Tokens Insuficientes**\n\n"
                f"Esta operação precisa de ~**{estimated_tokens}** tokens, "
                f"mas você só tem **{remaining}** disponíveis.\n\n"
                f"💡 **Dica:** Use perguntas mais curtas ou aguarde até amanhã!"
            )
        
        raise TokenLimitError(
            message=error_message,
            remaining_tokens=remaining,
            daily_limit=limit,
            reset_time="00:00 (meia-noite)"
        )
    
    # Consumir tokens
    success = await token_manager.consume_tokens(user_id, estimated_tokens)
    
    if success:
        # Retornar status atualizado
        updated_status = await token_manager.get_user_tokens_today(user_id)
        return {
            "success": True,
            "tokens_consumed": estimated_tokens,
            "remaining_tokens": updated_status['remaining_tokens'],
            "total_used_today": updated_status['used_tokens'],
            "is_warning": updated_status['is_warning'],
            "daily_limit": updated_status['daily_limit']
        }
    else:
        raise TokenLimitError(
            message="❌ Erro interno ao processar tokens. Tente novamente!",
            remaining_tokens=current_status['remaining_tokens'],
            daily_limit=current_status['daily_limit'],
            reset_time="00:00"
        )

def create_token_warning_message(token_status: dict) -> str:
    """Cria mensagem de aviso quando tokens estão baixos"""
    remaining = token_status['remaining_tokens']
    limit = token_status['daily_limit']
    percentage_used = (token_status['total_used_today'] / limit) * 100
    
    if percentage_used >= 90:
        return (
            f"🔥 **Atenção:** Você já usou **{percentage_used:.0f}%** dos seus tokens hoje! "
            f"Restam apenas **{remaining:,}** tokens. Use com moderação! 😊"
        )
    elif percentage_used >= 80:
        return (
            f"⚡ **Aviso:** Você já usou **{percentage_used:.0f}%** dos seus tokens hoje. "
            f"Restam **{remaining:,}** tokens para suas próximas perguntas."
        )
    
    return ""

def token_required(estimated_tokens_override: int = None):
    """
    Decorator para endpoints que consomem tokens de IA
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            # Encontrar user_id nos argumentos
            user_id = None
            
            # Procurar current_user nos kwargs
            for key, value in kwargs.items():
                if key == 'current_user' and isinstance(value, dict) and 'id' in value:
                    user_id = value['id']
                    break
            
            if not user_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="User ID não encontrado para verificação de tokens"
                )
            
            # Estimar tokens necessários
            if estimated_tokens_override:
                estimated_tokens = estimated_tokens_override
            else:
                # Tentar estimar baseado nos argumentos
                estimated_tokens = 200  # Valor padrão conservador
                
                # Procurar por conteúdo de texto para estimar
                for arg in args:
                    if hasattr(arg, 'message') and hasattr(arg.message, '__len__'):
                        estimated_tokens = estimate_tokens(str(arg.message))
                        break
                
                for value in kwargs.values():
                    if hasattr(value, 'message') and hasattr(value.message, '__len__'):
                        estimated_tokens = estimate_tokens(str(value.message))
                        break
            
            try:
                # Verificar e consumir tokens
                token_status = await check_and_consume_tokens(user_id, estimated_tokens)
                
                # Executar função original
                result = await func(*args, **kwargs) if asyncio.iscoroutinefunction(func) else func(*args, **kwargs)
                
                # Adicionar aviso se tokens estão baixos
                warning_message = create_token_warning_message(token_status)
                
                # Se o resultado tem uma mensagem de resposta, adicionar aviso
                if warning_message and hasattr(result, 'message'):
                    result.message = f"{result.message}\n\n---\n{warning_message}"
                elif warning_message and isinstance(result, dict) and 'message' in result:
                    result['message'] = f"{result['message']}\n\n---\n{warning_message}"
                
                return result
                
            except TokenLimitError as e:
                # Retornar erro HTTP com detalhes dos tokens
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail={
                        "error": "token_limit_exceeded",
                        "message": e.message,
                        "remaining_tokens": e.remaining_tokens,
                        "daily_limit": e.daily_limit,
                        "reset_time": e.reset_time,
                        "type": "token_limit"
                    }
                )
        
        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            # Para funções síncronas, converter para assíncrono
            return asyncio.run(async_wrapper(*args, **kwargs))
        
        # Retornar wrapper apropriado baseado se a função é async ou não
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper
    
    return decorator

# Função para criar respostas de erro personalizadas
def create_token_limit_response(error_details: dict) -> dict:
    """Cria resposta padronizada para erros de limite de token"""
    return {
        "id": "token_limit_error",
        "role": "system",
        "message": error_details["message"],
        "created_at": "2024-12-01T00:00:00Z",
        "token_info": {
            "remaining": error_details["remaining_tokens"],
            "daily_limit": error_details["daily_limit"],
            "reset_time": error_details["reset_time"]
        },
        "type": "token_limit_error"
    }