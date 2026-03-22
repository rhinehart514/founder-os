// heading-hierarchy.js — Verify h1 > h2 > h3 font size hierarchy
// Usage: pass contents to browser_evaluate. Returns structured results.
(() => {
  const headings = [...document.querySelectorAll('h1, h2, h3, h4, h5, h6')].map(h => ({
    tag: h.tagName,
    text: h.textContent.trim().slice(0, 60),
    size: parseFloat(getComputedStyle(h).fontSize),
    weight: parseInt(getComputedStyle(h).fontWeight)
  }));
  const h1s = headings.filter(h => h.tag === 'H1');
  const h2s = headings.filter(h => h.tag === 'H2');
  const h3s = headings.filter(h => h.tag === 'H3');
  const bodySize = parseFloat(getComputedStyle(document.body).fontSize);
  const issues = [];
  if (h1s.length === 0) issues.push('no h1 element found');
  if (h1s.length > 1) issues.push(`${h1s.length} h1 elements (should be 1)`);
  if (h1s.length > 0 && h2s.length > 0 && h1s[0].size <= h2s[0].size) {
    issues.push(`h1 (${h1s[0].size}px) not larger than h2 (${h2s[0].size}px)`);
  }
  if (h2s.length > 0 && h3s.length > 0 && h2s[0].size <= h3s[0].size) {
    issues.push(`h2 (${h2s[0].size}px) not larger than h3 (${h3s[0].size}px)`);
  }
  return { check: 'heading-hierarchy', pass: issues.length === 0, h1Count: h1s.length, bodySize, headings: headings.slice(0, 10), issues };
})()
