"""Script para debugar resposta da OpenAI"""
from openai import OpenAI
from app.config import settings

client = OpenAI(api_key=settings.openai_api_key)

print("🔍 Testando resposta da OpenAI em DEBUG mode...\n")

prompt = """Crie um plano alimentar simples de 3 dias apenas para teste.

FORMATO JSON (retorne SOMENTE isto):
{
  "days": [
    {
      "day": 1,
      "day_name": "Segunda",
      "meals": [
        {
          "type": "breakfast",
          "options": [
            {
              "name": "Omelete",
              "calories": 300,
              "protein": 25,
              "carbs": 10,
              "fat": 15,
              "ingredients": "3 ovos, tomate",
              "recipe": "Bata e frite"
            },
            {
              "name": "Tapioca",
              "calories": 310,
              "protein": 20,
              "carbs": 35,
              "fat": 8,
              "ingredients": "50g tapioca, queijo",
              "recipe": "Hidrate e doure"
            }
          ]
        }
      ]
    }
  ]
}

Gere 3 dias completos com 5 refeições cada (breakfast, morning_snack, lunch, afternoon_snack, dinner)."""

print("📤 Enviando requisição para OpenAI...\n")

try:
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
        temperature=0.7,
        max_tokens=16000
    )
    
    content = response.choices[0].message.content
    
    print("✅ Resposta recebida!")
    print(f"📏 Tamanho: {len(content)} caracteres")
    print(f"🔢 Tokens usados: {response.usage.total_tokens}")
    print(f"🔢 Completion tokens: {response.usage.completion_tokens}")
    print(f"📊 Finish reason: {response.choices[0].finish_reason}")
    
    # Salva resposta em arquivo para análise
    with open('debug_response.json', 'w', encoding='utf-8') as f:
        f.write(content)
    print("\n💾 Resposta salva em debug_response.json")
    
    # Mostra os primeiros e últimos caracteres
    print(f"\n📝 Primeiros 200 caracteres:")
    print(content[:200])
    print(f"\n📝 Últimos 200 caracteres:")
    print(content[-200:])
    
    # Tenta fazer parse
    import json
    data = json.loads(content)
    print(f"\n✅ JSON válido! {len(data.get('days', []))} dias gerados")
    
except json.JSONDecodeError as e:
    print(f"\n❌ ERRO JSON: {e}")
    print(f"Posição do erro: linha {e.lineno}, coluna {e.colno}")
    print(f"\nConteúdo ao redor do erro (±100 chars):")
    start = max(0, e.pos - 100)
    end = min(len(content), e.pos + 100)
    print(f"...{content[start:end]}...")
    
    # Salva resposta mesmo com erro
    with open('debug_response_error.txt', 'w', encoding='utf-8') as f:
        f.write(content)
    print("\n💾 Resposta com erro salva em debug_response_error.txt")
    
except Exception as e:
    print(f"\n❌ ERRO: {type(e).__name__}: {e}")
