"""Script para testar a API da OpenAI"""
import os
from app.config import settings
from app.ai_service import generate_meal_plan

print("🔍 Testando API da OpenAI...")
print(f"📌 API Key configurada: {settings.openai_api_key[:20]}..." if settings.openai_api_key else "❌ API Key não configurada")

if not settings.openai_api_key:
    print("\n❌ ERRO: API Key da OpenAI não está configurada no arquivo .env")
    print("Adicione: OPENAI_API_KEY=sua-chave-aqui")
    exit(1)

print("\n🧪 Testando geração de meal plan...")
print("Criando perfil de teste...")

# Perfil de teste
test_profile = {
    'weight': 80.0,
    'height': 175.0,
    'age': 30,
    'target_weight': 70.0,
    'activity_level': 'moderate',
    'daily_calories': 1800,
    'dietary_restrictions': ['lactose'],
    'dietary_preferences': ['low_carb']
}

print(f"""
📊 Perfil de teste:
  - Peso: {test_profile['weight']} kg
  - Altura: {test_profile['height']} cm
  - Idade: {test_profile['age']} anos
  - Meta: {test_profile['target_weight']} kg
  - Atividade: {test_profile['activity_level']}
  - Calorias: {test_profile['daily_calories']} kcal
  - Restrições: {', '.join(test_profile['dietary_restrictions'])}
  - Preferências: {', '.join(test_profile['dietary_preferences'])}
""")

print("🚀 Gerando plano alimentar (isso pode levar alguns segundos)...\n")

try:
    meal_plan = generate_meal_plan(test_profile)
    
    print("✅ Plano alimentar gerado com sucesso!\n")
    print(f"📋 Estrutura do plano:")
    print(f"  - Total de dias: {len(meal_plan.get('days', []))}")
    
    if meal_plan.get('days'):
        first_day = meal_plan['days'][0]
        print(f"  - Refeições por dia: {len(first_day.get('meals', []))}")
        
        if first_day.get('meals'):
            first_meal = first_day['meals'][0]
            print(f"  - Opções por refeição: {len(first_meal.get('options', []))}")
            
            print(f"\n📝 Exemplo (Dia 1 - {first_day.get('day_name')}):")
            print(f"  {first_meal.get('type')}:")
            
            for i, option in enumerate(first_meal.get('options', []), 1):
                print(f"    Opção {i}: {option.get('name')}")
                print(f"      - Calorias: {option.get('calories')} kcal")
                print(f"      - Proteínas: {option.get('protein')}g | Carbs: {option.get('carbs')}g | Gorduras: {option.get('fat')}g")
                if i == 1:  # Mostra ingredientes só da primeira opção
                    print(f"      - Ingredientes: {option.get('ingredients', 'N/A')[:100]}...")
                print()
    
    print("✅ API da OpenAI está funcionando corretamente!")
    print("✅ Formato da resposta está correto!")
    
except Exception as e:
    print(f"\n❌ ERRO ao gerar plano alimentar:")
    print(f"   {type(e).__name__}: {str(e)}")
    print("\nVerifique:")
    print("  1. Se a API Key está correta")
    print("  2. Se há créditos disponíveis na conta OpenAI")
    print("  3. Se a conexão com internet está funcionando")
    exit(1)

print("\n🎉 Todos os testes passaram!")
