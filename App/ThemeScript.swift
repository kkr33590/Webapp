let themeJS = #"""
(function () {
  if (window.__themeLoaded) return;
  window.__themeLoaded = true;

  var css = [
    'html{-webkit-text-size-adjust:100%;touch-action:manipulation;overscroll-behavior-y:none;background:#11161f}',
    'body{-webkit-font-smoothing:antialiased;overflow-x:hidden;max-width:100vw;animation:cpfade .35s ease both}',
    '@keyframes cpfade{from{opacity:0}to{opacity:1}}',
    '*{-webkit-tap-highlight-color:transparent}',
    '::-webkit-scrollbar{display:none;width:0;height:0}',
    'img,a{-webkit-touch-callout:none}',
    'img,video{max-width:100%}',
    'input,textarea,select{font-size:16px !important}',
    'a[href*="/detail/"] img{border-radius:12px;transition:transform .2s ease,filter .2s ease}',
    'a[href*="/detail/"]:active img{transform:scale(.96);filter:brightness(.85)}',
    'a[href*="downloadApp"],a[href*="download-app"],a[href*="t.me/"]{display:none !important}'
  ].join('\n');

  var s = document.createElement('style');
  s.textContent = css;
  (document.head || document.documentElement).appendChild(s);

  // Make sure the page scales to the screen and cannot be zoomed or dragged sideways
  function fixViewport() {
    var m = document.querySelector('meta[name=viewport]');
    if (!m) {
      m = document.createElement('meta');
      m.name = 'viewport';
      (document.head || document.documentElement).appendChild(m);
    }
    m.content = 'width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no';
  }
  fixViewport();
  document.addEventListener('DOMContentLoaded', fixViewport);
})();
"""#
