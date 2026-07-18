const CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

export function generateSplitRef(): string {
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += CHARS[Math.floor(Math.random() * CHARS.length)];
  }
  return `SPLIT-${code}`;
}
