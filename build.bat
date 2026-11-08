@echo off
nasm -f bin Mario.asm -o MARIO.COM

if errorlevel 1 (
    echo Assembly failed!
    pause
    exit /b 1
)

echo Assembly successful!
pause