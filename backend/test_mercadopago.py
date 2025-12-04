#!/usr/bin/env python3
"""
Script para testar integração com Mercado Pago
Usando as credenciais e cartões de teste mostrados na imagem
"""

import requests
import json
from datetime import datetime

# Configurações baseadas na imagem
BASE_URL = "http://192.168.0.85:8001"
USER_ID = "3037885683"  # User ID do painel MP
APP_ID = "4726385779514992"  # Número da aplicação

# Cartões de teste do Mercado Pago (da imagem)
TEST_CARDS = {
    "mastercard": {
        "number": "5031433215406351",
        "expiry": "11/30",  
        "cvv": "123"
    },
    "visa": {
        "number": "4235647728025682", 
        "expiry": "11/30",
        "cvv": "123"
    }
}

def test_subscription_endpoint():
    """Testa o endpoint de criação de assinatura"""
    print("🧪 Testando endpoint de assinatura...")
    
    # Dados para criar assinatura
    subscription_data = {
        "plan_type": "monthly",
        "amount": 39.90
    }
    
    # Headers (sem token por enquanto para testar sem autenticação)
    headers = {
        "Content-Type": "application/json"
    }
    
    try:
        # Primeiro testar sem autenticação para ver o erro
        print("📡 Fazendo requisição para criar assinatura...")
        response = requests.post(
            f"{BASE_URL}/subscription/create",
            json=subscription_data,
            headers=headers,
            timeout=10
        )
        
        print(f"📊 Status Code: {response.status_code}")
        print(f"📄 Response: {response.text}")
        
        return response.json() if response.headers.get('content-type', '').startswith('application/json') else response.text
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro na requisição: {e}")
        return None

def test_health_endpoint():
    """Testa se o servidor está funcionando"""
    print("🏥 Testando endpoint de saúde...")
    
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        print(f"✅ Servidor funcionando: {response.json()}")
        return True
    except Exception as e:
        print(f"❌ Servidor não responde: {e}")
        return False

def test_login_and_subscription():
    """Testa login de usuário e criação de assinatura"""
    print("\n🔐 Testando fluxo completo: login + assinatura...")
    
    # Dados de um usuário existente (gui@gmail.com que sabemos que existe)
    login_data = {
        "email": "gui@gmail.com",
        "password": "123123"
    }
    
    try:
        # 1. Fazer login
        print("1️⃣ Fazendo login...")
        login_response = requests.post(
            f"{BASE_URL}/auth/login",
            json=login_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        print(f"📊 Login Status: {login_response.status_code}")
        
        if login_response.status_code == 200:
            login_result = login_response.json()
            token = login_result.get("access_token")
            
            if token:
                print("✅ Login realizado com sucesso!")
                print(f"🔑 Token obtido: {token[:50]}...")
                
                # 2. Criar assinatura com token
                print("\n2️⃣ Criando assinatura...")
                subscription_data = {
                    "plan_type": "monthly", 
                    "amount": 39.90
                }
                
                auth_headers = {
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {token}"
                }
                
                sub_response = requests.post(
                    f"{BASE_URL}/subscription/create",
                    json=subscription_data,
                    headers=auth_headers,
                    timeout=15
                )
                
                print(f"📊 Assinatura Status: {sub_response.status_code}")
                print(f"📄 Assinatura Response: {sub_response.text}")
                
                return sub_response.json() if sub_response.headers.get('content-type', '').startswith('application/json') else sub_response.text
                
        else:
            print(f"❌ Erro no login: {login_response.text}")
            
    except Exception as e:
        print(f"❌ Erro no fluxo: {e}")
        return None

def main():
    print("🚀 TESTE DE INTEGRAÇÃO MERCADO PAGO - LiveBs")
    print("=" * 60)
    
    # Verificar se servidor está rodando
    if not test_health_endpoint():
        print("❌ Servidor não está respondendo. Verifique se está rodando.")
        return
    
    print("\n" + "=" * 60)
    
    # Testar endpoint básico
    test_subscription_endpoint()
    
    print("\n" + "=" * 60)
    
    # Testar fluxo completo
    test_login_and_subscription()
    
    print("\n" + "=" * 60)
    print("🏁 Testes concluídos!")
    print("\n💡 INFORMAÇÕES DO MERCADO PAGO:")
    print(f"   User ID: {USER_ID}")
    print(f"   App ID: {APP_ID}")
    print(f"   Cartões de teste disponíveis:")
    for brand, card in TEST_CARDS.items():
        print(f"     {brand.upper()}: {card['number']} | {card['expiry']} | {card['cvv']}")

if __name__ == "__main__":
    main()