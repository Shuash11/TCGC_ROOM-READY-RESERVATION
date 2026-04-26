const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const size = 1024;
const center = size / 2;

async function generateIcon() {
    const svg = `
    <svg width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg">
        <defs>
            <linearGradient id="bgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style="stop-color:#1E88E5;stop-opacity:1" />
                <stop offset="100%" style="stop-color:#1565C0;stop-opacity:1" />
            </linearGradient>
        </defs>
        
        <rect width="${size}" height="${size}" rx="180" fill="url(#bgGrad)"/>
        
        <rect x="280" y="180" width="464" height="80" rx="12" fill="white" opacity="0.95"/>
        <rect x="280" y="340" width="464" height="80" rx="12" fill="white" opacity="0.95"/>
        <rect x="280" y="500" width="320" height="80" rx="12" fill="white" opacity="0.95"/>
        
        <rect x="280" y="660" width="464" height="80" rx="12" fill="white" opacity="0.95"/>
        <rect x="280" y="820" width="280" height="80" rx="12" fill="white" opacity="0.95"/>
        
        <circle cx="${center}" cy="${center}" r="120" fill="white" opacity="0.2"/>
        <path d="M${center-60},${center-40} L${center+80},${center-40} M${center-60},${center+20} L${center+80},${center+20} M${center-60},${center+80} L${center+20},${center+80}" 
              stroke="white" stroke-width="24" stroke-linecap="round" fill="none"/>
    </svg>`;

    const svgBuffer = Buffer.from(svg);
    
    const outputDir = path.join(__dirname, 'assets', 'icon');
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }
    
    await sharp(svgBuffer)
        .resize(1024, 1024)
        .png()
        .toFile(path.join(outputDir, 'app_icon.png'));
    
    console.log('Created app_icon.png');
    
    await sharp(svgBuffer)
        .resize(1024, 1024)
        .png()
        .toFile(path.join(outputDir, 'app_icon_foreground.png'));
    
    console.log('Created app_icon_foreground.png');
    
    const sizes = [192, 144, 96, 72, 48, 36];
    const density = 72;
    
    for (const s of sizes) {
        await sharp(svgBuffer)
            .resize(s, s)
            .png()
            .toFile(path.join(outputDir, `app_icon_${s}.png`));
    }
    
    console.log('All icons generated!');
}

generateIcon().catch(console.error);