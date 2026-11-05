@echo off
setlocal
chcp 65001 >nul
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0ejecutar_demo.ps1" -Accion comparar
set "demo_exit=%errorlevel%"
if not "%demo_exit%"=="0" echo La demostracion no paso. Revise el diagnostico anterior.
if not defined DEMO_SIN_PAUSA pause
exit /b %demo_exit%
