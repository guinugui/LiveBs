#!/usr/bin/env python3
"""
Script de Teste para Sistema de Assinatura Mercado Pago

Este script facilita os testes locais e em produção do sistema de pagamento
"""

import asyncio
import json
import asyncpg
from datetime import datetime
import requests
import os

# Configurações
NGROK_URL = "https://selene-daughterless-kenyatta.ngrok-free.dev"
LOCAL_URL = "http://192.168.0.85:8001"
DATABASE_URL = "postgresql://postgres:MCguinu02@127.0.0.1:5432/livebs_db"

async def test_subscription_creation():
    """Testa criação de assinatura"""
    print("🧪 Testando criação de assinatura...")
    
    # Simular token de usuário (você precisa pegar um token real)
    headers = {
        "Authorization": "Bearer YOUR_TOKEN_HERE",
        "Content-Type": "application/json"
    }
    
    data = {
        "plan_type": "monthly",
        "amount": 39.90
    }
    
    try:
        response = requests.post(f"{NGROK_URL}/subscription/create", json=data, headers=headers)
        print(f"✅ Status: {response.status_code}")
        print(f"📄 Response: {response.json()}")
        return response.json()
    except Exception as e:
        print(f"❌ Erro: {e}")
        return None

async def test_webhook_simulation():
    """Simula um webhook do Mercado Pago"""
    print("\n🔔 Simulando webhook do Mercado Pago...")
    
    # Dados simulados de pagamento aprovado
    webhook_data = {
        "id": 12345678901,
        "live_mode": True,
        "type": "payment",
        "date_created": datetime.now().isoformat(),
        "application_id": 594823,
        "user_id": 594823,
        "version": 1,
        "api_version": "v1",
        "action": "payment.updated",
        "data": {
            "id": "1234567890"  # ID do pagamento
        }
    }
    
    try:
        response = requests.post(f"{NGROK_URL}/webhook/mercadopago", json=webhook_data)
        print(f"✅ Webhook Status: {response.status_code}")
        print(f"📄 Webhook Response: {response.text}")
    except Exception as e:
        print(f"❌ Webhook Erro: {e}")

async def check_user_subscription_status(user_email):
    """Verifica status da assinatura de um usuário específico"""
    print(f"\n👤 Verificando status de assinatura para: {user_email}")
    
    conn = None
    try:
        print("🔌 Conectando ao banco PostgreSQL...")
        conn = await asyncpg.connect(DATABASE_URL)
        print("✅ Conectado ao banco")
        
        query = """
        SELECT email, subscription_status, subscription_payment_id, subscription_date 
        FROM users 
        WHERE email = $1
        """
        
        result = await conn.fetchrow(query, user_email)
        
        if result:
            print(f"✅ Usuário encontrado:")
            print(f"   📧 Email: {result['email']}")
            print(f"   📊 Status: {result['subscription_status']}")
            print(f"   💳 Payment ID: {result['subscription_payment_id']}")
            print(f"   📅 Data: {result['subscription_date']}")
            
            is_active = result['subscription_status'] == 'active'
            print(f"   🟢 Assinatura Ativa: {'SIM' if is_active else 'NÃO'}")
        else:
            print("❌ Usuário não encontrado")
            
    except Exception as e:
        print(f"❌ Erro ao verificar banco: {e}")
        print("💡 Verifique se:")
        print("   - PostgreSQL está rodando")
        print("   - As credenciais estão corretas") 
        print("   - O banco 'livebs_db' existe")
    finally:
        if conn:
            await conn.close()
            print("🔌 Conexão fechada")

async def update_user_subscription(user_email, status, payment_id=None):
    """Atualiza manualmente o status de assinatura (para testes)"""
    print(f"\n⚙️ Atualizando assinatura para {user_email} -> {status}")
    
    conn = None
    try:
        conn = await asyncpg.connect(DATABASE_URL)
        
        if payment_id:
            query = """
            UPDATE users 
            SET subscription_status = $1, subscription_payment_id = $2, subscription_date = $3
            WHERE email = $4
            """
            await conn.execute(query, status, payment_id, datetime.now(), user_email)
        else:
            query = """
            UPDATE users 
            SET subscription_status = $1, subscription_date = $2
            WHERE email = $3
            """
            await conn.execute(query, status, datetime.now(), user_email)
        
        print(f"✅ Status atualizado para: {status}")
        
    except Exception as e:
        print(f"❌ Erro ao atualizar: {e}")
    finally:
        if conn:
            await conn.close()

async def list_all_users():
    """Lista todos os usuários e seus status"""
    print("\n📋 Listando todos os usuários:")
    
    conn = None
    try:
        conn = await asyncpg.connect(DATABASE_URL)
        
        query = """
        SELECT id, email, subscription_status, subscription_date, created_at
        FROM users 
        ORDER BY created_at DESC
        LIMIT 10
        """
        
        results = await conn.fetch(query)
        
        if results:
            for user in results:
                status_emoji = "🟢" if user['subscription_status'] == 'active' else "🔴"
                print(f"   {status_emoji} ID: {user['id']} | {user['email']} | {user['subscription_status']} | {user['created_at']}")
        else:
            print("   📭 Nenhum usuário encontrado")
            
    except Exception as e:
        print(f"❌ Erro ao listar usuários: {e}")
        print("💡 Certifique-se que o PostgreSQL está rodando")
    finally:
        if conn:
            await conn.close()

def test_api_endpoints():
    """Testa endpoints básicos da API"""
    print("\n🌐 Testando endpoints da API...")
    
    endpoints = [
        "/",
        "/health"
    ]
    
    for endpoint in endpoints:
        try:
            response = requests.get(f"{LOCAL_URL}{endpoint}")
            print(f"✅ {endpoint}: {response.status_code}")
        except Exception as e:
            print(f"❌ {endpoint}: {e}")

async def simulate_user_payment_webhook(user_email):
    """Simula pagamento de um usuário específico via webhook"""
    print(f"\n💳 Simulando pagamento para: {user_email}")
    
    conn = None
    try:
        conn = await asyncpg.connect(DATABASE_URL)
        
        # Buscar usuário
        user_query = "SELECT id, subscription_payment_id FROM users WHERE email = $1"
        user = await conn.fetchrow(user_query, user_email)
        
        if not user:
            print(f"❌ Usuário {user_email} não encontrado")
            return
            
        user_id = user['id']
        payment_id = user['subscription_payment_id'] or f"MP_TEST_{user_id}_{int(datetime.now().timestamp())}"
        
        # Atualizar payment_id se não existir
        if not user['subscription_payment_id']:
            await conn.execute(
                "UPDATE users SET subscription_payment_id = $1 WHERE id = $2",
                payment_id, user_id
            )
            print(f"🔧 Payment ID gerado: {payment_id}")
        
        # Simular webhook do Mercado Pago
        webhook_data = {
            "id": 12345678901,
            "live_mode": False,
            "type": "payment",
            "date_created": datetime.now().isoformat(),
            "user_id": 594823,
            "api_version": "v1", 
            "action": "payment.updated",
            "data": {
                "id": payment_id
            }
        }
        
        # Enviar webhook
        webhook_url = f"{LOCAL_URL}/api/subscription/webhook"
        response = requests.post(webhook_url, json=webhook_data)
        
        if response.status_code == 200:
            print(f"✅ Webhook enviado com sucesso!")
            print(f"📄 Response: {response.json()}")
            
            # Verificar se o status foi atualizado
            await asyncio.sleep(1)
            updated_user = await conn.fetchrow(
                "SELECT subscription_status FROM users WHERE email = $1", 
                user_email
            )
            
            print(f"🔄 Status atual: {updated_user['subscription_status']}")
            
        else:
            print(f"❌ Erro no webhook: {response.status_code}")
            print(f"📄 Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Erro: {e}")
    finally:
        if conn:
            await conn.close()

async def main():
    print("🚀 SISTEMA DE TESTES - LiveBs Assinatura")
    print("="*50)
    
    while True:
        print("\nEscolha uma opção:")
        print("1. 🧪 Testar criação de assinatura")
        print("2. 🔔 Simular webhook Mercado Pago") 
        print("3. 👤 Verificar status de usuário")
        print("4. ⚙️ Atualizar status manualmente")
        print("5. 📋 Listar todos os usuários")
        print("6. 🌐 Testar endpoints básicos")
        print("7. 🔔 Simular webhook de pagamento específico")
        print("8. 🔄 Executar todos os testes")
        print("0. ❌ Sair")
        
        choice = input("\nDigite sua opção: ")
        
        if choice == "1":
            await test_subscription_creation()
        elif choice == "2":
            await test_webhook_simulation()
        elif choice == "3":
            email = input("Digite o email do usuário: ")
            await check_user_subscription_status(email)
        elif choice == "4":
            email = input("Digite o email do usuário: ")
            status = input("Digite o novo status (pending/active/cancelled): ")
            payment_id = input("Digite o payment ID (opcional): ") or None
            await update_user_subscription(email, status, payment_id)
        elif choice == "5":
            await list_all_users()
        elif choice == "6":
            test_api_endpoints()
        elif choice == "7":
            email = input("Digite o email do usuário para simular pagamento: ")
            await simulate_user_payment_webhook(email)
        elif choice == "8":
            await test_subscription_creation()
            await test_webhook_simulation()
            test_api_endpoints()
            await list_all_users()
        elif choice == "0":
            print("👋 Saindo...")
            break
        else:
            print("❌ Opção inválida!")

if __name__ == "__main__":
    asyncio.run(main())