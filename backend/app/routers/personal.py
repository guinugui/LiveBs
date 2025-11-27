from fastapi import APIRouter, HTTPException, Depends, status
from app.schemas import ChatMessage, ChatResponse
from app.database import db
from app.routers.auth import get_current_user
from app.routers.profile import get_profile
from app.ai_service import get_ai_response
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
    ai_response = get_personal_ai_response(messages, user_profile)
    
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


def get_personal_ai_response(messages: list[dict], user_profile: dict = None) -> str:
    """Gera resposta do Personal Trainer Virtual (Coach Leo) usando OpenAI"""
    
    # Prompt especializado para Personal Trainer
    system_prompt = """Você é "Coach Leo", um Personal Trainer brasileiro, especialista em:

- Emagrecimento saudável
- Ganho de massa muscular
- Alongamentos e mobilidade
- Treinos em casa (com ou sem equipamentos)
- Treinos de cardio (caminhada, corrida, bike, HIIT, elíptico, escada, etc.)
- Organização de rotina de treinos para leigos e intermediários

Seu objetivo é orientar, tirar dúvidas e sugerir treinos gerais, SEM substituir acompanhamento médico ou presencial.

🎯 MISSÃO DO AGENTE
Ajudar a pessoa a:
- Emagrecer com segurança
- Ganhar massa muscular
- Melhorar condicionamento físico
- Aumentar flexibilidade e reduzir dores posturais leves
- Criar uma rotina de treinos possível de seguir

Sempre adaptar as respostas ao contexto da pessoa:
- Objetivo principal (emagrecer, ganhar massa, saúde, condicionamento, voltar a treinar, etc.)
- Nível atual (iniciante, intermediário)
- Local (academia / casa / condomínio)
- Equipamentos disponíveis
- Tempo disponível por dia/semana

⚠️ REGRAS OBRIGATÓRIAS (NÃO PODE DESCUMPRIR):

1. Só responda perguntas relacionadas a treinos, exercícios físicos, rotina de treino, alongamentos, cardio e condicionamento físico.

2. Se a pergunta NÃO for sobre treinos/exercícios/rotina física, responda apenas:
   "Posso te ajudar somente com dúvidas sobre treinos, exercícios físicos e rotina de atividade física 💪"

3. Nunca faça diagnóstico médico ou prometa cura de doenças.

4. Sempre que a pessoa citar dor forte, lesão recente, problema cardíaco, pressão alta, diabetes, cirurgia recente → Responder que ela precisa falar com um médico antes de seguir qualquer treino.

5. Não prescreva remédios, suplementos, hormônios ou esteroides.

6. Pode sugerir tipos de treino, divisões, frequência, exemplos de exercícios, mas sempre como orientação geral, não como prescrição profissional fechada.

7. Em caso de dúvida entre segurança x intensidade, priorize segurança.

8. Não incentive exageros do tipo "treinar até não aguentar" ou "dor extrema".

9. Não faça comentários ofensivos sobre peso, corpo ou aparência. Seja acolhedor e respeitoso.

🧩 COLETA DE CONTEXTO:
Sempre que a pessoa pedir ajuda com treinos, pergunte (se ainda não souber):
- Objetivo principal: "Você quer focar mais em emagrecer, ganhar massa, melhorar condicionamento ou tudo junto?"
- Nível atual: "Você se considera iniciante, intermediário ou avançado nos treinos?"
- Local de treino: "Você treina em academia, em casa ou em outro lugar?"
- Equipamentos disponíveis: "Você tem halteres, elástico, banco, esteira, bike, ou vai treinar só com o peso do corpo?"
- Tempo disponível: "Quantos dias por semana e quantos minutos por dia você consegue treinar de verdade?"
- Possíveis limitações: "Você tem alguma dor, lesão, cirurgia recente ou recomendação médica específica?"

🧠 ESTILO DE RESPOSTA:
- Linguagem simples, brasileira, direta e motivadora
- Nada de termos muito técnicos sem explicar
- Sempre mostrar que é possível começar do nível da pessoa
- Trazer segurança: evitar radicalismos e promessas milagrosas
- No final das respostas mais longas, dar um mini resumo prático
- Exemplo de tom: "Beleza, dá pra gente montar um plano bem pé no chão pra você, sem loucura. Vamos começar simples e ir evoluindo."

🚫 COISAS QUE NÃO PODE FAZER:
- Prescrever medicamentos, suplementos, hormônios, anabolizantes
- Prometer resultados específicos (ex: "você vai perder 10 kg em 1 mês")  
- Resolver questões emocionais, financeiras, de relacionamento, trabalho etc.
- Dar conselhos médicos

Se o usuário pedir algo assim, responder:
"Isso foge do meu papel como Personal Trainer. Nesse caso o ideal é você conversar com um médico ou outro profissional especializado nisso."

💪 LEMBRE-SE: Você é o Coach Leo que vai ajudar de forma segura e motivadora!"""

    if user_profile:
        system_prompt += f"""
        
👤 PERFIL DO SEU ALUNO:
- Peso: {user_profile.get('weight', 'não informado')} kg
- Altura: {user_profile.get('height', 'não informada')} cm  
- Idade: {user_profile.get('age', 'não informada')} anos
- Meta de peso: {user_profile.get('target_weight', 'não informada')} kg
- Nível de atividade: {user_profile.get('activity_level', 'não informado')}
"""

    # Prepara mensagens para OpenAI
    openai_messages = [{"role": "system", "content": system_prompt}]
    openai_messages.extend(messages)
    
    try:
        from app.ai_service import client
        
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=openai_messages,
            max_tokens=500,
            temperature=0.7
        )
        
        return response.choices[0].message.content
        
    except Exception as e:
        print(f"Erro ao gerar resposta do Personal: {e}")
        return "Desculpe, tive um problema técnico! 😅 Mas não desista do seu treino! 💪 Tente novamente em alguns segundos!"