# ==============================================================================
# CONFIGURACIÓN DEL BOT DE TELEGRAM (Pon tus datos aquí)
# ==============================================================================
$Token  = "8935867266:AAELjvUiJRXauSgYmmHAMmut-SOJWXyYImg" # Tu TOKEN real completo aquí
$ChatID = "1018796719"                                    # Tu ChatID numérico real aquí


$URL    = "https://telegram.org"
$MiPC   = $env:COMPUTERNAME
$User   = $env:USERNAME

Write-Host "Iniciando prueba de conexión forzada a Telegram..." -ForegroundColor Cyan

# Habilitar protocolos TLS 1.2 obligatorios
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Intentar el envío SIN bloques TRY/CATCH para que muestre el error en rojo si falla
$MensajeInicio = "🚀 PRUEBA DIRECTA: $User@$MiPC"

Invoke-RestMethod -Uri "$URL/sendMessage" -Method Post -Body @{ chat_id = $ChatID; text = $MensajeInicio }

Write-Host "`n[+] Si ves esto y te llegó el mensaje, la conexión fue exitosa." -ForegroundColor Green
