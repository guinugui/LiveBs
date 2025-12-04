#!/usr/bin/env python3
"""
Configuração rápida de túnel HTTPS com ngrok para webhooks do Mercado Pago
"""

import subprocess
import sys
import json
import time
import requests

def download_ngrok():
    """Download do ngrok se não existir"""
    import urllib.request
    import zipfile
    
    ngrok_url = "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip"
    
    print("📥 Baixando ngrok...")
    urllib.request.urlretrieve(ngrok_url, "ngrok.zip")
    
    print("📦 Extraindo ngrok...")
    with zipfile.ZipFile("ngrok.zip", 'r') as zip_ref:
        zip_ref.extractall()
    
    print("✅ ngrok baixado!")

def setup_ngrok_tunnel(port=8001):
    """Configura túnel ngrok para a porta especificada"""
    
    # Verificar se ngrok existe
    try:
        subprocess.run(["ngrok", "--version"], check=True, capture_output=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ ngrok não encontrado, baixando...")
        download_ngrok()
    
    print(f"🌐 Criando túnel HTTPS para porta {port}...")
    print("⏳ Aguarde alguns segundos...")
    
    # Iniciar túnel ngrok em background
    process = subprocess.Popen(
        ["ngrok", "http", str(port)],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    
    # Aguardar ngrok inicializar
    time.sleep(3)
    
    try:
        # Obter URL do túnel
        response = requests.get("http://localhost:4040/api/tunnels")
        tunnels = response.json()["tunnels"]
        
        if tunnels:
            https_url = None
            for tunnel in tunnels:
                if tunnel["proto"] == "https":
                    https_url = tunnel["public_url"]
                    break
            
            if https_url:
                print("🎉 TÚNEL HTTPS CRIADO!")
                print("=" * 50)
                print(f"🔒 URL Pública: {https_url}")
                print(f"🔗 Webhook URL: {https_url}/webhook/mercadopago")
                print(f"📚 Docs: {https_url}/docs")
                print("=" * 50)
                print("💡 Use esta URL no Mercado Pago para webhooks")
                print("🛑 Pressione Ctrl+C para parar")
                
                # Manter processo rodando
                try:
                    process.wait()
                except KeyboardInterrupt:
                    print("\n👋 Túnel encerrado")
                    process.terminate()
            else:
                print("❌ Não foi possível obter URL HTTPS")
        else:
            print("❌ Nenhum túnel encontrado")
            
    except requests.RequestException:
        print("❌ Erro ao conectar com ngrok API")
    except Exception as e:
        print(f"❌ Erro: {e}")

def main():
    """Função principal"""
    print("🚀 CONFIGURADOR DE TÚNEL HTTPS")
    print("=" * 40)
    
    port = input("🔌 Porta do servidor local (padrão: 8001): ").strip()
    if not port:
        port = 8001
    else:
        try:
            port = int(port)
        except ValueError:
            print("❌ Porta inválida, usando 8001")
            port = 8001
    
    print(f"🔧 Configurando túnel para porta {port}...")
    print("💡 Certifique-se que sua API está rodando na porta especificada")
    print()
    
    setup_ngrok_tunnel(port)

if __name__ == "__main__":
    main()