#!/usr/bin/env python3
"""
Script para iniciar a API FastAPI
"""
import uvicorn

if __name__ == "__main__":
    print("🚀 Iniciando LiveBs API...")
    print("📡 URL: http://localhost:8001")
    print("📚 Docs: http://localhost:8001/docs")
    print("🔗 Webhook: http://localhost:8001/webhook/mercadopago")
    print("=" * 50)
    
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8001,
        reload=True,
        reload_dirs=["app"]
    )