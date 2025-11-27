@echo off
title Backend - API Server
cd /d "C:\dev\nutri_ai_project\backend"
echo 🚀 Iniciando Backend API Server...
echo 📍 Servidor rodara em: http://192.168.0.85:8000
echo ⚡ Hot reload ativo - modificacoes serao detectadas automaticamente
echo.
python -m uvicorn app.main:app --reload --host 192.168.0.85 --port 8000
pause