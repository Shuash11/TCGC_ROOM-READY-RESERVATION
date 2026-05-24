const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const S = 512;
const C = S / 2;

// ── Full icon SVG (with background squircle) ──
function createFullSvg() {
  return `<svg width="${S}" height="${S}" viewBox="0 0 ${S} ${S}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#4F46E5"/>
      <stop offset="100%" stop-color="#7C3AED"/>
    </linearGradient>
    <linearGradient id="r" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#FFFFFF"/>
      <stop offset="100%" stop-color="#DDD6FE"/>
    </linearGradient>
  </defs>
  <rect width="${S}" height="${S}" rx="112" fill="url(#bg)"/>
  <g transform="translate(${C}, ${C})">
    <!-- Stem -->
    <rect x="-66" y="-148" width="52" height="296" rx="26" fill="url(#r)"/>
    <!-- Bowl -->
    <path d="M-14 -148
             C 110 -148 158 -92 158 -20
             C 158 50 110 82 46 82
             C 18 82 -14 66 -14 42"
          fill="none" stroke="url(#r)" stroke-width="52" stroke-linecap="round"/>
    <!-- Leg -->
    <rect x="18" y="40" width="52" height="162" rx="26" transform="rotate(40, 44, 121)" fill="url(#r)"/>
  </g>
</svg>`;
}

// ── Foreground SVG (R only, transparent bg) ──
function createForegroundSvg() {
  return `<svg width="${S}" height="${S}" viewBox="0 0 ${S} ${S}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="r" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#FFFFFF"/>
      <stop offset="100%" stop-color="#DDD6FE"/>
    </linearGradient>
  </defs>
  <g transform="translate(${C}, ${C})">
    <rect x="-70" y="-156" width="56" height="312" rx="28" fill="url(#r)"/>
    <path d="M-14 -156
             C 118 -156 168 -96 168 -20
             C 168 54 118 88 50 88
             C 20 88 -14 70 -14 44"
          fill="none" stroke="url(#r)" stroke-width="56" stroke-linecap="round"/>
    <rect x="16" y="40" width="56" height="170" rx="28" transform="rotate(40, 44, 125)" fill="url(#r)"/>
  </g>
</svg>`;
}

async function generateIcon() {
  const assetDir = path.join(__dirname, 'assets', 'icon');
  if (!fs.existsSync(assetDir)) fs.mkdirSync(assetDir, { recursive: true });

  // ── Write the scalable SVG logo ──
  const svgContent = createFullSvg();
  fs.writeFileSync(path.join(assetDir, 'logo.svg'), svgContent);
  console.log('✓ Created logo.svg (scalable vector)');

  // ── Generate launcher PNG (1024px) ──
  await sharp(Buffer.from(svgContent))
    .resize(1024, 1024)
    .png()
    .toFile(path.join(assetDir, 'app_icon.png'));
  console.log('✓ Created app_icon.png (1024x1024)');

  // ── Generate foreground PNG for Android adaptive icons ──
  await sharp(Buffer.from(createForegroundSvg()))
    .resize(1024, 1024)
    .png()
    .toFile(path.join(assetDir, 'app_icon_foreground.png'));
  console.log('✓ Created app_icon_foreground.png');

  console.log('\n✅ Logo generated successfully!');
}

generateIcon().catch(console.error);
