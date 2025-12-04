#!/usr/bin/env python3
"""
Configurador de Webhook para Produção
Atualiza automaticamente a URL do webhook no Mercado Pago
"""

import requests
import json
import os
from datetime import datetime

class WebhookConfigurator:
    def __init__(self):
        self.access_token = None
        self.base_url = "https://api.mercadopago.com"
        
    def set_access_token(self, token):
        """Define o token de acesso"""
        self.access_token = token
        print(f"✅ Token configurado: {token[:20]}...")
    
    def create_webhook(self, webhook_url):
        """Cria um novo webhook"""
        print(f"🔗 Criando webhook para: {webhook_url}")
        
        headers = {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json"
        }
        
        data = {
            "url": webhook_url,
            "events": ["payment"]
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/v1/webhooks",
                headers=headers,
                json=data
            )
            
            if response.status_code == 201:
                result = response.json()
                webhook_id = result.get("id")
                print(f"✅ Webhook criado com sucesso!")
                print(f"   🆔 ID: {webhook_id}")
                print(f"   🔗 URL: {result.get('url')}")
                print(f"   📅 Criado em: {result.get('date_created')}")
                return webhook_id
            else:
                print(f"❌ Erro ao criar webhook: {response.status_code}")
                print(f"   📄 Response: {response.text}")
                return None
                
        except Exception as e:
            print(f"❌ Erro: {e}")
            return None
    
    def list_webhooks(self):
        """Lista todos os webhooks existentes"""
        print("📋 Listando webhooks existentes...")
        
        headers = {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json"
        }
        
        try:
            response = requests.get(
                f"{self.base_url}/v1/webhooks",
                headers=headers
            )
            
            if response.status_code == 200:
                webhooks = response.json().get("results", [])
                
                if webhooks:
                    print(f"✅ Encontrados {len(webhooks)} webhook(s):")
                    for webhook in webhooks:
                        status = "🟢 Ativo" if webhook.get("status") == "active" else "🔴 Inativo"
                        print(f"   🆔 ID: {webhook.get('id')}")
                        print(f"   🔗 URL: {webhook.get('url')}")
                        print(f"   📊 Status: {status}")
                        print(f"   📅 Criado: {webhook.get('date_created')}")
                        print("   " + "-"*40)
                else:
                    print("ℹ️  Nenhum webhook encontrado")
                    
                return webhooks
            else:
                print(f"❌ Erro ao listar webhooks: {response.status_code}")
                print(f"   📄 Response: {response.text}")
                return []
                
        except Exception as e:
            print(f"❌ Erro: {e}")
            return []
    
    def delete_webhook(self, webhook_id):
        """Deleta um webhook"""
        print(f"🗑️  Deletando webhook ID: {webhook_id}")
        
        headers = {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json"
        }
        
        try:
            response = requests.delete(
                f"{self.base_url}/v1/webhooks/{webhook_id}",
                headers=headers
            )
            
            if response.status_code == 200:
                print("✅ Webhook deletado com sucesso!")
                return True
            else:
                print(f"❌ Erro ao deletar webhook: {response.status_code}")
                print(f"   📄 Response: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Erro: {e}")
            return False
    
    def update_webhook(self, webhook_id, new_url):
        """Atualiza URL de um webhook existente"""
        print(f"🔄 Atualizando webhook {webhook_id} para: {new_url}")
        
        headers = {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json"
        }
        
        data = {
            "url": new_url,
            "events": ["payment"]
        }
        
        try:
            response = requests.put(
                f"{self.base_url}/v1/webhooks/{webhook_id}",
                headers=headers,
                json=data
            )
            
            if response.status_code == 200:
                result = response.json()
                print("✅ Webhook atualizado com sucesso!")
                print(f"   🔗 Nova URL: {result.get('url')}")
                return True
            else:
                print(f"❌ Erro ao atualizar webhook: {response.status_code}")
                print(f"   📄 Response: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Erro: {e}")
            return False
    
    def test_webhook_url(self, url):
        """Testa se a URL do webhook está respondendo"""
        print(f"🧪 Testando URL do webhook: {url}")
        
        try:
            # Simular dados de teste
            test_data = {
                "id": 12345,
                "live_mode": False,
                "type": "payment",
                "date_created": datetime.now().isoformat(),
                "data": {"id": "test"}
            }
            
            response = requests.post(url, json=test_data, timeout=10)
            
            if response.status_code == 200:
                print("✅ URL está respondendo corretamente!")
                return True
            else:
                print(f"⚠️  URL respondeu com status: {response.status_code}")
                return False
                
        except requests.exceptions.Timeout:
            print("❌ Timeout - URL não respondeu em 10 segundos")
            return False
        except Exception as e:
            print(f"❌ Erro ao testar URL: {e}")
            return False

def main():
    configurator = WebhookConfigurator()
    
    print("🔧 CONFIGURADOR DE WEBHOOK MERCADO PAGO")
    print("Para configuração em produção")
    print("="*50)
    
    # Solicitar token se não estiver definido
    token = os.getenv("MERCADOPAGO_ACCESS_TOKEN")
    if not token:
        token = input("Digite seu Access Token do Mercado Pago: ")
    
    configurator.set_access_token(token)
    
    while True:
        print("\nEscolha uma opção:")
        print("1. 📋 Listar webhooks existentes")
        print("2. 🔗 Criar novo webhook")
        print("3. 🔄 Atualizar webhook existente")
        print("4. 🗑️  Deletar webhook")
        print("5. 🧪 Testar URL de webhook")
        print("6. ⚙️  Setup completo para produção")
        print("0. ❌ Sair")
        
        choice = input("\nDigite sua opção: ")
        
        if choice == "1":
            configurator.list_webhooks()
            
        elif choice == "2":
            url = input("Digite a URL do webhook (ex: https://api.livebs.com.br/webhook/mercadopago): ")
            if configurator.test_webhook_url(url):
                configurator.create_webhook(url)
            else:
                print("⚠️  URL não está respondendo. Deseja criar mesmo assim? (y/n)")
                if input().lower() == 'y':
                    configurator.create_webhook(url)
                    
        elif choice == "3":
            webhooks = configurator.list_webhooks()
            if webhooks:
                webhook_id = input("Digite o ID do webhook para atualizar: ")
                new_url = input("Digite a nova URL: ")
                if configurator.test_webhook_url(new_url):
                    configurator.update_webhook(webhook_id, new_url)
                    
        elif choice == "4":
            webhooks = configurator.list_webhooks()
            if webhooks:
                webhook_id = input("Digite o ID do webhook para deletar: ")
                if input("Confirma deletar? (y/n): ").lower() == 'y':
                    configurator.delete_webhook(webhook_id)
                    
        elif choice == "5":
            url = input("Digite a URL para testar: ")
            configurator.test_webhook_url(url)
            
        elif choice == "6":
            print("\n🚀 SETUP COMPLETO PARA PRODUÇÃO")
            print("="*40)
            
            domain = input("Digite seu domínio (ex: api.livebs.com.br): ")
            webhook_url = f"https://{domain}/webhook/mercadopago"
            
            print(f"\n1. 🧪 Testando URL: {webhook_url}")
            if configurator.test_webhook_url(webhook_url):
                print("2. 📋 Verificando webhooks existentes...")
                existing = configurator.list_webhooks()
                
                if existing:
                    print("\n⚠️  Webhooks existentes encontrados!")
                    print("Deseja deletar os antigos e criar um novo? (y/n)")
                    if input().lower() == 'y':
                        for webhook in existing:
                            configurator.delete_webhook(webhook['id'])
                        
                        print("3. 🔗 Criando novo webhook...")
                        webhook_id = configurator.create_webhook(webhook_url)
                        if webhook_id:
                            print(f"\n🎉 Setup completo!")
                            print(f"   🔗 URL: {webhook_url}")
                            print(f"   🆔 ID: {webhook_id}")
                else:
                    print("3. 🔗 Criando webhook...")
                    webhook_id = configurator.create_webhook(webhook_url)
                    if webhook_id:
                        print(f"\n🎉 Setup completo!")
                        print(f"   🔗 URL: {webhook_url}")
                        print(f"   🆔 ID: {webhook_id}")
            else:
                print("❌ URL não está respondendo. Verifique se:")
                print("   - O domínio está configurado corretamente")
                print("   - O servidor está rodando")
                print("   - O SSL está ativo")
                print("   - O firewall permite conexões na porta 443")
                
        elif choice == "0":
            print("👋 Saindo...")
            break
        else:
            print("❌ Opção inválida!")

if __name__ == "__main__":
    main()