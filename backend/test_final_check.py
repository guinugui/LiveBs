#!/usr/bin/env python3
"""
Teste para verificar exatamente o que o roteador está retornando
"""
import requests
import json

# Login
email = "gui@gmail.com"
password = "123123"

login_response = requests.post(
    "http://localhost:8001/auth/login",
    json={"email": email, "password": password}
)

token = login_response.json()["access_token"]
headers = {"Authorization": f"Bearer {token}"}

# Buscar planos existentes primeiro
print("📋 PLANOS EXISTENTES:")
existing_response = requests.get(
    "http://localhost:8001/workout-plan/",
    headers=headers
)

if existing_response.status_code == 200:
    existing_plans = existing_response.json()
    print(f"Total: {len(existing_plans)} planos")
    
    for i, plan in enumerate(existing_plans[:3]):  # Mostrar apenas 3 mais recentes
        workout_json = json.loads(plan['workout_data'])
        print(f"  {i+1}. {plan['plan_name']} (tipo: {workout_json.get('workout_type', 'N/A')})")

print(f"\n🆕 CRIANDO NOVO PLANO...")

# Criar novo plano com dados mínimos para casa
new_plan_data = {
    "fitness_level": "iniciante",  # Mudando nível
    "workout_type": "home",
    "days_per_week": 3,
    "session_duration": 30,
    "available_days": ["Segunda", "Quarta", "Sexta"],
    "preferred_exercises": [],
    "exercises_to_avoid": [],
    "has_musculoskeletal_problems": False,
    "has_respiratory_problems": False,
    "has_cardiac_problems": False,
    "previous_injuries": []
}

print(f"Dados: workout_type={new_plan_data['workout_type']}, level={new_plan_data['fitness_level']}")

# Fazer requisição com timeout menor
try:
    response = requests.post(
        "http://localhost:8001/workout-plan/",
        json=new_plan_data,
        headers=headers,
        timeout=120  # 2 minutos
    )
    
    if response.status_code == 201:
        result = response.json()
        print(f"\n✅ PLANO CRIADO:")
        print(f"📝 Nome: '{result['plan_name']}'")
        print(f"📋 Resumo: '{result['plan_summary']}'")
        
        # Análise do conteúdo
        workout_json = json.loads(result['workout_data'])
        print(f"\n🔍 ANÁLISE:")
        print(f"   Nome no JSON: '{workout_json.get('plan_name', 'N/A')}'")
        print(f"   Tipo no JSON: '{workout_json.get('workout_type', 'N/A')}'")
        print(f"   Resumo no JSON: '{workout_json.get('plan_summary', 'N/A')}'")
        
        # Verificação final
        nome_correto = "casa" in result['plan_name'].lower() or "home" in result['plan_name'].lower()
        tipo_correto = workout_json.get('workout_type') == 'home'
        
        print(f"\n🎯 VERIFICAÇÃO:")
        print(f"   Nome correto: {'✅' if nome_correto else '❌'} ({'Casa/Home encontrado' if nome_correto else 'Casa/Home NÃO encontrado'})")
        print(f"   Tipo correto: {'✅' if tipo_correto else '❌'} ({workout_json.get('workout_type', 'N/A')})")
        
    else:
        print(f"❌ Erro: {response.status_code}")
        print(f"Resposta: {response.text}")
        
except requests.exceptions.Timeout:
    print("⏰ Timeout - Geração demorou mais de 2 minutos")
except Exception as e:
    print(f"❌ Erro: {e}")