import requests
import json

BASE_URL = "http://192.168.0.85:8000"

def test_gui_user():
    """Testa login e busca de planos para gui@gmail.com"""
    
    print("=== TESTANDO USUÁRIO gui@gmail.com ===")
    
    # Tentar login
    login_data = {"email": "gui@gmail.com", "password": "123123"}
    
    print("1. Tentando fazer login...")
    login_response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    print(f"Status do login: {login_response.status_code}")
    
    if login_response.status_code != 200:
        print(f"❌ Erro no login: {login_response.text}")
        
        # Tentar outras senhas comuns
        senhas = ["123123", "123456", "senha123", "gui123", "12345678"]
        for senha in senhas:
            print(f"Tentando senha: {senha}")
            test_login = requests.post(f"{BASE_URL}/auth/login", json={"email": "gui@gmail.com", "password": senha})
            if test_login.status_code == 200:
                print(f"✅ Login bem-sucedido com senha: {senha}")
                token = test_login.json()['access_token']
                break
        else:
            print("❌ Nenhuma senha funcionou")
            return
    else:
        token = login_response.json()['access_token']
        print(f"✅ Login bem-sucedido!")
    
    # Buscar planos
    headers = {"Authorization": f"Bearer {token}"}
    
    print("\n2. Buscando planos alimentares...")
    response = requests.get(f"{BASE_URL}/meal-plan", headers=headers)
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        plans = data.get('plans', [])
        print(f"✅ {len(plans)} planos encontrados:")
        
        for plan in plans:
            print(f"   - {plan['plan_name']} (ID: {plan['id']})")
            
        return plans
    else:
        print(f"❌ Erro ao buscar planos: {response.text}")
        return []

if __name__ == "__main__":
    test_gui_user()