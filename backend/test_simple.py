"""Teste básico da OpenAI API"""
from openai import OpenAI
from app.config import settings

client = OpenAI(api_key=settings.openai_api_key)

print("🔍 Teste básico da OpenAI API\n")

# Teste 1: Resposta simples de texto
print("📝 Teste 1: Resposta de texto simples")
response = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role": "user", "content": "Diga apenas: Oi tudo bem"}],
    temperature=0.7
)
print(f"Resposta: {response.choices[0].message.content}\n")

# Teste 2: JSON simples
print("📝 Teste 2: JSON simples")
response = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role": "user", "content": 'Retorne apenas este JSON: {"status": "ok", "message": "funcionando"}'}],
    response_format={"type": "json_object"},
    temperature=0.7
)
print(f"Resposta: {response.choices[0].message.content}\n")

# Teste 3: JSON um pouco mais complexo
print("📝 Teste 3: JSON com array")
response = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role": "user", "content": 'Retorne JSON com 2 dias: {"days": [{"day": 1, "name": "Segunda"}, {"day": 2, "name": "Terca"}]}'}],
    response_format={"type": "json_object"},
    temperature=0.7
)
content = response.choices[0].message.content
print(f"Resposta: {content}")

import json
data = json.loads(content)
print(f"✅ JSON válido! {len(data.get('days', []))} dias\n")

print("✅ Todos os testes passaram! A API está funcionando corretamente.")
