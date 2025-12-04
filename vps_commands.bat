@echo off
echo 🔧 COMANDOS PARA EXECUTAR NO VPS
echo ===============================
echo.
echo Copie e execute estes comandos no SSH do VPS:
echo.
echo # 1. Navegar para o diretório do projeto
echo cd /home/livebs/LiveBs
echo.
echo # 2. Verificar status e fazer pull
echo git status
echo git pull
echo.
echo # 3. Parar PostgreSQL do sistema
echo sudo systemctl stop postgresql
echo.
echo # 4. Continuar o deploy
echo ./deploy_ubuntu.sh
echo.
echo ========================================
echo Pressione qualquer tecla para continuar...
pause >nul
echo.
echo Alternativa: Script automático
echo =============================
echo Ou cole este comando completo:
echo.
echo cd /home/livebs/LiveBs ^&^& git pull ^&^& sudo systemctl stop postgresql ^&^& ./deploy_ubuntu.sh
echo.
pause