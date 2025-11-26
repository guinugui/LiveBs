import requests
import json

# Configurações
BASE_URL = "http://localhost:8000"

def test_workout_api():
    try:
        print("🧪 TESTANDO API DE TREINOS")
        print("=" * 40)
        
        # 1. Fazer login primeiro
        print("1. Fazendo login...")
        login_data = {
            "username": "gui@gmail.com",
            "password": "123123"
        }
        
        login_response = requests.post(
            f"{BASE_URL}/auth/login",
            data=login_data
        )
        
        if login_response.status_code != 200:
            print(f"❌ Erro no login: {login_response.status_code}")
            print(login_response.text)
            return
        
        token = login_response.json()["access_token"]
        print(f"✅ Login realizado: {token[:20]}...")
        
        # Headers com autenticação
        headers = {"Authorization": f"Bearer {token}"}
        
        # 2. Testar criação de plano de treino
        print("\n2. Criando plano de treino...")
        
        workout_data = {
            "healthProblems": ["nenhum"],
            "previousInjuries": [],
            "fitnessLevel": "iniciante",
            "exercisePreferences": ["musculacao"],
            "workoutType": "casa",
            "daysPerWeek": 3,
            "availableTimes": ["manha"]
        }
        
        create_response = requests.post(
            f"{BASE_URL}/workout-plan/",
            json=workout_data,
            headers=headers
        )
        
        print(f"Status: {create_response.status_code}")
        if create_response.status_code == 201:
            plan = create_response.json()
            print(f"✅ Plano criado: {plan['plan_name']}")
            plan_id = plan['id']
            
            # 3. Testar listagem
            print("\n3. Listando planos...")
            list_response = requests.get(
                f"{BASE_URL}/workout-plan/",
                headers=headers
            )
            
            if list_response.status_code == 200:
                plans = list_response.json()
                print(f"✅ Encontrados {len(plans)} planos")
                
                # 4. Testar busca por ID
                print(f"\n4. Buscando plano {plan_id}...")
                get_response = requests.get(
                    f"{BASE_URL}/workout-plan/{plan_id}",
                    headers=headers
                )
                
                if get_response.status_code == 200:
                    plan_details = get_response.json()
                    print(f"✅ Plano encontrado: {plan_details['plan_name']}")
                else:
                    print(f"❌ Erro ao buscar plano: {get_response.status_code}")
                    
            else:
                print(f"❌ Erro ao listar: {list_response.status_code}")
                
        else:
            print(f"❌ Erro ao criar: {create_response.status_code}")
            print(create_response.text)
        
        print("\n✅ Teste da API concluído!")
        
    except Exception as e:
        print(f"❌ Erro no teste: {e}")

if __name__ == "__main__":
    test_workout_api()