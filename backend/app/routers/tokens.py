from fastapi import APIRouter, Depends
from app.routers.auth import get_current_user
from app.token_manager import token_manager

router = APIRouter(prefix="/tokens", tags=["Token Management"])

@router.get("/status")
async def get_token_status(current_user = Depends(get_current_user)):
    """Retorna status atual dos tokens do usuário"""
    user_id = current_user['id']
    
    token_status = await token_manager.get_user_tokens_today(user_id)
    
    # Calcular percentage usado
    percentage_used = (token_status['used_tokens'] / token_status['daily_limit']) * 100
    
    # Determinar nível de alerta
    alert_level = "normal"
    if percentage_used >= 95:
        alert_level = "critical"
    elif percentage_used >= 80:
        alert_level = "warning"
    elif percentage_used >= 60:
        alert_level = "info"
    
    # Mensagem personalizada
    if percentage_used == 0:
        status_message = f"✨ Você tem {token_status['daily_limit']:,} tokens disponíveis para hoje!"
    elif percentage_used < 50:
        status_message = f"💚 Você ainda tem {token_status['remaining_tokens']:,} tokens disponíveis"
    elif percentage_used < 80:
        status_message = f"⚡ {token_status['remaining_tokens']:,} tokens restantes - use com moderação"
    elif percentage_used < 95:
        status_message = f"🔥 Atenção! Apenas {token_status['remaining_tokens']:,} tokens restantes"
    else:
        status_message = f"🚫 Limite quase atingido! {token_status['remaining_tokens']:,} tokens restantes"
    
    return {
        "user_id": user_id,
        "tokens_used_today": token_status['used_tokens'],
        "tokens_remaining": token_status['remaining_tokens'],
        "daily_limit": token_status['daily_limit'],
        "percentage_used": round(percentage_used, 1),
        "requests_count": token_status['requests_count'],
        "alert_level": alert_level,
        "status_message": status_message,
        "is_limit_reached": token_status['is_limit_reached'],
        "reset_time": "00:00 (meia-noite)"
    }