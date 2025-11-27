#!/usr/bin/env python3
"""
Teste simplificado para verificar se o tipo de treino está sendo respeitado
"""
import requests
import json

def create_test_user():
    """Cria usuário de teste e faz login"""
    print("👤 Criando usuário de teste...")
    
    # Dados do usuário
    user_data = {
        "email": "teste_treino@test.com",
        "password": "123456",
        "full_name": "Teste Treino"
    }
    
    # Tentar fazer login primeiro
    login_response = requests.post(
        "http://localhost:8001/auth/login",
        data={"username": user_data["email"], "password": user_data["password"]}
    )
    
    if login_response.status_code == 200:
        token_data = login_response.json()
        print("✅ Login realizado com sucesso!")
        return token_data["access_token"]
    
    # Se login falhou, tentar criar usuário
    register_response = requests.post(
        "http://localhost:8001/auth/register",
        json=user_data
    )
    
    if register_response.status_code == 201:
        print("✅ Usuário criado com sucesso!")
        
        # Fazer login
        login_response = requests.post(
            "http://localhost:8001/auth/login",
            data={"username": user_data["email"], "password": user_data["password"]}
        )
        
        if login_response.status_code == 200:
            token_data = login_response.json()
            return token_data["access_token"]
    
    print("❌ Erro ao criar usuário ou fazer login")
    return None

def test_workout_generation():
    # Obter token
    token = create_test_user()
    if not token:
        print("❌ Não foi possível obter token de acesso")
        return
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Dados de teste para treino em casa
    test_data = {
        "age": 30,
        "weight": 75,
        "height": 175,
        "activity_level": "MODERADO",
        "objective": "EMAGRECER",
        "fitness_level": "intermediario",
        "workout_type": "home",  # CASA
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
    
    print(f"\n🏠 TESTANDO TREINO EM CASA")
    print(f"Tipo solicitado: {test_data['workout_type']}")
    
    try:
        response = requests.post(
            "http://localhost:8001/workout-plan/",
            json=test_data,
            headers=headers,
            timeout=60
        )
        
        if response.status_code == 201:
            result = response.json()
            print("✅ Plano de treino criado com sucesso!")
            
            # Verificar se o workout_data está presente
            if 'workout_data' in result:
                workout_str = result['workout_data']
                
                # Se for string, fazer parse
                if isinstance(workout_str, str):
                    try:
                        workout_data = json.loads(workout_str)
                    except:
                        workout_data = workout_str
                else:
                    workout_data = workout_str
                
                print(f"📊 Resumo: {result.get('plan_summary', 'N/A')[:150]}...")
                
                # Verificar exercícios
                if isinstance(workout_data, dict) and 'days' in workout_data:
                    days = workout_data['days']
                    print(f"📅 Encontrados {len(days)} dias de treino")
                    
                    if days:
                        first_day = days[0]
                        exercises = first_day.get('exercises', [])
                        print(f"\n💪 Exercícios do primeiro dia:")
                        
                        gym_equipment = ['supino', 'leg press', 'máquina', 'barra olímpica', 'cabo', 'polia']
                        
                        for i, ex in enumerate(exercises[:4]):
                            name = ex.get('name', '').lower()
                            print(f"   {i+1}. {ex.get('name', 'N/A')}")
                            
                            # Verificar se há equipamento de academia
                            has_gym = any(equip in name for equip in gym_equipment)
                            if has_gym:
                                print(f"      ❌ ERRO: Exercício de academia detectado!")
                            else:
                                print(f"      ✅ OK: Exercício adequado para casa")
                
                return True
                
        else:
            print(f"❌ Erro: {response.status_code}")
            print(f"Resposta: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro na requisição: {e}")
        return False

if __name__ == "__main__":
    print("🏋️  TESTE DE TREINO EM CASA")
    print("="*50)
    test_workout_generation()