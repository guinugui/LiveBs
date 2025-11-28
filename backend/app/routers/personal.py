from fastapi import APIRouter, HTTPException, Depends, status
from app.schemas import ChatMessage, ChatResponse
from app.database import db
from app.routers.auth import get_current_user
from app.routers.profile import get_profile
from app.ai_service import get_personal_ai_response
import uuid

router = APIRouter(prefix="/personal", tags=["Personal Trainer"])

@router.post("/chat", response_model=ChatResponse)
def send_personal_message(message: ChatMessage, current_user = Depends(get_current_user)):
    """Envia mensagem para o Personal Trainer Virtual (Coach Atlas)"""
    user_id = current_user['id']
    
    # Busca perfil do usuário
    try:
        profile = get_profile(current_user)
        user_profile = {
            'name': profile.name,
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
    
    # Busca histórico recente (últimas 10 mensagens) para context
    with db.get_db_cursor() as cursor:
        # Verifica quantas mensagens do personal existem
        cursor.execute(
            """SELECT COUNT(*) as message_count FROM personal_messages WHERE user_id = %s""",
            (user_id,)
        )
        count_result = cursor.fetchone()
        # Tentar acessar como dict primeiro, depois como tupla/lista
        if count_result:
            if isinstance(count_result, dict) and 'message_count' in count_result:
                total_messages = count_result['message_count']
            elif isinstance(count_result, (list, tuple)) and len(count_result) > 0:
                total_messages = count_result[0]
            else:
                total_messages = 0
        else:
            total_messages = 0
        
        # Se já temos 11+ mensagens, remove as mais antigas para manter limite de 10
        if total_messages >= 10:
            cursor.execute(
                """DELETE FROM personal_messages 
                   WHERE user_id = %s 
                   AND id IN (
                       SELECT id FROM personal_messages 
                       WHERE user_id = %s 
                       ORDER BY created_at ASC 
                       LIMIT %s
                   )""",
                (user_id, user_id, total_messages - 9)  # Remove para deixar espaço para nova mensagem
            )
        
        # Busca histórico recente (últimas 10 mensagens)
        cursor.execute(
            """SELECT role, message FROM personal_messages 
               WHERE user_id = %s 
               ORDER BY created_at DESC 
               LIMIT 10""",
            (user_id,)
        )
        history = cursor.fetchall()
    
    # Monta lista de mensagens para a IA (ordem cronológica)
    messages = [{"role": msg['role'], "content": msg['message']} for msg in reversed(history)]
    messages.append({"role": "user", "content": message.message})
    
    # Obtém resposta da IA usando prompt do Coach Leo (Personal Trainer)
    print(f"[PERSONAL] 🤖 Enviando para IA: {message.message}")
    ai_response = get_personal_ai_response(messages, user_profile)
    print(f"[PERSONAL] ✅ Resposta da IA: {ai_response[:100]}...")
    
    # Salva mensagem do usuário e resposta da IA
    with db.get_db_cursor() as cursor:
        # Salva mensagem do usuário
        cursor.execute(
            """INSERT INTO personal_messages (user_id, role, message) 
               VALUES (%s, %s, %s)""",
            (user_id, 'user', message.message)
        )
        
        # Salva resposta da IA
        cursor.execute(
            """INSERT INTO personal_messages (user_id, role, message) 
               VALUES (%s, %s, %s)
               RETURNING id, role, message, created_at""",
            (user_id, 'assistant', ai_response)
        )
        response_row = cursor.fetchone()
        
        # Garantir que retornamos um dicionário para o Pydantic
        if isinstance(response_row, dict):
            return response_row
        elif isinstance(response_row, (list, tuple)) and len(response_row) >= 4:
            return {
                "id": response_row[0],
                "role": response_row[1], 
                "message": response_row[2],
                "created_at": response_row[3]
            }
        else:
            # Fallback se algo der errado
            from datetime import datetime
            return {
                "id": str(uuid.uuid4()),
                "role": "assistant",
                "message": ai_response,
                "created_at": datetime.utcnow()
            }


@router.get("/history", response_model=list[ChatResponse])
def get_personal_history(current_user = Depends(get_current_user), limit: int = 50):
    """Retorna histórico de conversas com o Personal Trainer"""
    user_id = current_user['id']
    
    with db.get_db_cursor() as cursor:
        cursor.execute(
            """SELECT id, role, message, created_at 
               FROM personal_messages 
               WHERE user_id = %s 
               ORDER BY created_at DESC 
               LIMIT %s""",
            (user_id, limit)
        )
        messages = cursor.fetchall()
    
    return list(reversed(messages))