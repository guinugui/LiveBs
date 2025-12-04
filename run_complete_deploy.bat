@echo off
echo 🚀 EXECUTANDO DEPLOY COMPLETO NO VPS...
echo ======================================

echo [STEP] Enviando script completo...
scp complete_deploy.sh root@69.166.236.73:/tmp/

echo [STEP] Executando deploy no VPS...
ssh root@69.166.236.73 "chmod +x /tmp/complete_deploy.sh && /tmp/complete_deploy.sh"

echo.
echo 🎯 COMANDOS ÚTEIS PARA O VPS:
echo =============================
echo Verificar logs: ssh root@69.166.236.73 "journalctl -u livebs-api -f"
echo Reiniciar API: ssh root@69.166.236.73 "systemctl restart livebs-api"
echo Ver containers: ssh root@69.166.236.73 "docker ps"
echo Status geral: ssh root@69.166.236.73 "systemctl status livebs-api"
echo.
pause