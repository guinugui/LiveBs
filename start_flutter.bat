@echo off
title Flutter App - Nutri AI (Personal Virtual)
cd /d "C:\dev\nutri_ai_project\nutri_ai_app"
echo  Iniciando Flutter App com Personal Virtual...
echo  Target: emulator-5554
echo  Hot reload ativo - salve arquivos para ver mudan?as
echo  Personal Virtual funcionando na aba Progresso
echo.
flutter run -d emulator-5554
pause
