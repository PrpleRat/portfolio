import { writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const expUrl = process.argv[2];

if (!expUrl || !expUrl.startsWith('exp://')) {
  console.error('Usage: node scripts/generate-qr-page.mjs exp://xxx.exp.direct');
  process.exit(1);
}

const encoded = encodeURIComponent(expUrl);
const html = `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>SplitPad — Scanner avec Expo Go</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      min-height: 100vh; background: #0a0a0a; color: #f8f8f8;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      display: flex; flex-direction: column; align-items: center; justify-content: center;
      padding: 24px; text-align: center;
    }
    h1 { font-size: 2rem; margin-bottom: 8px; color: #a78bfa; }
    .sub { color: #888; margin-bottom: 32px; }
    .qr {
      background: #fff; padding: 16px; border-radius: 16px;
      box-shadow: 0 0 40px rgba(139,92,246,0.35);
    }
    .qr img { display: block; width: 420px; height: 420px; max-width: 90vw; max-height: 90vw; }
    .steps { margin-top: 32px; max-width: 420px; text-align: left; line-height: 1.8; color: #aaa; }
    .steps strong { color: #a78bfa; }
    .url { margin-top: 24px; font-size: 12px; color: #555; word-break: break-all; }
    .live { color: #22c55e; font-size: 13px; margin-top: 16px; }
  </style>
  <meta http-equiv="refresh" content="120" />
</head>
<body>
  <h1>SplitPad</h1>
  <p class="sub">Scanne ce QR code avec l'appareil photo ou Expo Go</p>
  <div class="qr">
    <img src="https://api.qrserver.com/v1/create-qr-code/?size=420x420&data=${encoded}" alt="QR Code Expo Go" width="420" height="420" />
  </div>
  <p class="live">● Serveur actif — ne ferme pas le terminal SplitPad</p>
  <ol class="steps">
    <li>Ouvre <strong>Expo Go</strong> sur ton iPhone</li>
    <li>Scanne le QR code ci-dessus</li>
    <li>Sur l'accueil, tape <strong>« Charger la démo »</strong> (optionnel)</li>
  </ol>
  <p class="url">${expUrl}</p>
</body>
</html>
`;

writeFileSync(join(root, 'qr-code.html'), html, 'utf8');
console.log('qr-code.html mis à jour →', expUrl);
