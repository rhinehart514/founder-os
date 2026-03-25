// form-labels.js — Find form inputs without associated labels
// Usage: pass contents to browser_evaluate. Returns structured results.
(() => {
  const inputs = document.querySelectorAll('input, select, textarea');
  const unlabeled = [];
  let total = 0;
  for (const inp of inputs) {
    if (inp.type === 'hidden' || inp.type === 'submit') continue;
    total++;
    const id = inp.id;
    const hasLabel = id && document.querySelector(`label[for="${id}"]`);
    const hasAriaLabel = inp.getAttribute('aria-label');
    const hasAriaLabelledby = inp.getAttribute('aria-labelledby');
    const wrappedInLabel = inp.closest('label');
    if (!hasLabel && !hasAriaLabel && !hasAriaLabelledby && !wrappedInLabel) {
      unlabeled.push({
        tag: inp.tagName.toLowerCase(),
        type: inp.type || 'text',
        name: inp.name || '',
        placeholder: inp.placeholder || '',
        selector: inp.id ? `#${inp.id}` : inp.name ? `[name="${inp.name}"]` : inp.tagName.toLowerCase()
      });
    }
  }
  return { check: 'form-labels', pass: unlabeled.length === 0, total, unlabeled: unlabeled.length, examples: unlabeled.slice(0, 8) };
})()
