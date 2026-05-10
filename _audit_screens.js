const fs = require('fs');
const path = require('path');

const projectRoot = 'c:/Users/Os/.gemini/antigravity/scratch/InmuFacil_Project/frontend/lib/presentation/screens';
const esJsonPath = 'c:/Users/Os/.gemini/antigravity/scratch/InmuFacil_Project/frontend/assets/translations/es-ES.json';

const dirs = ['offers', 'arras', 'chat', 'solvency', 'profile', 'visits'];

let esJson = {};
if (fs.existsSync(esJsonPath)) {
  let content = fs.readFileSync(esJsonPath, 'utf8');
  if (content.charCodeAt(0) === 0xFEFF) content = content.slice(1);
  esJson = JSON.parse(content);
}

function getNested(obj, key) {
  return key.split('.').reduce((o, k) => (o || {})[k], obj);
}

const missingKeys = new Set();
const hardcodedStrings = [];

function scanDir(dir) {
  const fullPath = path.join(projectRoot, dir);
  if (!fs.existsSync(fullPath)) return;

  const files = fs.readdirSync(fullPath);
  for (const file of files) {
    const filePath = path.join(fullPath, file);
    if (fs.statSync(filePath).isDirectory()) {
      scanDir(path.join(dir, file));
      continue;
    }
    if (!file.endsWith('.dart')) continue;

    const content = fs.readFileSync(filePath, 'utf8');
    
    // Find .tr()
    const trRegex = /'([^']+)'\.tr\(/g;
    let match;
    while ((match = trRegex.exec(content)) !== null) {
      const key = match[1];
      if (!getNested(esJson, key)) {
        missingKeys.add(key);
      }
    }

    // Look for hardcoded strings in Text()
    const textRegex = /Text\(\s*'([^']+)'\s*[,)]/g;
    while ((match = textRegex.exec(content)) !== null) {
      const str = match[1];
      if (str.length > 2 && !str.includes('$') && !str.includes('.tr')) {
        hardcodedStrings.push({ file, str });
      }
    }
  }
}

dirs.forEach(scanDir);

console.log("--- MISSING KEYS ---");
Array.from(missingKeys).sort().forEach(k => console.log(k));

console.log("\n--- POTENTIAL HARDCODED STRINGS ---");
hardcodedStrings.forEach(s => console.log(`[${s.file}] ${s.str}`));
