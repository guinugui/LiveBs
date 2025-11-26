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


    """
    Gera plano alimentar de 7 dias personalizado
    
    Args:
        user_profile: Dados do perfil do usuário
    
    Returns:
        Dicionário com plano de 7 dias
    """
    
    # Monta informações do perfil
    peso_atual = user_profile.get('weight', 0)
    peso_meta = user_profile.get('target_weight', 0)
    diferenca_peso = peso_atual - peso_meta
    altura = user_profile.get('height', 0)
    idade = user_profile.get('age', 0)
    calorias = user_profile.get('daily_calories', 0)
    atividade = user_profile.get('activity_level', '')
    
    # Traduz nível de atividade
    atividade_texto = {
        'sedentary': 'sedentário',
        'light': 'levemente ativo',
        'moderate': 'moderadamente ativo',
        'active': 'muito ativo',
        'very_active': 'extremamente ativo'
    }.get(atividade, atividade)
    
    prompt = f"""Você é Dr. Nutri, um nutricionista especialista em emagrecimento saudável e sustentável.

Crie um plano alimentar completo de 7 dias para o seguinte paciente:

📊 DADOS DO PACIENTE:
• Peso atual: {peso_atual} kg
• Peso meta: {peso_meta} kg
• Objetivo: Perder {diferenca_peso:.1f} kg
• Altura: {altura} cm
• Idade: {idade} anos
• Nível de atividade física: {atividade_texto}
• Meta calórica diária: {calorias} kcal"""
    
    if user_profile.get('dietary_restrictions'):
        restricoes = ', '.join(user_profile['dietary_restrictions'])
        prompt += f"\n• Restrições alimentares: {restricoes}"
    
    if user_profile.get('dietary_preferences'):
        preferencias = ', '.join(user_profile['dietary_preferences'])
        prompt += f"\n• Preferências alimentares: {preferencias}"
    
    prompt += """

🎯 DIRETRIZES PARA O PLANO:
1. Crie um plano de 7 dias (segunda a domingo)
2. Cada dia deve ter 5 refeições: Café da Manhã, Lanche da Manhã, Almoço, Lanche da Tarde, Jantar
3. Para CADA refeição, forneça 2 OPÇÕES diferentes (Opção A e Opção B)
4. Distribua as calorias de forma equilibrada ao longo do dia
5. Priorize alimentos naturais, nutritivos e saudáveis
6. Respeite todas as restrições e preferências alimentares do paciente
7. Varie os alimentos ao longo da semana para evitar monotonia
8. Inclua fontes de proteína de qualidade em todas as refeições principais
9. Equilibre carboidratos complexos e gorduras saudáveis
10. Sugira preparos práticos e viáveis

📋 FORMATO DA RESPOSTA:
Retorne APENAS um JSON válido (sem markdown, sem ```json) com esta estrutura EXATA:

{
  "days": [
    {
      "day": 1,
      "day_name": "Segunda-feira",
      "meals": [
        {
          "type": "Café da Manhã",
          "options": [
            {
              "name": "Opção A - Nome da refeição",
              "calories": 350,
              "protein": 15,
              "carbs": 45,
              "fat": 10,
              "ingredients": "Lista de ingredientes com quantidades",
              "recipe": "Modo de preparo passo a passo"
            },
            {
              "name": "Opção B - Nome da refeição alternativa",
              "calories": 350,
              "protein": 15,
              "carbs": 45,
              "fat": 10,
              "ingredients": "Lista de ingredientes com quantidades",
              "recipe": "Modo de preparo passo a passo"
            }
          ]
        }
      ]
    }
  ]
}

IMPORTANTE: 
- As calorias devem somar aproximadamente {calorias} kcal por dia
- Cada tipo de refeição deve ter EXATAMENTE 2 opções
- Use os tipos de refeição: "Café da Manhã", "Lanche da Manhã", "Almoço", "Lanche da Tarde", "Jantar"
- Seja específico nas quantidades (gramas, unidades, colheres, etc)
- Retorne APENAS o JSON, sem texto adicional antes ou depois
"""
    
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
        temperature=0.8,
        max_tokens=4000
    )
    
    import json
    return json.loads(response.choices[0].message.content)

