# Affiche le QR code Expo Go dans le navigateur
$ErrorActionPreference = "SilentlyContinue"
Set-Location $PSScriptRoot\..

$nodeDir = "C:\Program Files\nodejs"
if (Test-Path "$nodeDir\node.exe") {
    $env:Path = "$nodeDir;" + $env:Path
}

function Get-TunnelExpUrl {
    for ($i = 0; $i - 30; $i++) {
        try {
            $tunnels = (Invoke-RestMethod "http://127.0.0.1:4040/api/tunnels" -TimeoutSec 2).tunnels
            $https = ($tunnels | Where-Object { $_.public_url -like "https://*" } | Select-Object -First 1).public_url
            if ($https) {
                $host_ = ([Uri]$https).Host
                return "exp://${host_}"
            }
        } catch {}
        Start-Sleep -Seconds 2
    }
    return $null
}

function Test-ExpoRunning {
    try {
        $r = Invoke-WebRequest "http://localhost:8081/status" -UseBasicParsing -TimeoutSec 2
        return $r.StatusCode -eq 200
    } catch {
        return $false
    }
}

if (-not (Test-ExpoRunning)) {
    Write-Host "Demarrage du serveur Expo (tunnel)..." -ForegroundColor Cyan
    Start-Process cmd -ArgumentList "/k", "cd /d `"$PWD`" && set PATH=$nodeDir;%PATH% && title BeatBill - NE PAS FERMER && npx expo start --tunnel"
    Start-Sleep -Seconds 12
}

$expUrl = Get-TunnelExpUrl
if (-not $expUrl) {
    Write-Host "Tunnel pas encore pret. Attends 20s puis relance SCANNER-QR.bat" -ForegroundColor Yellow
    Read-Host "Entree pour quitter"
    exit 1
}

$qrApi = "https://api.qrserver.com/v1/create-qr-code/?size=420x420&data=" + [Uri]::EscapeDataString($expUrl)
$htmlPath = Join-Path $PWD "qr-code.html"

@"

<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>BeatBill — Scanner avec Expo Go</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      min-height: 100vh; background: #0a0a0a; color: #f8f8f8;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      display: flex; flex-direction: column; align-items: center; justify-content: center;
      padding: 24px; text-align: center;
    }
    h1 { font-size: 2rem; margin-bottom: 8px; }
    .sub { color: #888; margin-bottom: 32px; }
    .qr {
      background: #fff; padding: 16px; border-radius: 16px;
      box-shadow: 0 0 40px rgba(34,197,94,0.25);
    }
    .qr img { display: block; width: 420px; height: 420px; }
    .steps { margin-top: 32px; max-width: 420px; text-align: left; line-height: 1.8; color: #aaa; }
    .steps strong { color: #4ade80; }
    .url { margin-top: 24px; font-size: 12px; color: #555; word-break: break-all; }
    .live { color: #22c55e; font-size: 13px; margin-top: 16px; }
  </style>
  <meta http-equiv="refresh" content="60" />
</head>
<body>
  <h1>BeatBill</h1>
  <p class="sub">Scanne ce QR code avec l'appareil photo ou Expo Go</p>
  <div class="qr">
    <img src="$qrApi" alt="QR Code Expo Go" width="420" height="420" />
  </div>
  <p class="live">● Serveur actif — ne ferme pas la fenetre terminal BeatBill</p>
  <ol class="steps">
    <li>Ouvre <strong>Expo Go</strong> sur ton iPhone</li>
    <li>Scanne le QR code ci-dessus</li>
    <li>Sur l'accueil, tape <strong>« Charger la démo »</strong></li>
  </ol>
  <p class="url">$expUrl</p>
</body>
</html>
"@ | Set-Content -Path $htmlPath -Encoding UTF8

Start-Process $htmlPath
Write-Host ""
Write-Host "QR code ouvert dans le navigateur." -ForegroundColor Green
Write-Host "URL: $expUrl" -ForegroundColor DarkGray
Write-Host ""
