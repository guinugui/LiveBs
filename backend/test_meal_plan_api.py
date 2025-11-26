import requests
import json

BASE_URL = "http://127.0.0.1:8000"

def test_login():
    """Testa login e retorna token"""
    url = f"{BASE_URL}/auth/login"
    data = {
        "email": "test@example.com",
        "password": "123456"
    }
    
    response = requests.post(url, json=data)
    print(f"Login status: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        token = result.get('access_token')
        print(f"Token obtido: {token[:50]}..." if token else "Token não encontrado")
        return token
    else:
        print(f"Erro no login: {response.text}")
        return None

def test_meal_plan_endpoints(token):
    """Testa os endpoints de plano alimentar"""
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    
    print("\n=== TESTANDO ENDPOINTS DE PLANO ALIMENTAR ===")
    
    # 1. Listar planos salvos
    print("\n1. Listando planos salvos...")
    response = requests.get(f"{BASE_URL}/meal-plan", headers=headers)
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"Planos encontrados: {len(data.get('plans', []))}")
        print(json.dumps(data, indent=2, ensure_ascii=False))
    else:
        print(f"Erro: {response.text}")
    
    # 2. Criar novo plano
    print("\n2. Criando novo plano...")
    response = requests.post(f"{BASE_URL}/meal-plan", headers=headers)
    print(f"Status: {response.status_code}")
    if response.status_code == 201:
        data = response.json()
        print(f"Plano criado: {data.get('plan_name')}")
        plan_id = data.get('id')
        print(f"ID do plano: {plan_id}")
        
        if plan_id:
            # 3. Buscar detalhes do plano
            print(f"\n3. Buscando detalhes do plano {plan_id}...")
            response = requests.get(f"{BASE_URL}/meal-plan/{plan_id}", headers=headers)
            print(f"Status: {response.status_code}")
            if response.status_code == 200:
                data = response.json()
                print(f"Plano encontrado: {data.get('plan_name')}")
                print("Estrutura do plan_data:")
                plan_data = data.get('plan_data', {})
                if isinstance(plan_data, dict) and 'days' in plan_data:
                    print(f"  - Dias: {len(plan_data['days'])}")
                    for i, day in enumerate(plan_data['days'][:2]):  # Mostra só 2 dias
                        print(f"  - Dia {day.get('day', i+1)}: {len(day.get('meals', []))} refeições")
                else:
                    print(f"  - Tipo: {type(plan_data)}")
            else:
                print(f"Erro: {response.text}")
                
    else:
        print(f"Erro: {response.text}")

if __name__ == "__main__":
    # Fazer login primeiro
    token = test_login()
    
    if token:
        # Testar endpoints de meal plan
        test_meal_plan_endpoints(token)
    else:
        print("Não foi possível fazer login. Testando sem autenticação...")
        test_meal_plan_endpoints(None)