"""Geração de meal plan - Versão minimalista"""
from openai import OpenAI
from app.config import settings
import json

def gerar_plano_v1():
    """Versão 1: Apenas estrutura básica"""
    client = OpenAI(api_key=settings.openai_api_key)
    
    prompt = 'Retorne JSON exatamente: {"days":[{"day":1,"meals":[]}]}'
    
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
        temperature=0
    )
    
    return json.loads(response.choices[0].message.content)

def gerar_plano_v2():
    """Versão 2: Com 1 refeição"""
    client = OpenAI(api_key=settings.openai_api_key)
    
    prompt = '''Retorne JSON:
{"days":[{"day":1,"meals":[{"type":"breakfast","name":"Ovos","cal":300}]}]}'''
    
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
        temperature=0
    )
    
    return json.loads(response.choices[0].message.content)

def gerar_plano_v3():
    """Versão 3: Gerar 2 opções de café"""
    client = OpenAI(api_key=settings.openai_api_key)
    
    prompt = '''Crie 2 opcoes de cafe da manha. Retorne JSON:
{"opcoes":[{"nome":"Ovos","cal":300},{"nome":"Tapioca","cal":300}]}'''
    
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
        temperature=0.5
    )
    
    return json.loads(response.choices[0].message.content)

def gerar_plano_v4():
    """Versão 4: 1 dia com 2 refeições"""
    client = OpenAI(api_key=settings.openai_api_key)
    
    prompt = '''Gere 1 dia com breakfast e lunch. JSON:
{"day":1,"meals":[{"type":"breakfast","name":"Ovos"},{"type":"lunch","name":"Frango"}]}'''
    
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
        temperature=0.5
    )
    
    return json.loads(response.choices[0].message.content)

def gerar_plano_v5():
    """Versão 5: 1 dia com 5 refeições simples"""
    client = OpenAI(api_key=settings.openai_api_key)
    
    prompt = '''Gere 1 dia de plano alimentar com 5 refeições.
Retorne JSON: {"meals":[
{"type":"breakfast","name":"item1"},
{"type":"morning_snack","name":"item2"},
{"type":"lunch","name":"item3"},
{"type":"afternoon_snack","name":"item4"},
{"type":"dinner","name":"item5"}
]}'''
    
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
        temperature=0.5
    )
    
    return json.loads(response.choices[0].message.content)

def gerar_plano_v6():
    """Versão 6: 1 refeição com 2 opções DETALHADAS"""
    client = OpenAI(api_key=settings.openai_api_key)
    
    prompt = '''Crie 2 opções de café da manhã com TODOS os detalhes.
Cada opção deve ter: nome, calorias, proteínas, carboidratos, gorduras E receita completa.
Retorne JSON com estrutura: {"options":[{...},{...}]}'''
    
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
        temperature=0.7
    )
    
    content = response.choices[0].message.content
    print(f"  Tamanho resposta: {len(content)} chars")
    return json.loads(content)

# Testes
print("🧪 Testando versões incrementais\n")

print("V1: Estrutura básica")
try:
    result = gerar_plano_v1()
    print(f"✅ OK: {result}\n")
except Exception as e:
    print(f"❌ ERRO: {e}\n")
    exit(1)

print("V2: Com 1 refeição")
try:
    result = gerar_plano_v2()
    print(f"✅ OK: {result}\n")
except Exception as e:
    print(f"❌ ERRO: {e}\n")
    exit(1)

print("V3: Gerando conteúdo (2 opções)")
try:
    result = gerar_plano_v3()
    print(f"✅ OK: {result}\n")
except Exception as e:
    print(f"❌ ERRO: {e}\n")
    exit(1)

print("V4: 1 dia, 2 refeições geradas")
try:
    result = gerar_plano_v4()
    print(f"✅ OK: {result}\n")
except Exception as e:
    print(f"❌ ERRO: {e}\n")
    exit(1)

print("V5: 1 dia, 5 refeições simples")
try:
    result = gerar_plano_v5()
    print(f"✅ OK: {result}\n")
except Exception as e:
    print(f"❌ ERRO: {e}\n")
    exit(1)

print("V6: 1 refeição com DETALHES (receita completa)")
try:
    result = gerar_plano_v6()
    print(f"✅ OK\n")
except Exception as e:
    print(f"❌ ERRO: {e}\n")
    exit(1)

print("✅ Todas as versões funcionaram!")
