@echo off
echo 🚀 CONFIGURAÇÃO HTTPS PARA MERCADO PAGO
echo =====================================
echo.
echo PASSO 1: Reiniciar sua API
echo --------------------------
echo Abra um terminal e execute:
echo cd C:\dev\nutri_ai_project\backend
echo python start_api.py
echo.
echo PASSO 2: Baixar ngrok
echo ---------------------
echo 1. Acesse: https://ngrok.com/download
echo 2. Baixe o ngrok.exe 
echo 3. Coloque na pasta backend
echo.
echo PASSO 3: Criar túnel
echo -------------------
echo Em outro terminal, execute:
echo ngrok http 8001
echo.
echo PASSO 4: Copiar URL
echo ------------------
echo O ngrok vai mostrar uma URL como:
echo https://abc123.ngrok.io
echo.
echo Use esta URL no Mercado Pago:
echo https://abc123.ngrok.io/webhook/mercadopago
echo.
pause