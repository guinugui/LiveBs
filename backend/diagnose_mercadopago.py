#!/usr/bin/env python3
"""
Script para diagnosticar e configurar integração Mercado Pago
"""

import requests
import json
import os

# Credenciais de teste do Mercado Pago
ACCESS_TOKEN = "TEST-3929468103866921-120418-b790a49ac1209cc4f7eedac43bb06b28-594823"
PUBLIC_KEY = "TEST-c330b8dc-1d2b-48e0-8dd1-8751970b0b5f"

def test_credentials():
    """Testa se as credenciais estão válidas"""
    print("🔐 Testando credenciais do Mercado Pago...")
    
    headers = {
        "Authorization": f"Bearer {ACCESS_TOKEN}",
        "Content-Type": "application/json"
    }
    
    try:
        # Testar endpoint de usuário para validar token
        response = requests.get(
            "https://api.mercadopago.com/users/me",
            headers=headers
        )
        
        if response.status_code == 200:
            user_data = response.json()
            print(f"✅ Credenciais válidas!")
            print(f"   User ID: {user_data.get('id')}")
            print(f"   Email: {user_data.get('email')}")
            print(f"   País: {user_data.get('site_id')}")
            return True
        else:
            print(f"❌ Credenciais inválidas: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro ao testar credenciais: {e}")
        return False

def create_webhook():
    """Cria webhook para receber notificações"""
    print("\n🔔 Configurando webhook...")
    
    headers = {
        "Authorization": f"Bearer {ACCESS_TOKEN}",
        "Content-Type": "application/json"
    }
    
    webhook_data = {
        "url": "http://192.168.0.85:8001/subscription/webhook",
        "events": [
            {"topic": "payment"},
            {"topic": "subscription_preapproval"}
        ]
    }
    
    try:
        response = requests.post(
            "https://api.mercadopago.com/v1/webhooks",
            json=webhook_data,
            headers=headers
        )
        
        if response.status_code == 201:
            webhook = response.json()
            print(f"✅ Webhook criado!")
            print(f"   ID: {webhook.get('id')}")
            print(f"   URL: {webhook.get('url')}")
            return webhook.get('id')
        else:
            print(f"❌ Erro ao criar webhook: {response.status_code}")
            print(f"   Response: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Erro: {e}")
        return None

def list_webhooks():
    """Lista webhooks existentes"""
    print("\n📋 Listando webhooks existentes...")
    
    headers = {
        "Authorization": f"Bearer {ACCESS_TOKEN}",
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.get(
            "https://api.mercadopago.com/v1/webhooks",
            headers=headers
        )
        
        if response.status_code == 200:
            webhooks = response.json()
            if webhooks:
                for webhook in webhooks:
                    print(f"   📡 ID: {webhook.get('id')} | URL: {webhook.get('url')}")
            else:
                print("   📭 Nenhum webhook configurado")
        else:
            print(f"❌ Erro ao listar webhooks: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Erro: {e}")

def test_simple_payment():
    """Testa criação de um pagamento PIX simples"""
    print("\n💳 Testando criação de pagamento PIX...")
    
    headers = {
        "Authorization": f"Bearer {ACCESS_TOKEN}",
        "Content-Type": "application/json"
    }
    
    payment_data = {
        "transaction_amount": 39.90,
        "description": "Teste LiveBs - Assinatura Mensal",
        "payment_method_id": "pix",
        "payer": {
            "email": "test@test.com",
            "first_name": "João",
            "last_name": "Silva",
            "identification": {
                "type": "CPF",
                "number": "11144477735"  # CPF de teste válido
            }
        },
        "notification_url": "http://192.168.0.85:8001/subscription/webhook"
    }
    
    try:
        response = requests.post(
            "https://api.mercadopago.com/v1/payments",
            json=payment_data,
            headers=headers
        )
        
        if response.status_code == 201:
            payment = response.json()
            print(f"✅ Pagamento PIX criado!")
            print(f"   ID: {payment.get('id')}")
            print(f"   Status: {payment.get('status')}")
            print(f"   QR Code: {payment.get('point_of_interaction', {}).get('transaction_data', {}).get('qr_code', 'N/A')[:50]}...")
            return payment
        else:
            print(f"❌ Erro ao criar pagamento: {response.status_code}")
            print(f"   Response: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Erro: {e}")
        return None

def main():
    print("🚀 DIAGNÓSTICO MERCADO PAGO - LiveBs")
    print("=" * 60)
    
    # 1. Testar credenciais
    if not test_credentials():
        print("\n❌ Pare aqui! Credenciais inválidas.")
        print("💡 Verifique no painel MP: Suas integrações > Credenciais")
        return
    
    # 2. Listar webhooks existentes
    list_webhooks()
    
    # 3. Criar webhook se necessário
    webhook_id = create_webhook()
    
    # 4. Testar pagamento simples
    payment = test_simple_payment()
    
    print("\n" + "=" * 60)
    print("📋 RESUMO:")
    print(f"   🔑 Credenciais: ✅ Válidas")
    print(f"   🔔 Webhook: {'✅ Configurado' if webhook_id else '❌ Falhou'}")
    print(f"   💳 Pagamento: {'✅ Funcionando' if payment else '❌ Falhou'}")
    
    if payment:
        print("\n🎉 TUDO PRONTO!")
        print("   Agora você pode testar no app Flutter:")
        print("   1. Faça login com gui@gmail.com")
        print("   2. Tente criar assinatura")
        print("   3. Use o QR Code PIX gerado")
    else:
        print("\n⚠️ AÇÃO NECESSÁRIA:")
        print("   1. Verifique as credenciais no painel MP")
        print("   2. Confirme se está usando ambiente de TESTE")
        print("   3. Verifique se a aplicação está aprovada")

if __name__ == "__main__":
    main()