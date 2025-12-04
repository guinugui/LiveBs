#!/usr/bin/env python3
"""
Servidor HTTPS para desenvolvimento com FastAPI
Ideal para testar webhooks do Mercado Pago
"""

import uvicorn
import ssl
import os
from pathlib import Path

def run_https_server():
    """Executa servidor HTTPS na porta 8443"""
    
    # Caminhos dos certificados
    cert_file = "ssl/server.crt"
    key_file = "ssl/server.key"
    
    # Verificar se certificados existem
    if not os.path.exists(cert_file) or not os.path.exists(key_file):
        print("❌ Certificados SSL não encontrados!")
        print("🔧 Execute primeiro: python generate_cert.py")
        return
    
    print("🚀 INICIANDO SERVIDOR HTTPS PARA WEBHOOKS")
    print("=" * 45)
    print(f"🔒 HTTPS: https://localhost:8443")
    print(f"📚 Docs: https://localhost:8443/docs")
    print(f"🔗 Webhook URL: https://localhost:8443/webhook/mercadopago")
    print("=" * 45)
    print("⚠️  Certificado self-signed - navegador mostrará aviso")
    print("💡 Para Mercado Pago, use ngrok ou similar para URL pública")
    print("=" * 45)
    
    # Configurar SSL
    ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ssl_context.load_cert_chain(cert_file, key_file)
    
    # Executar servidor
    try:
        uvicorn.run(
            "app.main:app",
            host="0.0.0.0",
            port=8443,
            ssl_context=ssl_context,
            reload=True,
            reload_dirs=["app"]
        )
    except KeyboardInterrupt:
        print("\n👋 Servidor HTTPS encerrado")
    except Exception as e:
        print(f"❌ Erro ao iniciar servidor HTTPS: {e}")

if __name__ == "__main__":
    run_https_server()