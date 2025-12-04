@echo off
echo Fazendo commit da correção...
git add .
git commit -m "Fix asyncpg typo in requirements.txt"
git push

echo.
echo Correção commitada e enviada para o repositório!
echo.
echo Para aplicar no VPS, execute:
echo ssh root@69.166.236.73
echo cd /home/livebs/LiveBs
echo git pull
echo ./deploy_ubuntu.sh
pause