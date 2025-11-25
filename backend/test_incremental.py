"""Teste incremental para descobrir o problema"""
from openai import OpenAI
from app.config import settings
import json

client = OpenAI(api_key=settings.openai_api_key)

print("🔍 Teste incremental da geração de meal plan\n")

# Teste 1: 1 dia, 1 refeição, 1 opção
print("📝 Teste 1: 1 dia, 1 refeição, 1 opção")
try:
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": 'Retorne JSON: {"days":[{"day":1,"meals":[{"type":"breakfast","options":[{"name":"Ovos","calories":300,"protein":25,"carbs":10,"fat":15,"ingredients":"2 ovos","recipe":"Frite"}]}]}]}'}],
        response_format={"type": "json_object"},
        temperature=0.7
    )
    data = json.loads(response.choices[0].message.content)
    print(f"✅ OK! {len(data['days'])} dia\n")
except Exception as e:
    print(f"❌ ERRO: {e}\n")
    exit(1)

# Teste 2: 1 dia, 1 refeição, 2 opções
print("📝 Teste 2: 1 dia, 1 refeição, 2 opções")
try:
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": 'Retorne JSON com 2 opcoes: {"days":[{"day":1,"meals":[{"type":"breakfast","options":[{"name":"Ovos","calories":300,"protein":25,"carbs":10,"fat":15,"ingredients":"2 ovos","recipe":"Frite"},{"name":"Tapioca","calories":300,"protein":20,"carbs":35,"fat":8,"ingredients":"tapioca","recipe":"Hidrate"}]}]}]}'}],
        response_format={"type": "json_object"},
        temperature=0.7
    )
    data = json.loads(response.choices[0].message.content)
    print(f"✅ OK! {len(data['days'][0]['meals'][0]['options'])} opções\n")
except Exception as e:
    print(f"❌ ERRO: {e}\n")
    exit(1)

# Teste 3: 1 dia, 2 refeições, 2 opções cada
print("📝 Teste 3: 1 dia, 2 refeições")
try:
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": 'Gere JSON de 1 dia com breakfast e lunch. 2 opcoes cada. Formato: {"days":[{"day":1,"meals":[{"type":"breakfast","options":[{obj},{obj}]},{"type":"lunch","options":[{obj},{obj}]}]}]}. Objeto tem: name calories protein carbs fat ingredients recipe'}],
        response_format={"type": "json_object"},
        temperature=0.7
    )
    data = json.loads(response.choices[0].message.content)
    print(f"✅ OK! {len(data['days'][0]['meals'])} refeições\n")
except Exception as e:
    print(f"❌ ERRO: {e}\n")
    exit(1)

# Teste 4: 1 dia, 5 refeições, 2 opções cada
print("📝 Teste 4: 1 dia, 5 refeições")
try:
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": 'Gere 1 dia com 5 refeicoes breakfast morning_snack lunch afternoon_snack dinner. 2 opcoes cada. JSON compacto. Ingredients e recipe curtos (max 20 chars)'}],
        response_format={"type": "json_object"},
        temperature=0.7
    )
    content = response.choices[0].message.content
    print(f"Tamanho resposta: {len(content)} chars")
    data = json.loads(content)
    print(f"✅ OK! {len(data['days'][0]['meals'])} refeições\n")
except Exception as e:
    print(f"❌ ERRO: {e}")
    print(f"Resposta: {content[:500]}...\n")
    exit(1)

# Teste 5: 3 dias, 5 refeições, 2 opções cada
print("📝 Teste 5: 3 dias completos")
try:
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": 'Gere 3 dias. Cada dia 5 refeicoes breakfast morning_snack lunch afternoon_snack dinner. Cada refeicao 2 opcoes. JSON compacto. Ingredients e recipe BEM curtos max 15 chars'}],
        response_format={"type": "json_object"},
        temperature=0.7
    )
    content = response.choices[0].message.content
    print(f"Tamanho resposta: {len(content)} chars")
    data = json.loads(content)
    print(f"✅ OK! {len(data['days'])} dias gerados!\n")
    
    # Mostra exemplo
    first_meal = data['days'][0]['meals'][0]
    print(f"Exemplo: {first_meal['options'][0]['name']}")
    print(f"Ingredients: {first_meal['options'][0]['ingredients']}")
    print(f"Recipe: {first_meal['options'][0]['recipe']}")
    
except Exception as e:
    print(f"❌ ERRO: {e}")
    if 'content' in locals():
        with open('error_full.txt', 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Resposta salva em error_full.txt")
    exit(1)

print("\n✅ TODOS OS TESTES PASSARAM!")
