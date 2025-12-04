@echo off
echo 🚀 SISTEMA DE ASSINATURA LIVEBS
echo ==============================
echo.
echo PASSO 1: Aplicar Migration
echo --------------------------
echo Executando migration no banco...
python apply_migration.py
echo.
echo PASSO 2: Reiniciar API
echo ----------------------
echo Reiniciando API com sistema de assinatura...
python start_api.py
echo.
pause