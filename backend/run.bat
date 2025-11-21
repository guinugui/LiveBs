@echo off
echo Instalando dependencias...
pip install -r requirements.txt

echo.
echo Iniciando servidor LiveBs API...
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
