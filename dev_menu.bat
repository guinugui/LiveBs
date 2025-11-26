@echo off
title Desenvolvimento Nutri AI
echo =========================================
echo    🥗 NUTRI AI - AMBIENTE DE DESENVOLVIMENTO
echo =========================================
echo.
echo Escolha uma opcao:
echo.
echo 1. Iniciar Backend (API Server)
echo 2. Iniciar Flutter App
echo 3. Iniciar Ambos (Backend + Flutter)
echo 4. Testar API OpenAI
echo 5. Sair
echo.
set /p opcao="Digite sua opcao (1-5): "

if "%opcao%"=="1" goto backend
if "%opcao%"=="2" goto flutter
if "%opcao%"=="3" goto ambos
if "%opcao%"=="4" goto test_api
if "%opcao%"=="5" goto sair

echo Opcao invalida!
pause
goto inicio

:backend
echo.
echo 🚀 Iniciando Backend...
start "Backend API" "%~dp0start_backend.bat"
goto fim

:flutter
echo.
echo 📱 Iniciando Flutter App...
start "Flutter App" "%~dp0start_flutter.bat"
goto fim

:ambos
echo.
echo 🚀 Iniciando Backend...
start "Backend API" "%~dp0start_backend.bat"
timeout /t 3 /nobreak > nul
echo 📱 Iniciando Flutter App...
start "Flutter App" "%~dp0start_flutter.bat"
goto fim

:test_api
echo.
echo 🧪 Testando API OpenAI...
cd /d "C:\Users\guilh\OneDrive\Desktop\APP Emagrecimento\backend"
python test_openai.py
pause
goto fim

:sair
exit

:fim
echo.
echo ✅ Aplicacao(oes) iniciada(s) em janelas separadas!
echo 💡 Dica: Use Ctrl+C nas janelas para parar os servicos
pause