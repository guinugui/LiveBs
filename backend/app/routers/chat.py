from fastapi import APIRouter, HTTPException, Depends, status
from app.schemas import ChatMessage, ChatResponse
from app.database import db
from app.routers.auth import get_current_user
from app.routers.profile import get_profile
from app.ai_service import get_ai_response

router = APIRouter(prefix="/chat", tags=["Chat"])

@router.post("", response_model=ChatResponse)
def send_message(message: ChatMessage, current_user = Depends(get_current_user)):
    """Envia mensagem para o nutricionista IA"""
    user_id = current_user['id']
    
    # Busca perfil do usuário
    try:
        profile = get_profile(current_user)
        user_profile = {
            'weight': profile.weight,
            'height': profile.height,
            'age': profile.age,
            'target_weight': profile.target_weight,
            'activity_level': profile.activity_level,
            'daily_calories': profile.daily_calories,
            'dietary_restrictions': profile.dietary_restrictions,
            'dietary_preferences': profile.dietary_preferences
        }
    except:
        user_profile = None
    
    # Busca histórico recente (últimas 10 mensagens)
    with db.get_db_cursor() as cursor:
        cursor.execute(
            """SELECT role, message FROM chat_messages 
               WHERE user_id = %s 
               ORDER BY created_at DESC 
               LIMIT 10""",
            (user_id,)
        )
        history = cursor.fetchall()
    
    # Monta lista de mensagens para a IA (ordem cronológica)
    messages = [{"role": msg['role'], "content": msg['message']} for msg in reversed(history)]
    messages.append({"role": "user", "content": message.message})
    
    # Obtém resposta da IA
    ai_response = get_ai_response(messages, user_profile)
    
    # Salva mensagem do usuário e resposta da IA
    with db.get_db_cursor() as cursor:
        # Salva mensagem do usuário
        cursor.execute(
            """INSERT INTO chat_messages (user_id, role, message) 
               VALUES (%s, %s, %s)""",
            (user_id, 'user', message.message)
        )
        
        # Salva resposta da IA
        cursor.execute(
            """INSERT INTO chat_messages (user_id, role, message) 
               VALUES (%s, %s, %s)
               RETURNING id, role, message, created_at""",
            (user_id, 'assistant', ai_response)
        )
        response = cursor.fetchone()
    
    return response

@router.get("/history", response_model=list[ChatResponse])
def get_chat_history(current_user = Depends(get_current_user), limit: int = 50):
    """Retorna histórico de mensagens"""
    user_id = current_user['id']
    
    with db.get_db_cursor() as cursor:
        cursor.execute(
            """SELECT id, role, message, created_at 
               FROM chat_messages 
               WHERE user_id = %s 
               ORDER BY created_at DESC 
               LIMIT %s""",
            (user_id, limit)
        )
        messages = cursor.fetchall()
    
    return list(reversed(messages))
