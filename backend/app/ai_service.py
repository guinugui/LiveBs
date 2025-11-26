from openai import OpenAI
from app.config import settings
import json

client = OpenAI(api_key=settings.openai_api_key)

def get_ai_response(messages: list[dict], user_profile: dict = None) -> str:
    """
    Obtém resposta do nutricionista IA

    Args:
        messages: Lista de mensagens no formato [{"role": "user", "content": "..."}]
        user_profile: Dados do perfil do usuário (peso, altura, objetivo, etc)

    Returns:
        Resposta do assistente IA
    """
    system_prompt = """Você é Dr. Nutri, um nutricionista virtual especializado em
    emagrecimento saudável. Você é gentil, motivador e baseado em evidências científicas.
    Sempre considere o perfil do usuário ao dar recomendações."""

    if user_profile:
        system_prompt += f"""

        Perfil do usuário:
        - Peso atual: {user_profile.get('weight')} kg
        - Altura: {user_profile.get('height')} cm
        - Idade: {user_profile.get('age')} anos
        - Peso alvo: {user_profile.get('target_weight')} kg
        - Nível de atividade: {user_profile.get('activity_level')}
        - Calorias diárias: {user_profile.get('daily_calories')} kcal
        """

        if user_profile.get('dietary_restrictions'):
            system_prompt += f"\n- Restrições alimentares: {', '.join(user_profile['dietary_restrictions'])}"

        if user_profile.get('dietary_preferences'):
            system_prompt += f"\n- Preferências: {', '.join(user_profile['dietary_preferences'])}"

    all_messages = [{"role": "system", "content": system_prompt}] + messages

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=all_messages,
        temperature=0.7,
        max_tokens=500
    )

    return response.choices[0].message.content


def generate_meal_plan(user_profile: dict) -> dict:
    """
    Gera plano alimentar de 3 dias personalizado
    
    Args:
        user_profile: Dados do usuário incluindo calorias, restrições, preferências
        
    Returns:
        Dicionário com plano de 3 dias
    """
    
    prompt = """COPIE E COMPLETE este JSON exato com 3 dias:

{"days":[{"day":1,"day_name":"Dia 1","meals":[{"type":"breakfast","options":[{"name":"Ovos","calories":300,"protein":25,"carbs":10,"fat":15,"ingredients":"2 ovos 100g batata","recipe":"Cozinhe frite"},{"name":"Tapioca","calories":300,"protein":20,"carbs":35,"fat":8,"ingredients":"tapioca frango","recipe":"Prepare recheie"}]},{"type":"morning_snack","options":[{},{}}]},{"type":"lunch","options":[{},{}]},{"type":"afternoon_snack","options":[{},{}]},{"type":"dinner","options":[{},{}]}]},{"day":2,"day_name":"Dia 2","meals":[{"type":"breakfast","options":[{},{}]},{"type":"morning_snack","options":[{},{}]},{"type":"lunch","options":[{},{}]},{"type":"afternoon_snack","options":[{},{}]},{"type":"dinner","options":[{},{}]}]},{"day":3,"day_name":"Dia 3","meals":[{"type":"breakfast","options":[{},{}]},{"type":"morning_snack","options":[{},{}]},{"type":"lunch","options":[{},{}]},{"type":"afternoon_snack","options":[{},{}]},{"type":"dinner","options":[{},{}]}]}]}

PREENCHA os {} com objetos: name calories protein carbs fat ingredients recipe.
REGRAS: ingredients e recipe MAX 25 chars. Sem virgulas nas strings. 1800 cal total/dia."""
    
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
        temperature=0.7
        # Sem max_tokens - deixa a IA decidir
    )
    
    import json
    import re
    
    # Pega a resposta
    content = response.choices[0].message.content
    
    # Remove possíveis markdown ou texto extra
    content = re.sub(r'^```json\s*', '', content)
    content = re.sub(r'\s*```$', '', content)
    content = content.strip()
    
    # Tenta fazer parse
    try:
        return json.loads(content)
    except json.JSONDecodeError as e:
        # Se falhar, salva para debug
        with open('error_response.txt', 'w', encoding='utf-8') as f:
            f.write(f"ERRO: {e}\n\n")
            f.write(f"POSIÇÃO: linha {e.lineno}, coluna {e.colno}, char {e.pos}\n\n")
            f.write("RESPOSTA:\n")
            f.write(content)
        raise Exception(f"Erro ao parsear JSON da OpenAI. Detalhes salvos em error_response.txt: {e}")
