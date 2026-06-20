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

# Registrar APIs de pantalla de Windows de forma segura
try {
    $MethodDefinition = '[DllImport("user32.dll")] public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);'
    Add-Type -MemberDefinition $MethodDefinition -Name "Win32Utils" -Namespace "Win32" -ErrorAction SilentlyContinue
} catch {}

# Habilitar TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ==============================================================================
# LIMPIAR HISTORIAL ANTES DE INICIAR (Evita bucles de bloqueo)
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
    $MensajeInicio = "🚀 *PC En Linea y Protegida:* `"$User@$MiPC`""
    [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $MensajeInicio; parse_mode = "Markdown" })
} catch {}

# ==============================================================================
# BUCLE PRINCIPAL DE MONITOREO SEGURO INTERACTIVO
# ==============================================================================
while ($true) {
    try {
        $Updates = Invoke-RestMethod -Uri "$URL/getUpdates?offset=$LastUpdateID&timeout=15" -Method Get
        
        foreach ($Update in $Updates.result) {
            $LastUpdateID = $Update.update_id + 1
            $TextoRecibido = $Update.message.text
            $RemitenteChatID = $Update.message.chat.id

            if ($RemitenteChatID -eq $ChatID -and $null -ne $TextoRecibido) {
                
                # Procesamiento seguro de comandos
                $Partes = $TextoRecibido -split " "
                $Comando = ([string]$Partes[0]).ToLower()
                
                # Seguro anti-accidentes (Requiere obligatoriamente el nombre de la PC)
                $Destino = ""
                if ($Partes.Count -gt 1) {
                    $Destino = ([string]$Partes[1]).ToUpper()
                }

                # --- COMANDO GLOBAL MODIFICADO: /lista ---
                if ($Comando -eq "/lista") {
                    # Al envolver el nombre de la PC entre acentos graves, Telegram lo vuelve "Tocado para Copiar"
                    $RespuestaLista = "🖥️ *PC Activa:* `"$User`"`n" +
                                      "📋 Nombre para copiar (Tócalo):`n" +
                                      "`$MiPC`"
                    
                    [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $RespuestaLista; parse_mode = "Markdown" })
                    continue
                }

                # --- COMANDO GLOBAL MODIFICADO: /codigo ---
                if ($Comando -eq "/ayuda") {
                    # Enviamos comandos pre-armados en modo "copiar con un toque" para que solo tengas que pegar el nombre al final
                    $TextoAyuda = "📖 *PLANTILLAS DE CONTROL REMOTO*`n" +
                                  "_(Toca el comando azul para copiarlo, pégalo, deja un espacio y pega el nombre de la PC)_`n`n" +
                                  "🔒 *Comandos disponibles:*`n" +
                                  "• `/pantalla_off` ` `n" +
                                  "• `/pantalla_on` ` `n" +
                                  "• `/notepad` ` `n`n" +
                                  "💡 _Tip: Primero escribe /lista, toca el nombre de la PC para copiarlo, luego escribe /codigo, toca el comando que quieras, pégalo y agrega el nombre de la PC._"
                    
                    [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $TextoAyuda; parse_mode = "Markdown" })
                    continue
                }

                # VALIDACIÓN CRÍTICA: Solo ejecuta funciones individuales si el destino coincide con ESTA PC
                if ($Destino -eq $MiPC.ToUpper() -and $Destino -ne "") {
                    
                    switch ($Comando) {
                        "/pantalla_off" {
                            $rundll = New-Object -ComObject WScript.Shell
                            $rundll.Run("rundll32.exe user32.dll,LockWorkStation")
                            [Win32.Win32Utils]::SendMessage(-1, 0x0112, 0xF170, 2)
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Body @{ chat_id = $ChatID; text = "✅ Pantalla apagada en $MiPC" })
                        }
                        "/pantalla_on" {
                            $wsh = New-Object -ComObject WScript.Shell
                            $wsh.SendKeys("{SHIFT}")
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Body @{ chat_id = $ChatID; text = "✅ Pantalla encendida en $MiPC" })
                        }
                        "/notepad" {
                            notepad.exe
                            Start-Sleep -Milliseconds 500
                            $wsh = New-Object -ComObject WScript.Shell
                            $wsh.SendKeys("Te estoy observando por Internet... 👀")
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Body @{ chat_id = $ChatID; text = "✅ Bloc de notas abierto en $MiPC" })
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


                
