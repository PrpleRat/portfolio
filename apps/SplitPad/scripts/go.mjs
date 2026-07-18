import { spawn, exec, execSync } from 'child_process';
import { networkInterfaces } from 'os';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import http from 'http';
import net from 'net';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
let qrGenerated = false;

const useTunnel = process.argv.includes('--tunnel');
const mode = useTunnel ? '--tunnel' : '--lan';

async function isPortInUse(port) {
  if (process.platform === 'win32') {
    try {
      const out = execSync(`netstat -ano | findstr :${port}`, {
        encoding: 'utf8',
        windowsHide: true,
      });
      return /LISTENING/i.test(out);
    } catch {
      return false;
    }
  }

  return new Promise((resolve) => {
    const server = net.createServer();
    server.once('error', () => resolve(true));
    server.once('listening', () => server.close(() => resolve(false)));
    server.listen(port, '0.0.0.0');
  });
}

async function findPort(start = 8081, maxTries = 15) {
  for (let port = start; port < start + maxTries; port++) {
    const inUse = await isPortInUse(port);
    if (!inUse) return port;
  }
  return start + maxTries - 1;
}

function freePortOnWindows(port) {
  if (process.platform !== 'win32') return;
  try {
    const out = execSync(`netstat -ano | findstr :${port}`, {
      encoding: 'utf8',
      windowsHide: true,
    });
    const pids = new Set();
    for (const line of out.split('\n')) {
      if (!/LISTENING/i.test(line)) continue;
      const pid = line.trim().split(/\s+/).pop();
      if (pid && /^\d+$/.test(pid) && pid !== '0') pids.add(pid);
    }
    for (const pid of pids) {
      try {
        execSync(`taskkill /F /PID ${pid}`, { windowsHide: true, stdio: 'ignore' });
      } catch {
        // ignore
      }
    }
  } catch {
    // port libre
  }
}

function getLanIpFromIpconfig() {
  try {
    const output = execSync('ipconfig', { encoding: 'utf8', windowsHide: true });
    const ips = [...output.matchAll(/IPv4[^:]*:\s*(\d+\.\d+\.\d+\.\d+)/gi)].map((m) => m[1]);
    return (
      ips.find((ip) => ip.startsWith('192.168.')) ??
      ips.find((ip) => ip.startsWith('10.')) ??
      ips.find((ip) => /^172\.(1[6-9]|2\d|3[01])\./.test(ip)) ??
      ips.find((ip) => !ip.startsWith('169.254.') && !ip.startsWith('127.')) ??
      null
    );
  } catch {
    return null;
  }
}

function getLanIp() {
  const fromIpconfig = getLanIpFromIpconfig();
  if (fromIpconfig) return fromIpconfig;

  const candidates = [];
  for (const ifaces of Object.values(networkInterfaces())) {
    for (const net of ifaces ?? []) {
      if (net.family !== 'IPv4' || net.internal) continue;
      candidates.push(net.address);
    }
  }

  return (
    candidates.find((ip) => ip.startsWith('192.168.')) ??
    candidates.find((ip) => ip.startsWith('10.')) ??
    candidates.find((ip) => /^172\.(1[6-9]|2\d|3[01])\./.test(ip)) ??
    candidates.find((ip) => !ip.startsWith('169.254.')) ??
    'localhost'
  );
}

function openQrPage() {
  const htmlPath = join(root, 'qr-code.html');
  const cmd =
    process.platform === 'win32'
      ? `start "" "${htmlPath}"`
      : process.platform === 'darwin'
        ? `open "${htmlPath}"`
        : `xdg-open "${htmlPath}"`;
  exec(cmd);
}

function generateQr(expUrl, port) {
  if (qrGenerated) return;
  qrGenerated = true;
  const child = spawn('node', [join(root, 'scripts', 'generate-qr-page.mjs'), expUrl], {
    cwd: root,
    stdio: 'inherit',
    shell: true,
  });
  child.on('close', () => {
    console.log(`\nScanne le QR -> ${expUrl}\n`);
    openQrPage();
    prewarmBundle(port);
  });
}

function prewarmBundle(port) {
  const path =
    `/node_modules/expo-router/entry.bundle?platform=ios&dev=true&minify=false&hot=false`;
  const req = http.get({ hostname: 'localhost', port, path, timeout: 120000 }, (res) => {
    res.resume();
    res.on('end', () => {
      if (res.statusCode === 200) {
        console.log('Bundle prechauffe - Expo Go devrait ouvrir plus vite\n');
      }
    });
  });
  req.on('error', () => {});
  req.on('timeout', () => req.destroy());
}

async function main() {
  freePortOnWindows(8081);
  await new Promise((r) => setTimeout(r, 500));

  const port = await findPort(8081);
  const lanIp = getLanIp();

  if (port !== 8081) {
    console.log(`\nPort 8081 occupe -> port ${port}\n`);
  }

  console.log(`\nSplitPad - ${useTunnel ? 'tunnel' : `LAN ${lanIp}`}\n`);

  const expo = spawn('npx', ['expo', 'start', mode, '--port', String(port)], {
    cwd: root,
    stdio: ['inherit', 'pipe', 'pipe'],
    shell: true,
    env: {
      ...process.env,
      FORCE_COLOR: '1',
      REACT_NATIVE_PACKAGER_HOSTNAME: lanIp,
    },
  });

  const urlPattern = /exp:\/\/[^\s\u001b"'<>]+/g;

  function onReady(chunk) {
    const text = chunk.toString();
    process.stdout.write(text);

    const tunnelMatch = text.match(urlPattern);
    if (tunnelMatch) {
      generateQr(tunnelMatch[tunnelMatch.length - 1].replace(/\u001b\[[0-9;]*m/g, ''), port);
      return;
    }

    if (!qrGenerated && /Waiting on|Metro Bundler/i.test(text) && !useTunnel) {
      generateQr(`exp://${lanIp}:${port}`, port);
    }
  }

  expo.stdout.on('data', onReady);
  expo.stderr.on('data', (chunk) => {
    process.stderr.write(chunk);
    const text = chunk.toString();
    const tunnelMatch = text.match(urlPattern);
    if (tunnelMatch) {
      generateQr(tunnelMatch[tunnelMatch.length - 1].replace(/\u001b\[[0-9;]*m/g, ''), port);
    }
  });

  expo.on('close', (code) => process.exit(code ?? 0));
  process.on('SIGINT', () => expo.kill('SIGINT'));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
