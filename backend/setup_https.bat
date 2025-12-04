@echo off
echo 🚀 CONFIGURAÇÃO RÁPIDA DE HTTPS PARA WEBHOOKS
echo =============================================
echo.
echo 1. OPÇÃO 1: HTTPS Local (self-signed)
echo    - Gera certificados SSL locais
echo    - Ideal para desenvolvimento
echo    - URL: https://localhost:8443
echo.
echo 2. OPÇÃO 2: Túnel Público (ngrok)
echo    - Cria URL pública HTTPS
echo    - Ideal para webhooks Mercado Pago
echo    - URL: https://random.ngrok.io
echo.
set /p choice="Escolha (1 ou 2): "

if "%choice%"=="1" (
    echo.
    echo 🔐 Configurando HTTPS Local...
    echo =============================
    echo.
    echo Passo 1: Gerando certificados SSL...
    python generate_cert.py
    echo.
    echo Passo 2: Iniciando servidor HTTPS...
    python run_https.py
) else if "%choice%"=="2" (
    echo.
    echo 🌐 Configurando Túnel Público...
    echo ===============================
    echo.
    echo Passo 1: Primeiro inicie sua API:
    echo python -m uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload
    echo.
    echo Passo 2: Em outro terminal, execute:
    echo python setup_tunnel.py
    echo.
    pause
    python setup_tunnel.py
) else (
    echo ❌ Opção inválida
    pause
)

echo.
echo 📝 PRÓXIMOS PASSOS:
echo ==================
echo 1. Teste o endpoint: /webhook/mercadopago
echo 2. Configure a URL no Mercado Pago
echo 3. Monitore os logs para debug
echo.
pause