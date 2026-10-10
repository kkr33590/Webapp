let themeJS = #"""
(function () {
  if (window.__themeLoaded) return;
  window.__themeLoaded = true;

  var css = [
    'html{-webkit-text-size-adjust:100%;touch-action:manipulation;overscroll-behavior-y:none;background:#0b0f17 !important;color-scheme:dark}',
    'body{background:#0b0f17 !important;-webkit-font-smoothing:antialiased;overflow-x:hidden;max-width:100vw;font-family:-apple-system,BlinkMacSystemFont,"SF Pro Text","Helvetica Neue",Arial,sans-serif;-webkit-user-select:none;user-select:none;animation:cpfade .35s ease both}',
    '@keyframes cpfade{from{opacity:0}to{opacity:1}}',
    '*{-webkit-tap-highlight-color:transparent}',
    '::-webkit-scrollbar{display:none;width:0;height:0}',
    'img,a{-webkit-touch-callout:none}',
    'img,video{max-width:100%}',
    'input,textarea,select{font-size:16px !important;-webkit-user-select:text;user-select:text}',
    'h1,h2,h3{font-weight:800;letter-spacing:-.015em}',
    // posters
    'a[href*="/detail/"]{scroll-snap-align:start;text-decoration:none}',
    'a[href*="/detail/"] img{border-radius:14px;box-shadow:0 8px 20px rgba(0,0,0,.4);transition:transform .2s cubic-bezier(.2,.8,.2,1),filter .2s ease}',
    'a[href*="/detail/"]:active img{transform:scale(.95);filter:brightness(.8)}',
    // website chrome that an app does not need
    '[data-cp-hidden="f"],[data-cp-hidden="d"],[data-cp-hidden="b"]{display:none !important}',
    'html:not(.cp-showhdr):not(.cp-srch) [data-cp-hidden="h"]{display:none !important}',
    'a[href*="downloadApp"],a[href*="download-app"],a[href*="t.me/"]{display:none !important}'
  ].join('\n');

  var st = document.createElement('style');
  st.textContent = css;
  (document.head || document.documentElement).appendChild(st);

  function fixViewport() {
    var m = document.querySelector('meta[name=viewport]');
    if (!m) {
      m = document.createElement('meta');
      m.name = 'viewport';
      (document.head || document.documentElement).appendChild(m);
    }
    m.content = 'width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover';
  }
  fixViewport();
  document.addEventListener('DOMContentLoaded', fixViewport);

  // Walk up from an element to the outermost wrapper that is still small enough to be the "section"
  function climb(start, maxH) {
    var e = start;
    while (e.parentElement && e.parentElement !== document.body &&
           e.parentElement !== document.documentElement &&
           e.parentElement.id !== '__nuxt') {
      var p = e.parentElement;
      if (p.querySelector('a[href*="/detail/"]')) break;
      if (p.getBoundingClientRect().height >= maxH) break;
      e = p;
    }
    return e;
  }

  function findText(re) {
    if (!document.body) return null;
    var w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, null), n;
    while ((n = w.nextNode())) {
      var t = n.nodeValue;
      if (t && t.length < 400 && re.test(t)) return n.parentElement;
    }
    return null;
  }

  function hideOnce(tag, finder, maxH) {
    if (document.querySelector('[data-cp-hidden="' + tag + '"]')) return;
    var el = finder();
    if (el) climb(el, maxH).setAttribute('data-cp-hidden', tag);
  }

  function rows() {
    document.querySelectorAll('a[href*="/detail/"]').forEach(function (a) {
      var e = a;
      for (var i = 0; i < 4 && e && e !== document.body; i++, e = e.parentElement) {
        if (e.__cp) break;
        var ox = getComputedStyle(e).overflowX;
        if (ox === 'auto' || ox === 'scroll') {
          e.__cp = 1;
          e.style.scrollSnapType = 'x proximity';
          e.style.scrollPaddingLeft = '16px';
          break;
        }
      }
    });
  }

  function run() {
    timer = null;
    if (!document.body) return;
    // top navigation bar of the website (native tab bar replaces it)
    hideOnce('h', function () { return document.querySelector('a[href$="/web/tv-series"]'); }, 200);
    // footer, promo block, download banner
    hideOnce('f', function () { return findText(/Disclaimer: All videos/); }, 500);
    hideOnce('d', function () { return findText(/^\s*Discover More\s*$/); }, 900);
    hideOnce('b', function () { return findText(/Scan QR code to download/); }, 900);
    // keep the site's own bar visible on search pages
    document.documentElement.classList.toggle('cp-srch', /search/i.test(location.pathname));
    rows();
  }

  var timer = null;
  function schedule() { if (!timer) timer = setTimeout(run, 500); }

  new MutationObserver(function (muts) {
    for (var i = 0; i < muts.length; i++) {
      var t = muts[i].target;
      if (t && t.nodeType !== 1) t = t.parentElement;
      if (t && t.closest && t.closest('.cp-root')) continue;
      schedule();
      return;
    }
  }).observe(document.documentElement, { childList: true, subtree: true });

  document.addEventListener('DOMContentLoaded', schedule);
  setInterval(run, 2500);
})();
"""#
