"""Teste completo do plano alimentar"""
from openai import OpenAI
from app.config import settings
import json

def gerar_plano_completo():
    """Plano completo: 3 dias, 5 refeições, 2 opções cada"""
    client = OpenAI(api_key=settings.openai_api_key)
    
    prompt = '''Crie um plano alimentar para 3 dias seguindo EXATAMENTE esta estrutura JSON:

{
  "days": [
    {
      "day": 1,
      "meals": [
        {
          "type": "breakfast",
          "options": [
            {"name": "nome específico", "calories": 400, "protein": 25, "carbs": 40, "fat": 12, "recipe": "receita"}
          ]
        },
        {
          "type": "morning_snack",
          "options": [
            {"name": "nome", "calories": 150, "protein": 10, "carbs": 15, "fat": 5, "recipe": "receita"}
          ]
        },
        {
          "type": "lunch",
          "options": [
            {"name": "nome", "calories": 500, "protein": 40, "carbs": 50, "fat": 15, "recipe": "receita"}
          ]
        },
        {
          "type": "afternoon_snack",
          "options": [
            {"name": "nome", "calories": 150, "protein": 10, "carbs": 15, "fat": 5, "recipe": "receita"}
          ]
        },
        {
          "type": "dinner",
          "options": [
            {"name": "nome", "calories": 450, "protein": 35, "carbs": 40, "fat": 15, "recipe": "receita"}
          ]
        }
      ]
    }
  ]
}

IMPORTANTE:
- Total ~1800 calorias/dia
- Preferência: low_carb
- Restrição: SEM lactose
- Comidas específicas (ex: "150g arroz integral"), NÃO categorias genéricas
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
    print(f"📏 Tamanho da resposta: {len(content)} caracteres")
    
    # Salvar resposta bruta para debug
    with open('resposta_completa.json', 'w', encoding='utf-8') as f:
        f.write(content)
    print("💾 Resposta salva em: resposta_completa.json")
    
    return json.loads(content)

print("🚀 Testando plano alimentar COMPLETO")
print("   (3 dias × 5 refeições × 1 opção = 15 refeições)\n")

try:
    result = gerar_plano_completo()
    
    print("✅ JSON válido gerado!\n")
    print(f"📊 Estrutura:")
    print(f"   - Dias: {len(result.get('days', []))}")
    
    for day in result.get('days', []):
        day_num = day.get('day')
        meals = day.get('meals', [])
        print(f"   - Dia {day_num}: {len(meals)} refeições")
        
        for meal in meals:
            meal_type = meal.get('type')
            options = meal.get('options', [])
            print(f"      • {meal_type}: {len(options)} opções")
    
    print("\n✅ SUCESSO! Plano completo funcionou!")
    
except json.JSONDecodeError as e:
    print(f"❌ ERRO ao fazer parse do JSON:")
    print(f"   {e}")
    print("\n📄 Verifique o arquivo resposta_completa.json")
    
except Exception as e:
    print(f"❌ ERRO: {e}")
