#!/usr/bin/env python3
"""
Teste detalhado do JSON retornado
"""
import requests
import json

def detailed_test():
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
        
        # Criar plano
        workout_data = {
            "age": 30,
            "weight": 75,
            "height": 175,
            "activity_level": "MODERADO", 
            "objective": "EMAGRECER",
            "fitness_level": "intermediario",
            "workout_type": "home",
            "days_per_week": 3,
            "session_duration": 45,
            "available_days": ["Segunda", "Quarta", "Sexta"],
            "preferred_exercises": ["flexão", "agachamento"],
            "exercises_to_avoid": [],
            "has_musculoskeletal_problems": False,
            "has_respiratory_problems": False,
            "has_cardiac_problems": False,
            "previous_injuries": []
        }
        
        print("🏠 Criando plano de treino...")
        
        response = requests.post(
            "http://localhost:8001/workout-plan/",
            json=workout_data,
            headers=headers,
            timeout=60
        )
        
        if response.status_code == 201:
            result = response.json()
            print("✅ Plano criado com sucesso!")
            
            # Analisar resultado detalhadamente
            print(f"\n🔍 ANÁLISE DETALHADA:")
            print(f"ID: {result.get('id', 'N/A')}")
            print(f"Nome: {result.get('plan_name', 'N/A')}")
            print(f"Resumo: {result.get('plan_summary', 'N/A')[:100]}...")
            print(f"Criado em: {result.get('created_at', 'N/A')}")
            print(f"User ID: {result.get('user_id', 'N/A')}")
            
            workout_data_raw = result.get('workout_data', '')
            print(f"\n📊 WORKOUT_DATA (tipo: {type(workout_data_raw)}):")
            print(f"Tamanho: {len(str(workout_data_raw))} caracteres")
            print(f"Primeiros 200 chars: {str(workout_data_raw)[:200]}...")
            
            if isinstance(workout_data_raw, str):
                try:
                    workout_json = json.loads(workout_data_raw)
                    print(f"\n✅ JSON válido parseado!")
                    print(f"Chaves disponíveis: {list(workout_json.keys())}")
                    
                    if 'days' in workout_json:
                        days = workout_json['days']
                        print(f"📅 Dias encontrados: {len(days)}")
                        
                        for i, day in enumerate(days):
                            print(f"\n   Dia {i+1}:")
                            print(f"     Day: {day.get('day', 'N/A')}")
                            print(f"     Grupos musculares: {day.get('muscle_groups', [])}")
                            exercises = day.get('exercises', [])
                            print(f"     Exercícios: {len(exercises)}")
                            
                            for j, ex in enumerate(exercises[:2]):
                                print(f"       {j+1}. {ex.get('name', 'N/A')} - {ex.get('sets', 'N/A')}x{ex.get('reps', 'N/A')}")
                    else:
                        print("❌ Chave 'days' não encontrada!")
                        
                except json.JSONDecodeError as e:
                    print(f"❌ Erro ao fazer parse do JSON: {e}")
                    
            elif isinstance(workout_data_raw, dict):
                print(f"\n📊 Já é um dicionário!")
                print(f"Chaves: {list(workout_data_raw.keys())}")
                
            # Testar buscar planos salvos
            print(f"\n📋 Buscando planos salvos...")
            
            saved_response = requests.get(
                "http://localhost:8001/workout-plan/",
                headers=headers
            )
            
            if saved_response.status_code == 200:
                saved_plans = saved_response.json()
                print(f"✅ Encontrados {len(saved_plans)} planos salvos")
                
                if saved_plans:
                    latest_plan = saved_plans[0]
                    print(f"Último plano: {latest_plan.get('plan_name', 'N/A')}")
                    
            else:
                print(f"❌ Erro ao buscar planos: {saved_response.status_code}")
                
        else:
            print(f"❌ Erro: {response.status_code}")
            print(f"Resposta: {response.text}")
            
    else:
        print(f"❌ Erro no login: {login_response.status_code}")

if __name__ == "__main__":
    detailed_test()