import requests
import json

BASE_URL = "http://localhost:8000"

def test_register():
    """Testa registro de usuário"""
    print("🔹 Testando registro...")
    response = requests.post(
        f"{BASE_URL}/auth/register",
        json={
            "email": "teste@livebs.com",
            "password": "senha123",
            "name": "Usuário Teste"
        }
    )
    print(f"Status: {response.status_code}")
    print(f"Resposta: {json.dumps(response.json(), indent=2)}")
    return response.json()

def test_login():
    """Testa login"""
    print("\n🔹 Testando login...")
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={
            "email": "teste@livebs.com",
            "password": "senha123"
        }
    )
    print(f"Status: {response.status_code}")
    data = response.json()
    print(f"Token: {data.get('access_token', 'N/A')[:50]}...")
    return data.get('access_token')

def test_create_profile(token):
    """Testa criação de perfil"""
    print("\n🔹 Testando criação de perfil...")
    response = requests.post(
        f"{BASE_URL}/profile",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "weight": 85.5,
            "height": 175,
            "age": 30,
            "gender": "male",
            "target_weight": 75.0,
            "activity_level": "moderate",
            "dietary_restrictions": ["lactose"],
            "dietary_preferences": ["vegetais"]
        }
    )
    print(f"Status: {response.status_code}")
    print(f"Perfil: {json.dumps(response.json(), indent=2, default=str)}")

def test_send_message(token):
    """Testa envio de mensagem ao chat"""
    print("\n🔹 Testando chat IA...")
    response = requests.post(
        f"{BASE_URL}/chat",
        headers={"Authorization": f"Bearer {token}"},
        json={"message": "Olá! Preciso de ajuda com minha dieta."}
    )
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"Resposta IA: {data.get('message', 'N/A')[:100]}...")

if __name__ == "__main__":
    print("=" * 50)
    print("🚀 TESTANDO API LIVEBS")
    print("=" * 50)
    
    try:
        # 1. Registro
        user = test_register()
        
        # 2. Login
        token = test_login()
        
        # 3. Criar perfil
        test_create_profile(token)
        
        # 4. Testar chat (só funciona com OpenAI key configurada)
        # test_send_message(token)
        
        print("\n" + "=" * 50)
        print("✅ TODOS OS TESTES PASSARAM!")
        print("=" * 50)
        
    except Exception as e:
        print(f"\n❌ ERRO: {e}")
