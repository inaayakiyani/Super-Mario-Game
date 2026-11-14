@echo off
nasm -f bin Mario.asm -o MARIO.COM
if errorlevel 1 goto failed
echo Assembly successful!
goto finished
:failed
echo Assembly failed!
:finished
pause