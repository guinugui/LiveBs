@echo off
echo ========================================
echo   INICIALIZANDO REPOSITORIO GIT
echo ========================================

echo.
echo [1/5] Inicializando Git...
git init

echo.
echo [2/5] Adicionando arquivos...
git add .

echo.
echo [3/5] Fazendo commit inicial...
git commit -m "Initial commit: LiveBs app com Flutter e FastAPI - Flutter app completo com 8 paginas - Backend FastAPI com PostgreSQL - Autenticacao JWT - Integracao OpenAI - 10 tabelas no banco de dados - API REST completa - Tema verde e branco"

echo.
echo [4/5] Conectando ao GitHub...
git remote add origin https://github.com/guinugui/LiveBs.git
git branch -M main

echo.
echo [5/5] Enviando para GitHub...
git push -u origin main

echo.
echo ========================================
echo   PUSH CONCLUIDO COM SUCESSO!
echo ========================================
echo.
echo Repositorio: https://github.com/guinugui/LiveBs
echo.
pause
