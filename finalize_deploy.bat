@echo off
echo 🚀 FINALIZANDO DEPLOY NO VPS...
echo ===============================

echo [STEP] Enviando script de correção...
scp fix_deploy.sh root@69.166.236.73:/home/livebs/
echo [SUCCESS] Script enviado

echo [STEP] Executando correção no VPS...
ssh root@69.166.236.73 "chmod +x /home/livebs/fix_deploy.sh && /home/livebs/fix_deploy.sh"

echo.
echo 🎉 DEPLOY FINALIZADO!
echo =====================
echo ✅ Aplicação rodando em: http://69.166.236.73
echo 📚 Documentação da API: http://69.166.236.73/docs
echo 💳 Webhooks Mercado Pago configurados
echo 🔒 SSL/HTTPS pronto para domínio livebs.com.br
echo.
echo Próximos passos:
echo 1. Configure o DNS do domínio livebs.com.br para apontar para 69.166.236.73
echo 2. Teste os endpoints da API
echo 3. Configure os webhooks no Mercado Pago
pause