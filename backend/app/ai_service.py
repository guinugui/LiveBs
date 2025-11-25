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
    Gera plano alimentar personalizado usando OpenAI
    
    Args:
        user_profile: Dados do usuário incluindo calorias, restrições, preferências
        
    Returns:
        dict: Plano alimentar com estrutura de dias e refeições
    """
    
    # Extrair dados do perfil
    calories = user_profile.get('daily_calories', 2000)
    restrictions = user_profile.get('dietary_restrictions', [])
    preferences = user_profile.get('dietary_preferences', [])
    
    # Construir informações de restrições
    restriction_text = ""
    if restrictions:
        restriction_text = f"- Restrições: SEM {', '.join(restrictions)}"
    
    preference_text = ""
    if preferences:
        preference_text = f"- Preferência: {', '.join(preferences)}"
    
    prompt = f'''Crie um plano alimentar para 3 dias seguindo EXATAMENTE esta estrutura JSON:

{{
  "days": [
    {{
      "day": 1,
      "meals": [
        {{
          "type": "breakfast",
          "options": [
            {{"name": "nome específico", "calories": 400, "protein": 25, "carbs": 40, "fat": 12, "recipe": "receita"}}
          ]
        }},
        {{
          "type": "morning_snack",
          "options": [
            {{"name": "nome", "calories": 150, "protein": 10, "carbs": 15, "fat": 5, "recipe": "receita"}}
          ]
        }},
        {{
          "type": "lunch",
          "options": [
            {{"name": "nome", "calories": 500, "protein": 40, "carbs": 50, "fat": 15, "recipe": "receita"}}
          ]
        }},
        {{
          "type": "afternoon_snack",
          "options": [
            {{"name": "nome", "calories": 150, "protein": 10, "carbs": 15, "fat": 5, "recipe": "receita"}}
          ]
        }},
        {{
          "type": "dinner",
          "options": [
            {{"name": "nome", "calories": 450, "protein": 35, "carbs": 40, "fat": 15, "recipe": "receita"}}
          ]
        }}
      ]
    }}
  ]
}}

IMPORTANTE:
- Total ~{calories} calorias/dia
{restriction_text}
{preference_text}
- Comidas específicas com quantidades (ex: "150g arroz integral", "2 ovos mexidos"), NÃO categorias genéricas
- Receitas devem ser práticas e detalhadas
- Repita a estrutura para day 2 e day 3 com refeições DIFERENTES

Retorne APENAS o JSON, nada mais.'''
    
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
        temperature=0.7,
        max_tokens=4000
    )
    
    content = response.choices[0].message.content
    
    try:
        meal_plan = json.loads(content)
        return meal_plan
    except json.JSONDecodeError as e:
        # Salvar resposta para debug
        with open('error_response.txt', 'w', encoding='utf-8') as f:
            f.write(content)
        raise Exception(f"Erro ao fazer parse do JSON da OpenAI: {e}")
