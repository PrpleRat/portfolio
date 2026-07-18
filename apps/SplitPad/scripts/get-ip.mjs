import { execSync } from 'child_process';
import { networkInterfaces } from 'os';

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
    candidates.find((ip) => !ip.startsWith('169.254.')) ??
    'localhost'
  );
}

console.log(getLanIp());
