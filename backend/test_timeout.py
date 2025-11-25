#!/usr/bin/env python3
# Teste de timeout e performance dos servicos IA
import time
import json
import requests
from datetime import datetime

def test_ai_service_timeout():
    """Testa o ai_service com timeout controle"""
    
    print("=== TESTE DE TIMEOUT AI SERVICE ===")
    
    # 1. Teste direto da funcao
    print("\n1. TESTE DIRETO DA FUNCAO:")
    try:
        import sys
        sys.path.append(r'C:\Users\guilh\OneDrive\Desktop\APP Emagrecimento\backend')
        
        # Carregar .env
        import os
        env_file = r"C:\Users\guilh\OneDrive\Desktop\APP Emagrecimento\backend\.env"
        with open(env_file, 'r') as f:
            for line in f:
                if '=' in line and not line.startswith('#'):
                    key, value = line.strip().split('=', 1)
                    os.environ[key] = value
        
        from app.ai_service import generate_meal_plan
        
        # Perfil simples para teste rapido
        profile = {
            'weight': 70, 'height': 170, 'age': 25, 'target_weight': 65,
            'activity_level': 'moderate', 'daily_calories': 1800,
            'dietary_restrictions': [], 'dietary_preferences': []
        }
        
        print("[INFO] Iniciando geracao de plano (pode demorar 10-30 segundos)...")
        start_time = time.time()
        
        meal_plan = generate_meal_plan(profile)
        
        end_time = time.time()
        duration = end_time - start_time
        
        print(f"[OK] Plano gerado em {duration:.2f} segundos")
        print(f"[OK] Estrutura: {len(meal_plan.get('days', []))} dias")
        
        if duration > 30:
            print(f"[WARNING] Tempo muito alto: {duration:.2f}s (pode causar timeout no app)")
        else:
            print(f"[OK] Tempo aceitavel: {duration:.2f}s")
            
        return True, duration
        
    except Exception as e:
        print(f"[ERRO] Falha no teste direto: {e}")
        return False, 0

def test_backend_api():
    """Testa o endpoint da API REST"""
    
    print("\n2. TESTE API BACKEND (se estiver rodando):")
    
    # URLs de teste
    base_url = "http://localhost:8000"
    
    try:
        # Teste de saude
        response = requests.get(f"{base_url}/", timeout=5)
        print(f"[OK] Backend respondendo: {response.status_code}")
        
        # Teste de meal plan (precisa de autenticacao)
        # Este teste vai falhar sem token, mas mostra se o endpoint existe
        try:
            response = requests.post(
                f"{base_url}/meal-plans/", 
                json={}, 
                timeout=30  # Timeout maior para meal plan
            )
            print(f"[INFO] Endpoint meal-plans responde: {response.status_code}")
        except requests.exceptions.Timeout:
            print("[WARNING] Timeout no endpoint meal-plans (>30s)")
        except requests.exceptions.RequestException as e:
            print(f"[INFO] Endpoint meal-plans existe mas precisa auth: {type(e).__name__}")
        
    except requests.exceptions.ConnectionError:
        print("[INFO] Backend nao esta rodando (normal se nao iniciado)")
    except Exception as e:
        print(f"[ERRO] Erro no teste API: {e}")

def check_network_config():
    """Verifica configuracoes de rede"""
    
    print("\n3. VERIFICACAO DE CONFIGURACAO:")
    
    try:
        # Teste de conectividade com OpenAI
        response = requests.get("https://api.openai.com/", timeout=5)
        print(f"[OK] Conectividade OpenAI: {response.status_code}")
    except Exception as e:
        print(f"[WARNING] Problema conectividade OpenAI: {e}")
    
    # Verificar configuracao de timeout do Flutter
    print("\n[INFO] DICAS PARA RESOLVER TIMEOUT NO FLUTTER:")
    print("1. Aumentar timeout no Dio (Flutter):")
    print("   dio.options.receiveTimeout = Duration(seconds: 60);")
    print("2. Verificar se backend esta rodando na porta 8000")
    print("3. Testar em emulador Android/iOS vs dispositivo fisico")
    print("4. Verificar firewall/antivirus bloqueando conexao")

if __name__ == "__main__":
    print("DIAGNOSTICO DE TIMEOUT - LIVEBS AI")
    print("=" * 50)
    
    # Executar testes
    success, duration = test_ai_service_timeout()
    test_backend_api()
    check_network_config()
    
    print("\n" + "=" * 50)
    print("RESUMO DO DIAGNOSTICO:")
    
    if success:
        if duration > 30:
            print("🔶 AI Service funciona mas e LENTO (pode causar timeout)")
            print("   Solucao: Aumentar timeout no Flutter ou otimizar prompts")
        else:
            print("✅ AI Service funciona em tempo adequado")
            print("   Problema pode ser configuracao de rede Flutter<->Backend")
    else:
        print("❌ AI Service com problemas - verificar logs acima")
    
    print("\nProximos passos:")
    print("1. Se AI Service lento: otimizar prompts ou usar GPT-3.5-turbo")
    print("2. Se rede: verificar configuracao Dio no Flutter") 
    print("3. Testar com backend rodando na porta 8000")