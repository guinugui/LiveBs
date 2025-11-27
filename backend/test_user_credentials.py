#!/usr/bin/env python3
"""
Teste completo com usuário real
"""
import requests
import json

def test_with_credentials():
    print("🔐 TESTE COM CREDENCIAIS FORNECIDAS")
    print("="*50)
    
    # Credenciais fornecidas
    email = "gui@gmail.com"
    password = "123123"
    
    print(f"📧 Email: {email}")
    print(f"🔑 Password: {'*' * len(password)}")
    
    # Tentar fazer login
    print("\n🔐 Tentando fazer login...")
    
    login_response = requests.post(
        "http://localhost:8001/auth/login",
        json={"email": email, "password": password}
    )
    
    if login_response.status_code == 200:
        token_data = login_response.json()
        token = token_data["access_token"]
        print("✅ Login realizado com sucesso!")
        
        # Testar criação de plano de treino
        headers = {"Authorization": f"Bearer {token}"}
        
        workout_data = {
            "age": 30,
            "weight": 75,
            "height": 175,
            "activity_level": "MODERADO",
            "objective": "EMAGRECER",
            "fitness_level": "intermediario",
            "workout_type": "home",  # TREINO EM CASA
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
        
        print(f"\n🏠 Criando plano de treino em casa...")
        
        workout_response = requests.post(
            "http://localhost:8001/workout-plan/",
            json=workout_data,
            headers=headers,
            timeout=60
        )
        
        if workout_response.status_code == 201:
            result = workout_response.json()
            print("✅ Plano de treino criado com sucesso!")
            print(f"📝 Nome do plano: {result.get('plan_name', 'N/A')}")
            print(f"📋 Resumo: {result.get('plan_summary', 'N/A')[:100]}...")
            
            # Verificar workout_data
            workout_str = result.get('workout_data', '')
            if isinstance(workout_str, str):
                try:
                    workout_json = json.loads(workout_str)
                    days = workout_json.get('days', [])
                    print(f"📅 Dias de treino: {len(days)}")
                    
                    if days:
                        first_day = days[0]
                        exercises = first_day.get('exercises', [])
                        print(f"💪 Exercícios do primeiro dia:")
                        for i, ex in enumerate(exercises[:3]):
                            print(f"   {i+1}. {ex.get('name', 'N/A')}")
                    
                except json.JSONDecodeError as e:
                    print(f"❌ Erro ao decodificar JSON: {e}")
                    
            return True
            
        else:
            print(f"❌ Erro na criação do treino: {workout_response.status_code}")
            print(f"Resposta: {workout_response.text}")
            return False
            
    else:
        print(f"❌ Erro no login: {login_response.status_code}")
        print(f"Resposta: {login_response.text}")
        
        # Tentar criar usuário
        print("\n👤 Tentando criar usuário...")
        
        register_data = {
            "email": email,
            "password": password,
            "name": "Gui Teste"
        }
        
        register_response = requests.post(
            "http://localhost:8001/auth/register",
            json=register_data
        )
        
        if register_response.status_code == 201:
            print("✅ Usuário criado com sucesso!")
            print("🔄 Tentando login novamente...")
            
            # Tentar login novamente
            login_response2 = requests.post(
                "http://localhost:8001/auth/login",
                json={"email": email, "password": password}
            )
            
            if login_response2.status_code == 200:
                print("✅ Login após registro realizado com sucesso!")
                return True
            else:
                print(f"❌ Erro no login após registro: {login_response2.status_code}")
                
        else:
            print(f"❌ Erro ao criar usuário: {register_response.status_code}")
            print(f"Resposta: {register_response.text}")
            
        return False

if __name__ == "__main__":
    test_with_credentials()