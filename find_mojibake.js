const fs = require('fs');
const path = require('path');

function walk(dir) {
  const results = [];
  fs.readdirSync(dir, { withFileTypes: true }).forEach(f => {
    const full = path.join(dir, f.name);
    if (f.isDirectory()) results.push(...walk(full));
    else if (f.name.endsWith('.cs')) results.push(full);
  });
  return results;
}

const files = walk('C:/BarberBooking_Salon/src');
let total = 0;

files.forEach(f => {
  const content = fs.readFileSync(f, 'utf8');
  const lines = content.split('\n');
  lines.forEach((line, i) => {
    // Check for common mojibake patterns (Arabic UTF-8 bytes misread as Latin-1)
    const hasMojibake = /[\u0627-\u064A]{2,}/.test(line) === false && 
      (line.includes('\u0637') || line.includes('\u0633') || line.includes('\u0639') || line.includes('\u0636'));
    
    // Simpler: check for specific known mojibake sequences
    const mojibakePatterns = [
      'ظ³', 'ظٹ', 'ظ…', 'ظ‡', 'ظپ', 'ط³', 'ط±', 'ط§', 'طھ', 'ط´',
      'ط·', 'ط،', 'ظ„', 'ظ‚', 'ظ†', 'ظˆ', 'ظ', 'ط£', 'ط¶',
      'ظˆط', 'ظ…ط', 'ط³ط', 'ط±ظ', 'ط§ظ', 'طھظ', 'ط´ظ'
    ];
    
    const isMojibake = mojibakePatterns.some(p => line.includes(p)) && !line.includes(' ');
    
    // Better approach: check if line has Arabic AND known mojibake sequences
    const hasKnownMojibake = line.includes('ظ³ط±ط·') || line.includes('ظٹظˆظ…') || 
      line.includes('ظ…طµط±ط­') || line.includes('ظ…ظˆط¬ظˆط¯') ||
      line.includes('ظ…ط·ظ„ظˆط¨ط©') || line.includes('ظ…ط³طھط®ط¯ظ…') ||
      line.includes('ط®ط·ط£') || line.includes('ظ…ظپط¶ظ„ط©') ||
      line.includes('طھظ…طھ') || line.includes('ظ…ط±ط§طھ') ||
      line.includes('ظ…ط´ط®طµ') || line.includes('طµظˆط±ط©') ||
      line.includes('طھط±طھظٹط¨') || line.includes('ظ†ط³ظٹط¨') ||
      line.includes('ظپظٹ') || line.includes('ظ…ظˆط¬ظˆط¯ط©') ||
      line.includes('ط§ظ„') || line.includes('ط؛ظٹط±') ||
      line.includes('ظٹط±ط¬ظ‰') || line.includes('ظ‚ظ…') ||
      line.includes('ظ…ظˆط¸ظپظٹظ†') || line.includes('ط¨ط³ط¨ط¨') ||
      line.includes('ظˆط§ظ„') || line.includes('ظ…ظ†') ||
      line.includes('ظ†ط³ظٹط¨') || line.includes('ظ…ط³طھط®ط¯ظ…') ||
      line.includes('ظ…ظˆط¬ظˆط¯') || line.includes('ظ…ط±ط§طھ') ||
      line.includes('ظ…طµط±ط­') || line.includes('ظ…ط·ظ„ظˆط¨ط©');
    
    if (hasKnownMojibake) {
      console.log(f + ':' + (i + 1) + ': ' + line.trim());
      total++;
    }
  });
});

console.log('\nTotal: ' + total + ' mojibake lines found');
