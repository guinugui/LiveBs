#!/usr/bin/env python3
"""
Teste simples para verificar nome e tipo de treino
"""
import requests
import json

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
    
    # Dados para treino em CASA (variando para forçar novo plano)
    import random
    workout_data = {
        "fitness_level": "intermediario",
        "workout_type": "home",  # CASA
        "days_per_week": random.choice([3, 4]),  # Variar para forçar novo plano
        "session_duration": random.choice([45, 50]),
        "available_days": ["Segunda", "Quarta", "Sexta"],
        "preferred_exercises": ["flexão", "agachamento"],
        "exercises_to_avoid": [],
        "has_musculoskeletal_problems": False,
        "has_respiratory_problems": False, 
        "has_cardiac_problems": False,
        "previous_injuries": []
    }
    
    print(f"🏠 Criando plano CASA (workout_type: {workout_data['workout_type']})")
    
    response = requests.post(
        "http://localhost:8001/workout-plan/",
        json=workout_data,
        headers=headers,
        timeout=60
    )
    
    if response.status_code == 201:
        result = response.json()
        print(f"✅ SUCESSO!")
        print(f"📝 Nome: {result['plan_name']}")
        print(f"📋 Resumo: {result['plan_summary']}")
        
        # Verificar JSON interno
        if 'workout_data' in result:
            workout_json = json.loads(result['workout_data'])
            print(f"🔍 Tipo no JSON: {workout_json.get('workout_type', 'N/A')}")
            print(f"🗂️ Estrutura: {list(workout_json.keys())}")
            
            # Verificar exercícios se existir 'days'
            if 'days' in workout_json:
                days = workout_json['days']
                print(f"📅 Estrutura DAYS encontrada! {len(days)} dias")
                if days:
                    exercises = days[0].get('exercises', [])
                    if exercises:
                        print(f"💪 Primeiro exercício: {exercises[0].get('name', 'N/A')}")
            elif 'workout_schedule' in workout_json:
                print(f"📅 Estrutura WORKOUT_SCHEDULE (legado) encontrada!")
    else:
        print(f"❌ Erro: {response.status_code} - {response.text}")
else:
    print(f"❌ Login falhou: {login_response.status_code}")