// images-alt.js — Find images without alt text
// Usage: pass contents to browser_evaluate. Returns structured results.
(() => {
  const images = document.querySelectorAll('img');
  const missing = [];
  let total = 0;
  for (const img of images) {
    const r = img.getBoundingClientRect();
    if (r.width === 0 && r.height === 0) continue;
    total++;
    const alt = img.getAttribute('alt');
    if (alt === null || alt === undefined) {
      missing.push({
        src: (img.src || '').slice(-60),
        width: Math.round(r.width),
        height: Math.round(r.height),
        selector: img.id ? `#${img.id}` : img.className ? `img.${img.className.split(' ')[0]}` : 'img'
      });
    }
  }
  return { check: 'images-alt', pass: missing.length === 0, total, missing: missing.length, examples: missing.slice(0, 8) };
})()
