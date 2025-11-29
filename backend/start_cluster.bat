@echo off
REM Script para Windows - iniciar cluster LiveBs API

echo 🚀 INICIANDO CLUSTER LIVEBS API

REM Definir portas
set PORTS=8000 8001 8002 8003
set AI_PORT=9000

echo 🔍 Verificando Redis...
redis-cli ping >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Redis não está rodando. Inicie manualmente: redis-server
    pause
    exit /b 1
)
echo ✅ Redis está rodando

echo 🧠 Iniciando microserviço de IA...
cd microservices
start "AI Service" python -m uvicorn ai_service:app --host 127.0.0.1 --port %AI_PORT%
cd ..
timeout /t 3 /nobreak >nul

echo 🌐 Iniciando instâncias da API...
for %%p in (%PORTS%) do (
    echo Porta %%p...
    start "API %%p" /min cmd /c "set API_PORT=%%p && python start_production.py"
    timeout /t 2 /nobreak >nul
)

echo 🔄 Iniciando workers Celery...
start "Celery AI" celery -A app.celery_config worker --loglevel=info --queues=ai_processing --concurrency=2
start "Celery Meal" celery -A app.celery_config worker --loglevel=info --queues=meal_planning --concurrency=2

echo.
echo ⏳ Aguardando inicialização...
timeout /t 10 /nobreak >nul

echo.
echo 📊 Verificando status...
for %%p in (%PORTS%) do (
    curl -s http://127.0.0.1:%%p/health >nul 2>&1
    if !errorlevel! equ 0 (
        echo ✅ API porta %%p: OK
    ) else (
        echo ❌ API porta %%p: FALHOU
    )
)

curl -s http://127.0.0.1:%AI_PORT%/health >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ AI Service: OK
) else (
    echo ❌ AI Service: FALHOU
)

echo.
echo 🎉 CLUSTER INICIADO!
echo.
echo 📡 Endpoints disponíveis:
echo    - API Principal: http://127.0.0.1:8000-8003
echo    - AI Service: http://127.0.0.1:9000
echo    - Health Check: http://127.0.0.1:8000/health
echo.
echo Pressione qualquer tecla para parar o cluster...
pause >nul

REM Parar processos
taskkill /f /im python.exe /fi "windowtitle eq API*" >nul 2>&1
taskkill /f /im python.exe /fi "windowtitle eq AI Service*" >nul 2>&1
taskkill /f /im python.exe /fi "windowtitle eq Celery*" >nul 2>&1

echo 🛑 Cluster parado.