@echo off
echo 🧹 Limpando arquivos temporarios e de teste...
echo.

REM Arquivos de teste na raiz
echo 📁 Removendo arquivos de teste na raiz...
del /q test_connection.py 2>nul
del /q test_meal_api.py 2>nul

REM Arquivos de teste no backend
echo 📁 Limpando arquivos de teste do backend...
cd backend
del /q test_*.py 2>nul
del /q check_*.py 2>nul
del /q debug_*.py 2>nul
del /q simple_*.py 2>nul
del /q create_test_*.py 2>nul
del /q create_new_*.py 2>nul
del /q create_saved_*.py 2>nul
del /q create_workout_*.py 2>nul
del /q setup_*.py 2>nul
del /q update_*.py 2>nul
del /q verify_*.py 2>nul
del /q add_*.py 2>nul
del /q clear_*.py 2>nul
del /q fix_*.py 2>nul
del /q workout_*.json 2>nul

REM Limpar arquivos temporários do Flutter
cd ..\nutri_ai_app
echo 📁 Limpando cache do Flutter...
rmdir /s /q build 2>nul
rmdir /s /q .dart_tool 2>nul
rmdir /s /q temp_files 2>nul

REM Voltar para diretório raiz
cd ..

echo.
echo ✅ Limpeza concluída!
echo 📊 Arquivos mantidos:
echo   - Código fonte principal (app/, lib/)
echo   - Configurações (.env, pubspec.yaml, etc)
echo   - Scripts úteis (*.bat)
echo   - README.md
echo.
pause