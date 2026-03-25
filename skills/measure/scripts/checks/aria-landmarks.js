// aria-landmarks.js — Check for semantic landmarks (main, nav, header, footer)
// Usage: pass contents to browser_evaluate. Returns structured results.
(() => {
  const landmarks = {
    main: !!document.querySelector('main, [role="main"]'),
    nav: !!document.querySelector('nav, [role="navigation"]'),
    header: !!document.querySelector('header, [role="banner"]'),
    footer: !!document.querySelector('footer, [role="contentinfo"]')
  };
  const missing = Object.entries(landmarks).filter(([, v]) => !v).map(([k]) => k);
  return { check: 'aria-landmarks', pass: missing.length === 0, landmarks, missing };
})()
