#!/usr/bin/env python3
"""
Simulador de Pagamentos Mercado Pago
Simula os dados de teste que aparecem na imagem
"""

import requests
import json
import asyncio
import asyncpg
from datetime import datetime

# Configurações
API_URL = "https://selene-daughterless-kenyatta.ngrok-free.dev"
DATABASE_URL = "postgresql://postgres:masterkey@localhost/livebs_db"

# Dados de teste do Mercado Pago (da imagem)
TEST_CARDS = {
    "mastercard": {
        "number": "5031433215406351",
        "expiry": "11/30", 
        "cvv": "123",
        "name": "APRO"  # Aprovado
    },
    "visa": {
        "number": "4235647728025682", 
        "expiry": "11/30",
        "cvv": "123", 
        "name": "APRO"  # Aprovado
    }
}

class PaymentSimulator:
    def __init__(self):
        self.session = requests.Session()
        
    async def create_test_subscription(self, user_email, card_type="mastercard"):
        """Cria uma assinatura de teste"""
        print(f"💳 Criando assinatura teste para: {user_email}")
        print(f"🎯 Usando cartão: {card_type}")
        
        # Primeiro, fazer login para obter token
        login_data = {
            "email": user_email,
            "password": "123456"  # Senha padrão de teste
        }
        
        try:
            # Login
            login_response = self.session.post(f"{API_URL}/auth/login", json=login_data)
            if login_response.status_code != 200:
                print(f"❌ Erro no login: {login_response.text}")
                return None
                
            token = login_response.json()["access_token"]
            print(f"✅ Login realizado, token obtido")
            
            # Headers com autenticação
            headers = {
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            }
            
            # Criar assinatura
            subscription_data = {
                "plan_type": "monthly",
                "amount": 39.90
            }
            
            sub_response = self.session.post(
                f"{API_URL}/subscription/create", 
                json=subscription_data, 
                headers=headers
            )
            
            if sub_response.status_code == 200:
                result = sub_response.json()
                print(f"✅ Assinatura criada!")
                print(f"   💰 ID: {result.get('payment_id')}")
                print(f"   🔗 URL: {result.get('payment_url')}")
                print(f"   📱 QR Code: {'Sim' if result.get('qr_code') else 'Não'}")
                return result
            else:
                print(f"❌ Erro ao criar assinatura: {sub_response.text}")
                return None
                
        except Exception as e:
            print(f"❌ Erro: {e}")
            return None
    
    async def simulate_payment_approval(self, payment_id, user_email):
        """Simula aprovação de pagamento via webhook"""
        print(f"\n🔔 Simulando aprovação de pagamento...")
        print(f"   💳 Payment ID: {payment_id}")
        print(f"   👤 Usuário: {user_email}")
        
        # Dados do webhook de pagamento aprovado
        webhook_data = {
            "id": int(datetime.now().timestamp()),
            "live_mode": False,  # Teste
            "type": "payment",
            "date_created": datetime.now().isoformat(),
            "application_id": 594823,
            "user_id": 594823,
            "version": 1,
            "api_version": "v1", 
            "action": "payment.updated",
            "data": {
                "id": str(payment_id)
            }
        }
        
        try:
            response = self.session.post(f"{API_URL}/webhook/mercadopago", json=webhook_data)
            print(f"✅ Webhook enviado: Status {response.status_code}")
            print(f"📄 Response: {response.text}")
            
            if response.status_code == 200:
                # Verificar se o status foi atualizado no banco
                await self.check_user_status(user_email)
                
        except Exception as e:
            print(f"❌ Erro no webhook: {e}")
    
    async def check_user_status(self, user_email):
        """Verifica status do usuário no banco"""
        print(f"\n🔍 Verificando status no banco para: {user_email}")
        
        try:
            conn = await asyncpg.connect(DATABASE_URL)
            
            query = """
            SELECT email, subscription_status, subscription_payment_id, subscription_date 
            FROM users 
            WHERE email = $1
            """
            
            result = await conn.fetchrow(query, user_email)
            await conn.close()
            
            if result:
                status = result['subscription_status']
                payment_id = result['subscription_payment_id']
                date = result['subscription_date']
                
                print(f"✅ Status atual: {status}")
                print(f"💳 Payment ID: {payment_id}")
                print(f"📅 Data: {date}")
                
                if status == 'active':
                    print("🟢 ASSINATURA ATIVA - Sistema funcionando!")
                else:
                    print("🟡 Assinatura pendente")
            else:
                print("❌ Usuário não encontrado")
                
        except Exception as e:
            print(f"❌ Erro ao verificar banco: {e}")
    
    async def create_test_user(self, email="teste@livebs.com"):
        """Cria usuário de teste"""
        print(f"\n👤 Criando usuário de teste: {email}")
        
        user_data = {
            "name": "Usuário Teste",
            "email": email,
            "password": "123456"
        }
        
        try:
            response = self.session.post(f"{API_URL}/auth/register", json=user_data)
            
            if response.status_code == 200:
                print("✅ Usuário criado com sucesso!")
                return True
            elif "já cadastrado" in response.text:
                print("ℹ️  Usuário já existe, continuando...")
                return True
            else:
                print(f"❌ Erro ao criar usuário: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Erro: {e}")
            return False
    
    async def full_test_flow(self, email="teste@livebs.com"):
        """Executa fluxo completo de teste"""
        print("🚀 INICIANDO TESTE COMPLETO DO SISTEMA DE ASSINATURA")
        print("="*60)
        
        # 1. Criar usuário de teste
        if not await self.create_test_user(email):
            return
        
        # 2. Criar assinatura
        subscription = await self.create_test_subscription(email)
        if not subscription:
            return
            
        payment_id = subscription.get('payment_id')
        if not payment_id:
            print("❌ Payment ID não encontrado")
            return
        
        # 3. Simular pagamento aprovado
        await asyncio.sleep(2)  # Aguardar um pouco
        await self.simulate_payment_approval(payment_id, email)
        
        # 4. Testar login com verificação de assinatura
        print(f"\n🔐 Testando login com verificação de assinatura...")
        await asyncio.sleep(2)
        
        login_data = {
            "email": email,
            "password": "123456"
        }
        
        try:
            response = self.session.post(f"{API_URL}/auth/login", json=login_data)
            if response.status_code == 200:
                print("✅ Login realizado - Assinatura verificada!")
            else:
                print(f"❌ Erro no login: {response.text}")
        except Exception as e:
            print(f"❌ Erro no login: {e}")
        
        print(f"\n🎉 TESTE COMPLETO FINALIZADO!")
        print("="*60)

async def main():
    simulator = PaymentSimulator()
    
    print("🧪 SIMULADOR DE PAGAMENTOS MERCADO PAGO")
    print("Baseado nos dados de teste da imagem fornecida")
    print("="*50)
    
    while True:
        print("\nEscolha uma opção:")
        print("1. 🚀 Executar teste completo")
        print("2. 👤 Criar usuário de teste")
        print("3. 💳 Criar assinatura")
        print("4. 🔔 Simular webhook de aprovação") 
        print("5. 🔍 Verificar status de usuário")
        print("6. 📋 Mostrar dados de teste")
        print("0. ❌ Sair")
        
        choice = input("\nDigite sua opção: ")
        
        if choice == "1":
            email = input("Email do usuário (Enter=teste@livebs.com): ") or "teste@livebs.com"
            await simulator.full_test_flow(email)
            
        elif choice == "2":
            email = input("Email do usuário: ")
            await simulator.create_test_user(email)
            
        elif choice == "3":
            email = input("Email do usuário: ")
            card = input("Cartão (mastercard/visa): ") or "mastercard"
            await simulator.create_test_subscription(email, card)
            
        elif choice == "4":
            payment_id = input("Payment ID: ")
            email = input("Email do usuário: ")
            await simulator.simulate_payment_approval(payment_id, email)
            
        elif choice == "5":
            email = input("Email do usuário: ")
            await simulator.check_user_status(email)
            
        elif choice == "6":
            print("\n💳 DADOS DE TESTE MERCADO PAGO:")
            print("="*40)
            for card_name, card_data in TEST_CARDS.items():
                print(f"\n{card_name.upper()}:")
                print(f"  Número: {card_data['number']}")
                print(f"  Validade: {card_data['expiry']}")
                print(f"  CVV: {card_data['cvv']}")
                print(f"  Nome: {card_data['name']}")
            print(f"\n📋 Use estes dados nos testes do Mercado Pago")
            
        elif choice == "0":
            print("👋 Saindo...")
            break
        else:
            print("❌ Opção inválida!")

if __name__ == "__main__":
    asyncio.run(main())