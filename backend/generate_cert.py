#!/usr/bin/env python3
"""
Gerador de certificado SSL self-signed para desenvolvimento/teste
"""

import subprocess
import os
import sys

def generate_self_signed_cert():
    """Gera certificado SSL self-signed"""
    
    # Criar diretório ssl se não existir
    ssl_dir = "ssl"
    if not os.path.exists(ssl_dir):
        os.makedirs(ssl_dir)
    
    cert_file = os.path.join(ssl_dir, "server.crt")
    key_file = os.path.join(ssl_dir, "server.key")
    
    # Comando OpenSSL para gerar certificado
    cmd = [
        "openssl", "req", "-x509", "-newkey", "rsa:4096",
        "-keyout", key_file,
        "-out", cert_file,
        "-days", "365", "-nodes",
        "-subj", "/C=BR/ST=SP/L=SaoPaulo/O=LiveBs/OU=Dev/CN=localhost"
    ]
    
    try:
        print("🔐 Gerando certificado SSL...")
        subprocess.run(cmd, check=True, capture_output=True)
        print(f"✅ Certificado criado: {cert_file}")
        print(f"✅ Chave criada: {key_file}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Erro ao gerar certificado: {e}")
        print("💡 Instale OpenSSL: https://slproweb.com/products/Win32OpenSSL.html")
        return False
    except FileNotFoundError:
        print("❌ OpenSSL não encontrado!")
        print("💡 Instale OpenSSL: https://slproweb.com/products/Win32OpenSSL.html")
        return False

if __name__ == "__main__":
    if generate_self_signed_cert():
        print("\n🚀 Para usar HTTPS, execute:")
        print("python run_https.py")
    else:
        print("\n❌ Falha ao gerar certificado SSL")