// click-targets.js — Find interactive elements smaller than 44x44px
// Usage: pass contents to browser_evaluate. Returns structured results.
(() => {
  const selectors = 'a, button, input, select, textarea, [role="button"], [role="link"], [tabindex]';
  const els = document.querySelectorAll(selectors);
  const undersized = [];
  let total = 0;
  for (const el of els) {
    const r = el.getBoundingClientRect();
    if (r.width === 0 && r.height === 0) continue;
    total++;
    if (r.width < 44 || r.height < 44) {
      undersized.push({
        tag: el.tagName.toLowerCase(),
        text: (el.textContent || '').trim().slice(0, 50),
        width: Math.round(r.width),
        height: Math.round(r.height),
        selector: el.id ? `#${el.id}` : el.className ? `.${el.className.split(' ')[0]}` : el.tagName.toLowerCase()
      });
    }
  }
  return { check: 'click-targets', pass: undersized.length === 0, total, undersized: undersized.length, examples: undersized.slice(0, 8) };
})()
