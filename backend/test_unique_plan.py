#!/usr/bin/env python3
"""
Teste com dados únicos para forçar criação de novo plano
"""
import requests
import json
import time

email = "gui@gmail.com"
password = "123123"

# Login
login_response = requests.post(
    "http://localhost:8001/auth/login",
    json={"email": email, "password": password}
)

if login_response.status_code == 200:
    token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    # Dados únicos para forçar novo plano
    unique_id = int(time.time())
    workout_data = {
        "fitness_level": "intermediario",
        "workout_type": "home",  # CASA
        "days_per_week": 4,  # Mudando para 4 dias
        "session_duration": unique_id % 50 + 30,  # Duração única
        "available_days": ["Segunda", "Terça", "Quinta", "Sexta"],
        "preferred_exercises": [f"flexão_{unique_id}"],  # Exercício único
        "exercises_to_avoid": [],
        "has_musculoskeletal_problems": False,
        "has_respiratory_problems": False,
        "has_cardiac_problems": False,
        "previous_injuries": []
    }
    
    print(f"🏠 Criando plano ÚNICO para CASA")
    print(f"🆔 ID único: {unique_id}")
    print(f"⏱️  Duração: {workout_data['session_duration']} min")
    print(f"📅 Dias: {workout_data['days_per_week']}")
    
    response = requests.post(
        "http://localhost:8001/workout-plan/",
        json=workout_data,
        headers=headers,
        timeout=90
    )
    
    if response.status_code == 201:
        result = response.json()
        print(f"\n✅ NOVO PLANO CRIADO!")
        print(f"📝 Nome: '{result['plan_name']}'")
        print(f"📋 Resumo: '{result['plan_summary']}'")
        print(f"🆔 ID do plano: {result['id']}")
        
        # Verificar dados internos
        if 'workout_data' in result:
            workout_json = json.loads(result['workout_data'])
            print(f"\n🔍 DADOS INTERNOS:")
            print(f"   workout_type: {workout_json.get('workout_type', 'N/A')}")
            print(f"   plan_name: {workout_json.get('plan_name', 'N/A')}")
            print(f"   estrutura: {list(workout_json.keys())}")
        
        # Verificar se nome está correto
        if "Casa" in result['plan_name'] or "casa" in result['plan_name']:
            print(f"✅ SUCESSO: Nome indica treino em casa!")
        elif "Academia" in result['plan_name'] or "academia" in result['plan_name']:
            print(f"❌ ERRO: Nome indica academia mas tipo é casa!")
        else:
            print(f"⚠️  NEUTRO: Nome genérico - {result['plan_name']}")
            
    else:
        print(f"❌ Erro: {response.status_code}")
        print(f"Resposta: {response.text}")
else:
    print(f"❌ Login falhou: {login_response.status_code}")