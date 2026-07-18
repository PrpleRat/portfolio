# Genere expo-qr.html avec la bonne URL LAN pour Expo Go
param(
    [string]$Port = "8081"
)

$ip = (
    Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object {
        $_.IPAddress -notlike '127.*' -and
        $_.IPAddress -notlike '169.254.*' -and
        $_.PrefixOrigin -ne 'WellKnown'
    } |
    Sort-Object { if ($_.IPAddress -like '192.168.*') { 0 } elseif ($_.IPAddress -like '10.*') { 1 } else { 2 } } |
    Select-Object -First 1 -ExpandProperty IPAddress
)

if (-not $ip) {
    $ip = '192.168.1.17'
    Write-Warning "IP locale introuvable, fallback $ip"
}

$expUrl = "exp://${ip}:${Port}"
$goUrl = "https://expo.dev/go?url=" + [uri]::EscapeDataString($expUrl)
$qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=320x320&data=" + [uri]::EscapeDataString($expUrl)

$html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Photo Space Cleaner — Expo Go</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #0a0a0f; color: #f5f5f7; display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 100vh; margin: 0; padding: 24px; text-align: center; }
    h1 { font-size: 1.5rem; margin-bottom: 8px; }
    .badge { background: #0a84ff33; color: #0a84ff; padding: 6px 12px; border-radius: 8px; font-size: 13px; font-weight: 700; margin-bottom: 12px; }
    p { color: #8e8e9a; max-width: 440px; line-height: 1.6; }
    img { margin: 20px 0; border-radius: 16px; background: white; padding: 16px; }
    code { background: #1e1e2a; padding: 10px 14px; border-radius: 10px; display: inline-block; margin: 12px 0; font-size: 13px; word-break: break-all; }
    a { color: #0a84ff; font-weight: 600; text-decoration: none; margin-top: 12px; display: inline-block; }
    .warn { color: #ffd60a; font-size: 13px; margin-top: 16px; max-width: 400px; }
  </style>
</head>
<body>
  <h1>Photo Space Cleaner</h1>
  <div class="badge">LAN · iPhone sur le meme Wi-Fi</div>
  <p>Scanne ce QR avec <strong>Expo Go</strong> ou l'appareil photo de l'iPhone.</p>
  <img src="$qrUrl" alt="QR Code" width="320" height="320" />
  <code>$expUrl</code>
  <p><a href="$goUrl">Ouvrir dans Expo Go</a></p>
  <p class="warn">PC : $ip · Port $Port<br/>Si ca ne marche pas : desactive le VPN, meme Wi-Fi, autorise Node.js dans le pare-feu Windows.</p>
</body>
</html>
"@

$outPath = Join-Path $PSScriptRoot "..\expo-qr.html"
$html | Out-File -FilePath $outPath -Encoding utf8

Write-Host "QR genere : $expUrl"
Write-Output $ip
