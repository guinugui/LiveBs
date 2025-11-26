import requests
import json

BASE_URL = "http://192.168.0.85:8000"

def test_get_saved_plans():
    """Testa apenas o GET da lista de planos salvos"""
    
    # Login primeiro
    login_data = {"email": "test@example.com", "password": "123456"}
    login_response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    
    if login_response.status_code != 200:
        print(f"Erro no login: {login_response.text}")
        return
        
    token = login_response.json()['access_token']
    headers = {"Authorization": f"Bearer {token}"}
    
    # Testar GET /meal-plan
    print("Testando GET /meal-plan...")
    response = requests.get(f"{BASE_URL}/meal-plan", headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")

if __name__ == "__main__":
    test_get_saved_plans()