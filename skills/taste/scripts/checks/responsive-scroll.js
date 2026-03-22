// responsive-scroll.js — Check for horizontal scroll overflow
// Usage: pass contents to browser_evaluate AFTER resizing viewport. Returns structured results.
(() => {
  const docWidth = document.documentElement.scrollWidth;
  const viewWidth = document.documentElement.clientWidth;
  const hasHorizontalScroll = docWidth > viewWidth;
  const bodyFontSize = parseFloat(getComputedStyle(document.body).fontSize);
  const navElement = document.querySelector('nav, [role="navigation"]');
  const navVisible = navElement ? navElement.getBoundingClientRect().height > 0 : false;
  const hamburger = document.querySelector('[aria-label*="menu"], [aria-label*="Menu"], .hamburger, .menu-toggle, button[aria-expanded]');
  return {
    check: 'responsive',
    pass: !hasHorizontalScroll,
    viewportWidth: viewWidth,
    scrollWidth: docWidth,
    horizontalOverflow: hasHorizontalScroll ? docWidth - viewWidth : 0,
    bodyFontSize,
    navVisible,
    hasHamburger: !!hamburger
  };
})()
