from openai import OpenAI
from app.config import settings

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
    Gera plano alimentar de 7 dias personalizado
    
    Args:
        user_profile: Dados do perfil do usuário
    
    Returns:
        Dicionário com plano de 7 dias
    """
    prompt = f"""Crie um plano alimentar de 7 dias para:
    
    Perfil:
    - Peso: {user_profile.get('weight')} kg
    - Altura: {user_profile.get('height')} cm
    - Idade: {user_profile.get('age')} anos
    - Meta: {user_profile.get('target_weight')} kg
    - Atividade: {user_profile.get('activity_level')}
    - Calorias/dia: {user_profile.get('daily_calories')} kcal
    """
    
    if user_profile.get('dietary_restrictions'):
        prompt += f"\n- Restrições: {', '.join(user_profile['dietary_restrictions'])}"
    
    if user_profile.get('dietary_preferences'):
        prompt += f"\n- Preferências: {', '.join(user_profile['dietary_preferences'])}"
    
    prompt += """
    
    Retorne um JSON com este formato exato:
    {
        "days": [
            {
                "day": 1,
                "meals": [
                    {
                        "type": "breakfast",
                        "name": "Nome da refeição",
                        "calories": 400,
                        "protein": 20,
                        "carbs": 50,
                        "fat": 10,
                        "recipe": "Ingredientes e modo de preparo"
                    }
                ]
            }
        ]
    }
    
    Inclua 5 refeições por dia: breakfast, morning_snack, lunch, afternoon_snack, dinner.
    """
    
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
        temperature=0.8
    )
    
    import json
    return json.loads(response.choices[0].message.content)
