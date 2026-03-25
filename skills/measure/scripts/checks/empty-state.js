// empty-state.js — Detect empty/blank states with no user guidance
// Usage: pass contents to browser_evaluate. Returns structured results.
(() => {
  const body = document.body;
  const text = (body.innerText || '').trim();
  const visibleElements = document.querySelectorAll('h1, h2, h3, p, button, a, img');
  let visibleCount = 0;
  for (const el of visibleElements) {
    const r = el.getBoundingClientRect();
    if (r.width > 0 && r.height > 0 && r.top < window.innerHeight) visibleCount++;
  }
  const hasCTA = !!document.querySelector('button, a[href], [role="button"]');
  const hasGuidance = text.length > 100;
  const suspectedEmpty = visibleCount < 3 && text.length < 200;
  const emptyPhrases = ['no data', 'no results', 'nothing here', 'empty', 'get started', 'no items'];
  const hasEmptyPhrase = emptyPhrases.some(p => text.toLowerCase().includes(p));
  return {
    check: 'empty-state',
    pass: !suspectedEmpty || (suspectedEmpty && hasCTA && hasGuidance),
    suspectedEmpty,
    visibleElements: visibleCount,
    textLength: text.length,
    hasCTA,
    hasGuidance,
    hasEmptyPhrase,
    sample: text.slice(0, 200)
  };
})()
