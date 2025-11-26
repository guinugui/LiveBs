import requests
import json

BASE_URL = "http://192.168.0.85:8000"

def check_all_users():
    """Verifica todos os usuários e seus planos"""
    
    # Testar com usuário de teste
    test_users = [
        {"email": "test@example.com", "password": "123456"},
        {"email": "teste@email.com", "password": "123456"},
        {"email": "admin@test.com", "password": "123456"},
    ]
    
    for user in test_users:
        print(f"\n=== TESTANDO USUÁRIO: {user['email']} ===")
        
        # Login
        login_response = requests.post(f"{BASE_URL}/auth/login", json=user)
        
        if login_response.status_code == 200:
            token = login_response.json()['access_token']
            headers = {"Authorization": f"Bearer {token}"}
            
            # Buscar planos
            response = requests.get(f"{BASE_URL}/meal-plan", headers=headers)
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Login OK - Planos: {len(data.get('plans', []))}")
                for plan in data.get('plans', []):
                    print(f"  - {plan['plan_name']} (ID: {plan['id']})")
            else:
                print(f"❌ Erro ao buscar planos: {response.status_code}")
        else:
            print(f"❌ Login falhou: {login_response.status_code}")

if __name__ == "__main__":
    check_all_users()