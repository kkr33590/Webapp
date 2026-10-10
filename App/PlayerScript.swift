let playerJS = #"""
(function () {
  if (window.__cpLoaded) return;
  window.__cpLoaded = true;

  // Catch hls.js players (if the site uses hls.js) so quality / audio / subtitle tracks can be controlled
  try {
    var _H;
    var wrapH = function (H) {
      if (typeof H !== 'function' || H.__cpw) return H;
      var W = function () {
        var inst = Reflect.construct(H, arguments, new.target || W);
        (window.__hlsInsts = window.__hlsInsts || []).push(inst);
        return inst;
      };
      W.prototype = H.prototype;
      Object.setPrototypeOf(W, H);
      W.__cpw = true;
      return W;
    };
    Object.defineProperty(window, 'Hls', {
      configurable: true,
      get: function () { return _H; },
      set: function (x) { _H = wrapH(x); }
    });
  } catch (e) {}

  var SPEEDS = [0.5, 0.75, 1, 1.25, 1.5, 2];
  var FITS = ['contain', 'cover', 'fill'];
  var FIT_LABELS = { contain: 'Fit', cover: 'Fill', fill: 'Stretch' };
  var SUBSIZES = [['Small', 14], ['Medium', 18], ['Large', 24], ['XL', 30]];
  var EVENTS = ['play', 'pause', 'playing', 'waiting', 'seeking', 'seeked', 'canplay',
                'progress', 'durationchange', 'volumechange', 'ratechange', 'ended', 'timeupdate'];

  var P = {
    play: 'M8 5v14l11-7z',
    pause: 'M6 5h4v14H6zm8 0h4v14h-4z',
    back: 'M12 5V1L7 6l5 5V7c3.31 0 6 2.69 6 6s-2.69 6-6 6-6-2.69-6-6H4c0 4.42 3.58 8 8 8s8-3.58 8-8-3.58-8-8-8z',
    fwd: 'M12 5V1l5 5-5 5V7c-3.31 0-6 2.69-6 6s2.69 6 6 6 6-2.69 6-6h2c0 4.42-3.58 8-8 8s-8-3.58-8-8 3.58-8 8-8z',
    vol: 'M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02z',
    mute: 'M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z',
    fs: 'M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z',
    nofs: 'M5 16h3v3h2v-5H5v2zm3-8H5v2h5V5H8v3zm6 11h2v-3h3v-2h-5v5zm2-11V5h-2v5h5V8h-3z',
    rot: 'M16.48 2.52c3.27 1.55 5.61 4.72 5.97 8.48h1.5C23.44 4.84 18.29 0 12 0l-.66.03 3.81 3.81 1.33-1.32zm-6.25-.77c-.59-.59-1.54-.59-2.12 0L1.75 8.11c-.59.59-.59 1.54 0 2.12l12.02 12.02c.59.59 1.54.59 2.12 0l6.36-6.36c.59-.59.59-1.54 0-2.12L10.23 1.75zm4.6 19.44L2.81 9.17l6.36-6.36 12.02 12.02-6.36 6.36zm-7.31.29C4.25 19.94 1.91 16.76 1.55 13H.05C.56 19.16 5.71 24 12 24l.66-.03-3.81-3.81-1.33 1.32z',
    lock: 'M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z',
    unlock: 'M12 17c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm6-9h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6h1.9c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm0 12H6V10h12v10z',
    cc: 'M19 4H5c-1.11 0-2 .9-2 2v12c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm-8 7H9.5v-.5h-2v3h2V13H11v1c0 .55-.45 1-1 1H7c-.55 0-1-.45-1-1v-4c0-.55.45-1 1-1h3c.55 0 1 .45 1 1v1zm7 0h-1.5v-.5h-2v3h2V13H18v1c0 .55-.45 1-1 1h-3c-.55 0-1-.45-1-1v-4c0-.55.45-1 1-1h3c.55 0 1 .45 1 1v1z',
    gear: 'M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z',
    check: 'M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z'
  };

  function ic(d, s) {
    s = s || 22;
    return '<svg viewBox="0 0 24 24" width="' + s + '" height="' + s + '" fill="currentColor"><path d="' + d + '"/></svg>';
  }
  function icT(d, label) {
    return '<svg viewBox="0 0 24 24" width="30" height="30" fill="currentColor"><path d="' + d + '"/>' +
      '<text x="12" y="15.2" font-size="7" font-weight="700" text-anchor="middle" fill="currentColor" ' +
      'font-family="-apple-system,Arial">' + label + '</text></svg>';
  }
  function setHTML(el, h) { if (el.__h !== h) { el.__h = h; el.innerHTML = h; } }
  function esc(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }
  function langName(c) {
    if (!c) return '';
    try {
      var n = new Intl.DisplayNames([navigator.language || 'en'], { type: 'language' }).of(c);
      return n || c;
    } catch (e) { return c; }
  }

  // ---------- state ----------
  var v = null, fs = false, dragging = false, locked = false, panelOpen = false, tab = 0;
  var uiShown = true, vis = false, rafOn = false, switching = false;
  var hideTimer = null, toastTimer = null, lockTimer = null;
  var fitIdx = 0, savedStyle = null, lastSave = 0;
  var lx = -1, ly = -1, lw = 0, lh = 0, barW = 0, lastT = -1, lastSec = -1;
  var acts = [], lastHtml = '';
  var subCur = null, subSig = '', subTouched = false, subDelay = 0, subSizeIdx = 1, subLast = '', subChk = 0;
  var masters = {}, variantMaster = {};
  try { var ss = parseInt(localStorage.getItem('cp_ssize'), 10); if (ss >= 0 && ss < SUBSIZES.length) subSizeIdx = ss; } catch (e) {}

  function post(m) {
    try { window.webkit.messageHandlers.orient.postMessage(m); } catch (e) {}
  }

  // ---------- native fetch bridge (used to read HLS master playlists without CORS limits) ----------
  var fetchCbs = {}, fetchId = 0;
  window.__cpFetchDone = function (id, text) {
    var cb = fetchCbs[id];
    delete fetchCbs[id];
    if (cb) cb(text || '');
  };
  function nativeFetch(url, cb) {
    var id = ++fetchId;
    fetchCbs[id] = cb;
    try {
      window.webkit.messageHandlers.cpfetch.postMessage({ id: id, url: url, referer: location.href });
    } catch (e) { delete fetchCbs[id]; cb(''); return; }
    setTimeout(function () {
      if (fetchCbs[id]) { delete fetchCbs[id]; cb(''); }
    }, 12000);
  }

  // ---------- styles ----------
  var css = document.createElement('style');
  css.textContent = [
    'video::-webkit-media-controls{display:none !important}',
    'video::-webkit-media-controls-enclosure{display:none !important}',
    '.cp-root{position:fixed;left:0;top:0;z-index:2147483647;display:none;overflow:hidden;will-change:transform;color:#fff;font-family:-apple-system,BlinkMacSystemFont,"Helvetica Neue",Arial,sans-serif;-webkit-user-select:none;user-select:none;-webkit-touch-callout:none}',
    '.cp-root *{box-sizing:border-box;-webkit-tap-highlight-color:transparent}',
    '.cp-root button{font-family:inherit;outline:0;margin:0;padding:0;border:0}',
    '.cp-tap{position:absolute;left:0;top:0;right:0;bottom:0;touch-action:manipulation}',
    '.cp-glass{background:rgba(10,14,20,.5);border:1px solid rgba(255,255,255,.16) !important}',
    '.cp-ui{position:absolute;left:0;top:0;right:0;bottom:0;display:flex;flex-direction:column;justify-content:space-between;pointer-events:none;transition:opacity .25s ease}',
    '.cp-ui.cp-hide,.cp-locked .cp-ui{opacity:0}',
    '.cp-ui.cp-hide *,.cp-locked .cp-ui *{pointer-events:none !important}',
    '.cp-top{display:flex;align-items:center;justify-content:space-between;gap:8px;padding:10px 12px 26px;background:linear-gradient(rgba(0,0,0,.7),rgba(0,0,0,0))}',
    '.cp-fs .cp-top{padding-top:max(10px,env(safe-area-inset-top));padding-left:max(12px,env(safe-area-inset-left));padding-right:max(12px,env(safe-area-inset-right))}',
    '.cp-title{flex:1;min-width:0;font-size:14px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;text-shadow:0 1px 4px rgba(0,0,0,.6)}',
    '.cp-tr{display:flex;gap:8px;align-items:center}',
    '.cp-btn{pointer-events:auto;display:flex;align-items:center;justify-content:center;width:38px;height:38px;border-radius:19px;color:#fff;transition:transform .15s ease,background .15s ease,color .15s}',
    '.cp-btn:active{transform:scale(.88);background:rgba(255,255,255,.28)}',
    '.cp-btn.cp-on{color:#2FF58B}',
    '.cp-mid{display:flex;align-items:center;justify-content:center;gap:30px;pointer-events:none;transition:opacity .2s}',
    '.cp-wait .cp-play{opacity:0}',
    '.cp-skip{width:48px;height:48px;border-radius:24px}',
    '.cp-play{width:70px;height:70px;border-radius:35px;transition:transform .15s ease,opacity .2s ease}',
    '.cp-play:active{transform:scale(.9)}',
    '.cp-bot{padding:18px 14px 10px;background:linear-gradient(rgba(0,0,0,0),rgba(0,0,0,.75))}',
    '.cp-fs .cp-bot{padding-left:max(14px,env(safe-area-inset-left));padding-right:max(14px,env(safe-area-inset-right));padding-bottom:max(10px,env(safe-area-inset-bottom))}',
    '.cp-bar{position:relative;height:30px;pointer-events:auto;touch-action:none;margin:0 6px}',
    '.cp-track{position:absolute;left:0;right:0;top:50%;height:4px;margin-top:-2px;border-radius:3px;background:rgba(255,255,255,.25);overflow:hidden;transition:height .15s,margin-top .15s}',
    '.cp-drag .cp-track{height:7px;margin-top:-3.5px}',
    '.cp-buf,.cp-played{position:absolute;left:0;top:0;bottom:0;width:100%;transform-origin:0 50%;transform:scaleX(0);will-change:transform}',
    '.cp-buf{background:rgba(255,255,255,.35)}',
    '.cp-played{background:linear-gradient(90deg,#1CB7FF,#2FF58B)}',
    '.cp-thumb{position:absolute;left:0;top:50%;width:14px;height:14px;margin:-7px 0 0 -7px;border-radius:50%;background:#fff;box-shadow:0 1px 6px rgba(0,0,0,.55);will-change:transform;transition:width .15s,height .15s,margin .15s}',
    '.cp-drag .cp-thumb{width:20px;height:20px;margin:-10px 0 0 -10px}',
    '.cp-tip{position:absolute;left:0;bottom:34px;padding:4px 9px;border-radius:9px;background:rgba(0,0,0,.8);font-size:12px;font-weight:600;font-variant-numeric:tabular-nums;opacity:0;transition:opacity .15s;pointer-events:none;will-change:transform}',
    '.cp-drag .cp-tip{opacity:1}',
    '.cp-row{display:flex;align-items:center;gap:6px;padding:0 6px}',
    '.cp-time{font-size:12px;font-weight:600;font-variant-numeric:tabular-nums}',
    '.cp-dim{opacity:.7}.cp-dim:before{content:"/ "}',
    '.cp-sp{flex:1}',
    '.cp-spin{position:absolute;left:50%;top:50%;width:46px;height:46px;margin:-23px 0 0 -23px;border-radius:50%;border:3px solid rgba(255,255,255,.25);border-top-color:#2FF58B;animation:cp-rot .8s linear infinite;opacity:0;transition:opacity .2s;pointer-events:none}',
    '.cp-wait .cp-spin{opacity:1}',
    '@keyframes cp-rot{to{transform:rotate(360deg)}}',
    '.cp-rip{position:absolute;top:0;bottom:0;width:36%;display:flex;align-items:center;justify-content:center;pointer-events:none;opacity:0;transition:opacity .4s;background:radial-gradient(circle at center,rgba(255,255,255,.2),rgba(255,255,255,0) 70%)}',
    '.cp-rip.cp-on{opacity:1;transition:opacity .05s}',
    '.cp-rl{left:0}.cp-rr{right:0}',
    '.cp-ripin{font-size:14px;font-weight:700;text-align:center;white-space:pre-line;line-height:1.5;text-shadow:0 1px 4px rgba(0,0,0,.6)}',
    // subtitles
    '.cp-sub{position:absolute;left:5%;right:5%;bottom:24px;text-align:center;pointer-events:none;transition:bottom .25s ease}',
    '.cp-fs .cp-sub{bottom:max(24px,env(safe-area-inset-bottom))}',
    '.cp-up .cp-sub{bottom:96px}',
    '.cp-fs.cp-up .cp-sub{bottom:calc(96px + env(safe-area-inset-bottom))}',
    '.cp-sl{display:block;line-height:1.55}',
    '.cp-st{display:inline;font-size:var(--ss,18px);font-weight:600;color:#fff;background:rgba(0,0,0,.68);padding:1px 8px;border-radius:5px;-webkit-box-decoration-break:clone;box-decoration-break:clone;text-shadow:0 1px 2px rgba(0,0,0,.8)}',
    '.cp-fs .cp-st{font-size:calc(var(--ss,18px) * 1.25)}',
    // settings panel
    '.cp-panel{position:absolute;top:56px;right:12px;width:min(310px,calc(100% - 24px));max-height:calc(100% - 120px);display:none;flex-direction:column;border-radius:18px;pointer-events:auto;overflow:hidden;background:rgba(14,18,26,.95)}',
    '.cp-fs .cp-panel{right:max(12px,env(safe-area-inset-right))}',
    '.cp-panel.cp-open{display:flex}',
    '.cp-tabs{display:flex;gap:2px;padding:8px 8px 4px;flex:none}',
    '.cp-tab{flex:1;height:32px;border-radius:16px;background:transparent;color:rgba(255,255,255,.7);font-size:12.5px;font-weight:700}',
    '.cp-tab.cp-sel{background:rgba(255,255,255,.18);color:#fff}',
    '.cp-list{overflow-y:auto;-webkit-overflow-scrolling:touch;overscroll-behavior:contain;padding:2px 8px 10px;flex:1}',
    '.cp-opt{display:flex;width:100%;align-items:center;justify-content:space-between;min-height:44px;padding:6px 12px;border-radius:12px;background:transparent;color:#fff;font-size:15px;font-weight:600;text-align:left}',
    '.cp-opt:active{background:rgba(255,255,255,.15)}',
    '.cp-opt.cp-sel{color:#2FF58B}',
    '.cp-opt small{display:block;font-size:11px;font-weight:500;opacity:.6;margin-top:1px}',
    '.cp-ck{opacity:0;display:flex}.cp-opt.cp-sel .cp-ck{opacity:1}',
    '.cp-note{padding:14px 12px;font-size:13px;line-height:1.45;opacity:.75}',
    '.cp-sec{padding:12px 12px 4px;font-size:11.5px;font-weight:700;opacity:.55;text-transform:uppercase;letter-spacing:.05em}',
    '.cp-chips{display:flex;flex-wrap:wrap;gap:6px;padding:4px 8px 6px}',
    '.cp-chip2{flex:1 0 28%;height:34px;border-radius:17px;background:rgba(255,255,255,.14);color:#fff;font-size:13px;font-weight:700}',
    '.cp-chip2:active{background:rgba(255,255,255,.28)}',
    '.cp-chip2.cp-sel{background:linear-gradient(90deg,#1CB7FF,#2FF58B);color:#08121a}',
    '.cp-unlock{position:absolute;left:50%;bottom:18%;margin-left:-24px;width:48px;height:48px;border-radius:24px;opacity:0;pointer-events:none;transition:opacity .2s}',
    '.cp-locked .cp-unlock.cp-show{opacity:1;pointer-events:auto}',
    '.cp-toast{position:absolute;top:16%;left:50%;transform:translateX(-50%);padding:8px 16px;border-radius:16px;background:rgba(10,14,20,.78);font-size:14px;font-weight:600;white-space:nowrap;opacity:0;transition:opacity .2s;pointer-events:none}',
    '.cp-toast.cp-on{opacity:1}'
  ].join('\n');
  document.documentElement.appendChild(css);

  // ---------- DOM ----------
  var root = document.createElement('div');
  root.className = 'cp-root';
  root.innerHTML =
    '<div class="cp-tap"></div>' +
    '<div class="cp-rip cp-rl"><div class="cp-ripin"></div></div>' +
    '<div class="cp-rip cp-rr"><div class="cp-ripin"></div></div>' +
    '<div class="cp-sub"></div>' +
    '<div class="cp-spin"></div>' +
    '<div class="cp-ui">' +
      '<div class="cp-top">' +
        '<div class="cp-title"></div>' +
        '<div class="cp-tr">' +
          '<button class="cp-btn cp-glass" data-a="cc"></button>' +
          '<button class="cp-btn cp-glass" data-a="gear"></button>' +
          '<button class="cp-btn cp-glass" data-a="mute"></button>' +
          '<button class="cp-btn cp-glass" data-a="rotate"></button>' +
          '<button class="cp-btn cp-glass" data-a="lock"></button>' +
        '</div>' +
      '</div>' +
      '<div class="cp-mid">' +
        '<button class="cp-btn cp-glass cp-skip" data-a="back"></button>' +
        '<button class="cp-btn cp-glass cp-play" data-a="play"></button>' +
        '<button class="cp-btn cp-glass cp-skip" data-a="fwd"></button>' +
      '</div>' +
      '<div class="cp-bot">' +
        '<div class="cp-bar">' +
          '<div class="cp-track"><div class="cp-buf"></div><div class="cp-played"></div></div>' +
          '<div class="cp-thumb"></div><div class="cp-tip">0:00</div>' +
        '</div>' +
        '<div class="cp-row">' +
          '<span class="cp-time" data-r="cur">0:00</span>' +
          '<span class="cp-time cp-dim" data-r="dur">0:00</span>' +
          '<span class="cp-sp"></span>' +
          '<button class="cp-btn cp-glass" data-a="fs"></button>' +
        '</div>' +
      '</div>' +
      '<div class="cp-panel">' +
        '<div class="cp-tabs">' +
          '<button class="cp-tab" data-a="tab" data-t="0">Quality</button>' +
          '<button class="cp-tab" data-a="tab" data-t="1">Audio</button>' +
          '<button class="cp-tab" data-a="tab" data-t="2">Subtitles</button>' +
          '<button class="cp-tab" data-a="tab" data-t="3">More</button>' +
        '</div>' +
        '<div class="cp-list"></div>' +
      '</div>' +
    '</div>' +
    '<button class="cp-btn cp-glass cp-unlock" data-a="unlock"></button>' +
    '<div class="cp-toast"></div>';
  document.documentElement.appendChild(root);

  function q(s) { return root.querySelector(s); }
  var ui = q('.cp-ui'), tap = q('.cp-tap'), bar = q('.cp-bar');
  var bufEl = q('.cp-buf'), playedEl = q('.cp-played'), thumb = q('.cp-thumb'), tip = q('.cp-tip');
  var curEl = q('[data-r=cur]'), durEl = q('[data-r=dur]'), titleEl = q('.cp-title');
  var toastEl = q('.cp-toast'), panel = q('.cp-panel'), list = q('.cp-list'), subEl = q('.cp-sub');
  var unlockBtn = q('.cp-unlock'), ripL = q('.cp-rl'), ripR = q('.cp-rr');
  function btn(a) { return root.querySelector('[data-a=' + a + ']'); }
  var bPlay = btn('play'), bMute = btn('mute'), bFs = btn('fs'), bCC = btn('cc');

  setHTML(btn('back'), icT(P.back, '10'));
  setHTML(btn('fwd'), icT(P.fwd, '10'));
  setHTML(btn('rotate'), ic(P.rot));
  setHTML(btn('lock'), ic(P.lock));
  setHTML(btn('gear'), ic(P.gear));
  setHTML(bCC, ic(P.cc));
  setHTML(unlockBtn, ic(P.unlock, 24));
  root.style.setProperty('--ss', SUBSIZES[subSizeIdx][1] + 'px');

  // ---------- helpers ----------
  function fmt(t) {
    if (!isFinite(t) || t < 0) t = 0;
    t = Math.floor(t);
    var h = Math.floor(t / 3600), m = Math.floor((t % 3600) / 60), s = t % 60;
    return (h ? h + ':' + (m < 10 ? '0' : '') : '') + m + ':' + (s < 10 ? '0' : '') + s;
  }

  function toast(msg) {
    toastEl.textContent = msg;
    toastEl.classList.add('cp-on');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { toastEl.classList.remove('cp-on'); }, 1100);
  }

  function measure() { if (!barW) barW = bar.clientWidth; }

  function updateProgress(force) {
    if (!v) return;
    var t = v.currentTime, d = v.duration;
    if (!force && t === lastT) return;
    lastT = t;
    var p = (isFinite(d) && d > 0) ? Math.min(1, t / d) : 0;
    playedEl.style.transform = 'scaleX(' + p + ')';
    measure();
    thumb.style.transform = 'translate3d(' + (p * barW) + 'px,0,0)';
    var s = Math.floor(t);
    if (s !== lastSec) { lastSec = s; curEl.textContent = fmt(t); }
  }

  function updateBuf() {
    if (!v || !isFinite(v.duration) || !v.duration) { bufEl.style.transform = 'scaleX(0)'; return; }
    var b = v.buffered, e = 0, t = v.currentTime;
    for (var i = 0; i < b.length; i++) {
      if (b.start(i) <= t + 0.5 && b.end(i) >= t) { e = b.end(i); break; }
    }
    bufEl.style.transform = 'scaleX(' + Math.min(1, e / v.duration) + ')';
  }

  function sync() {
    if (!v) return;
    setHTML(bPlay, ic(v.paused ? P.play : P.pause, 34));
    setHTML(bMute, ic((v.muted || v.volume === 0) ? P.mute : P.vol));
    setHTML(bFs, ic(fs ? P.nofs : P.fs));
    durEl.textContent = isFinite(v.duration) ? fmt(v.duration) : 'LIVE';
    bCC.classList.toggle('cp-on', !!subCur);
  }

  function showUI() {
    if (locked) return;
    ui.classList.remove('cp-hide');
    root.classList.add('cp-up');
    uiShown = true;
    clearTimeout(hideTimer);
    updateProgress(true);
    hideTimer = setTimeout(function () {
      if (v && !v.paused && !dragging && !panelOpen) hideUI();
    }, 3500);
  }
  function hideUI() {
    clearTimeout(hideTimer);
    ui.classList.add('cp-hide');
    root.classList.remove('cp-up');
    uiShown = false;
    closePanel();
  }
  function toggleUI() { if (uiShown) hideUI(); else showUI(); }

  function openPanel(t) {
    tab = t;
    panelOpen = true;
    panel.classList.add('cp-open');
    clearTimeout(hideTimer);
    lastHtml = '';
    list.scrollTop = 0;
    build();
  }
  function closePanel() { panelOpen = false; panel.classList.remove('cp-open'); }

  function setLock(on) {
    locked = on;
    root.classList.toggle('cp-locked', on);
    if (on) { hideUI(); toast('Controls locked'); }
    else { unlockBtn.classList.remove('cp-show'); showUI(); toast('Unlocked'); }
  }
  function flashUnlock() {
    unlockBtn.classList.add('cp-show');
    clearTimeout(lockTimer);
    lockTimer = setTimeout(function () { unlockBtn.classList.remove('cp-show'); }, 2200);
  }

  function toggle() {
    if (!v) return;
    if (v.paused) { var p = v.play(); if (p && p.catch) p.catch(function () {}); }
    else v.pause();
    showUI();
  }

  var ripAcc = 0, ripDir = 0, ripT = 0;
  function ripple(dir) {
    var el = dir < 0 ? ripL : ripR;
    ripAcc = (ripDir === dir && Date.now() - ripT < 900) ? ripAcc + 10 : 10;
    ripDir = dir; ripT = Date.now();
    el.firstChild.textContent = (dir < 0 ? '\u25C0\u25C0' : '\u25B6\u25B6') + '\n' + ripAcc + ' sec';
    el.classList.add('cp-on');
    clearTimeout(el.__t);
    el.__t = setTimeout(function () { el.classList.remove('cp-on'); }, 550);
  }

  function skip(sec, quiet) {
    if (!v) return;
    var t = v.currentTime + sec;
    if (isFinite(v.duration)) t = Math.min(v.duration, t);
    v.currentTime = Math.max(0, t);
    lastT = -1;
    if (quiet) ripple(sec < 0 ? -1 : 1);
    else { toast((sec > 0 ? '+' : '') + sec + 's'); showUI(); }
  }

  // ---------- quality ----------
  function hlsInst() {
    var a = window.__hlsInsts || [];
    for (var i = a.length - 1; i >= 0; i--) {
      try { if (a[i].media === v) return a[i]; } catch (e) {}
    }
    return null;
  }

  function parseMaster(text, base) {
    var res = { variants: [], sepAudio: false };
    if (!text || text.indexOf('#EXT-X-STREAM-INF') < 0) return res;
    if (/#EXT-X-MEDIA:[^\n]*TYPE=AUDIO[^\n]*URI=/.test(text)) res.sepAudio = true;
    var lines = text.split(/\r?\n/), out = [];
    for (var i = 0; i < lines.length; i++) {
      var l = lines[i];
      if (l.indexOf('#EXT-X-STREAM-INF:') !== 0) continue;
      var rs = /RESOLUTION=(\d+)x(\d+)/.exec(l);
      var bw = /(?:^|[:,])BANDWIDTH=(\d+)/.exec(l);
      var j = i + 1;
      while (j < lines.length && (lines[j].trim() === '' || lines[j].charAt(0) === '#')) j++;
      if (j < lines.length) {
        try {
          out.push({ h: rs ? parseInt(rs[2], 10) : 0, b: bw ? parseInt(bw[1], 10) : 0, url: new URL(lines[j].trim(), base).href });
        } catch (e) {}
      }
    }
    out.sort(function (a, b) { return b.h - a.h || b.b - a.b; });
    var seen = {};
    out.forEach(function (x) {
      var k = x.h || ('b' + x.b);
      if (!seen[k]) { seen[k] = 1; res.variants.push(x); }
    });
    return res;
  }

  function requestMaster(url) {
    masters[url] = { loading: true, variants: [], sepAudio: false };
    nativeFetch(url, function (text) {
      var r = parseMaster(text, url);
      masters[url] = { loading: false, variants: r.variants, sepAudio: r.sepAudio };
      r.variants.forEach(function (x) { variantMaster[x.url] = url; });
      if (panelOpen) build();
    });
  }

  function switchSrc(url) {
    if (!v) return;
    var vv = v, t = vv.currentTime, p = !vv.paused, r = vv.playbackRate;
    switching = true;
    toast('Switching quality...');
    root.classList.add('cp-wait');
    function ready() {
      vv.removeEventListener('loadedmetadata', ready);
      try { vv.currentTime = t; } catch (e) {}
      vv.playbackRate = r;
      switching = false;
      if (p) { var pr = vv.play(); if (pr && pr.catch) pr.catch(function () {}); }
      sync();
    }
    vv.addEventListener('loadedmetadata', ready);
    vv.src = url;
    vv.load();
  }

  function qLabel(h, b) { return h ? h + 'p' : Math.round(b / 1000) + ' kbps'; }

  function getQuality() {
    var h = hlsInst();
    if (h && h.levels && h.levels.length > 1) {
      var auto = !!h.autoLevelEnabled, cur = h.currentLevel;
      var now = (auto && cur >= 0 && h.levels[cur] && h.levels[cur].height) ? ('Now ' + h.levels[cur].height + 'p') : '';
      var items = [{ label: 'Auto', sub: now, idx: -1, sel: auto }];
      var order = [];
      h.levels.forEach(function (l, i) { order.push({ i: i, h: l.height || 0, b: l.bitrate || 0 }); });
      order.sort(function (a, b) { return b.h - a.h || b.b - a.b; });
      order.forEach(function (o) {
        items.push({ label: qLabel(o.h, o.b), sub: (o.h && o.b) ? Math.round(o.b / 1000) + ' kbps' : '', idx: o.i, sel: !auto && cur === o.i });
      });
      return { items: items, set: function (it) { try { h.currentLevel = it.idx; } catch (e) {} } };
    }

    var srcs = v.querySelectorAll('source'), sItems = [];
    for (var i = 0; i < srcs.length; i++) {
      var s = srcs[i];
      var lab = s.getAttribute('label') || s.getAttribute('title') || s.getAttribute('data-res') ||
                s.getAttribute('data-quality') || s.getAttribute('res') || s.getAttribute('size');
      if (lab && s.src) {
        if (/^\d+$/.test(lab)) lab += 'p';
        sItems.push({ label: lab, sub: '', url: s.src, sel: s.src === v.currentSrc });
      }
    }
    if (sItems.length > 1) return { items: sItems, set: function (it) { if (!it.sel) switchSrc(it.url); } };

    var src = v.currentSrc || '';
    if (src && src.indexOf('blob:') !== 0 && /m3u8/i.test(src)) {
      var base = variantMaster[src] || src;
      var m = masters[base];
      if (!m) { requestMaster(base); return { loading: true }; }
      if (m.loading) return { loading: true };
      if (m.sepAudio) {
        return { note: "This video keeps its audio in a separate stream, so switching quality by hand isn't safe. Quality adjusts automatically." };
      }
      if (m.variants.length > 1) {
        var nItems = [{ label: 'Auto', sub: '', url: base, sel: src === base }];
        m.variants.forEach(function (x) {
          nItems.push({ label: qLabel(x.h, x.b), sub: (x.h && x.b) ? Math.round(x.b / 1000) + ' kbps' : '', url: x.url, sel: src === x.url });
        });
        return { items: nItems, set: function (it) { if (it.url !== src) switchSrc(it.url); } };
      }
    }
    return {};
  }

  // ---------- audio language ----------
  function getAudio() {
    var h = hlsInst(), items = [];
    if (h && h.audioTracks && h.audioTracks.length > 1) {
      h.audioTracks.forEach(function (t, i) {
        items.push({
          label: t.name || langName(t.lang) || ('Track ' + (i + 1)),
          sub: (t.name && t.lang) ? langName(t.lang) : '',
          sel: h.audioTrack === i,
          fn: function () { h.audioTrack = i; toast(t.name || langName(t.lang) || 'Audio'); }
        });
      });
      return items;
    }
    var at = v.audioTracks;
    if (at && at.length > 1) {
      for (var i = 0; i < at.length; i++) {
        (function (i) {
          var t = at[i];
          items.push({
            label: t.label || langName(t.language) || ('Track ' + (i + 1)),
            sub: (t.label && t.language) ? langName(t.language) : '',
            sel: !!t.enabled,
            fn: function () {
              for (var j = 0; j < at.length; j++) at[j].enabled = (j === i);
              toast(t.label || langName(t.language) || 'Audio');
            }
          });
        })(i);
      }
      return items;
    }
    return null;
  }

  // ---------- subtitles ----------
  function ttList() {
    var out = [];
    if (!v || !v.textTracks) return out;
    for (var i = 0; i < v.textTracks.length; i++) {
      var t = v.textTracks[i];
      if (t.kind === 'subtitles' || t.kind === 'captions') out.push(t);
    }
    return out;
  }

  function subOptions() {
    var h = hlsInst(), out = [];
    if (h && h.subtitleTracks && h.subtitleTracks.length) {
      h.subtitleTracks.forEach(function (t, i) {
        out.push({ label: t.name || langName(t.lang) || ('Subtitle ' + (i + 1)), lang: t.lang || '', k: 'hls', i: i, h: h });
      });
      return out;
    }
    ttList().forEach(function (t, i) {
      out.push({ label: t.label || langName(t.language) || ('Subtitle ' + (i + 1)), lang: t.language || '', k: 'tt', t: t });
    });
    return out;
  }

  function isCur(o) {
    return !!subCur && subCur.k === o.k && (o.k === 'tt' ? subCur.t === o.t : subCur.i === o.i);
  }

  function activeTT() {
    if (!subCur || !v) return null;
    if (subCur.k === 'tt') return subCur.t;
    var h = hlsInst(), tl = ttList(), i;
    var name = (h && h.subtitleTracks && h.subtitleTracks[subCur.i]) ? h.subtitleTracks[subCur.i].name : null;
    if (name) { for (i = 0; i < tl.length; i++) if (tl[i].label === name) return tl[i]; }
    for (i = 0; i < tl.length; i++) if (tl[i].mode !== 'disabled') return tl[i];
    return null;
  }

  function fixModes() {
    var tt = activeTT();
    if (!tt) return;
    ttList().forEach(function (t) { try { t.mode = (t === tt) ? 'hidden' : 'disabled'; } catch (e) {} });
  }

  function selectSub(o, auto) {
    var tl = ttList();
    if (!o) {
      subCur = null;
      var h = hlsInst();
      if (h && h.subtitleTracks && h.subtitleTracks.length) { try { h.subtitleTrack = -1; } catch (e) {} }
      tl.forEach(function (t) { try { t.mode = 'disabled'; } catch (e) {} });
      setSub('');
      if (!auto) toast('Subtitles off');
    } else {
      if (o.k === 'hls') {
        try { o.h.subtitleDisplay = false; o.h.subtitleTrack = o.i; } catch (e) {}
        subCur = { k: 'hls', i: o.i };
        setTimeout(fixModes, 400);
        setTimeout(fixModes, 1500);
      } else {
        tl.forEach(function (t) { try { t.mode = (t === o.t) ? 'hidden' : 'disabled'; } catch (e) {} });
        subCur = { k: 'tt', t: o.t };
      }
      if (!auto) toast(o.label);
    }
    subChk = 0; subLast = '\u0000';
    sync();
  }

  function savePref(val) { try { localStorage.setItem('cp_sub', val); } catch (e) {} }

  function syncSubs() {
    if (!v) return;
    var opts = subOptions();
    var sig = opts.map(function (o) { return o.label + '|' + o.lang; }).join(';');
    if (sig === subSig) return;
    subSig = sig;
    if (subTouched || !opts.length) return;
    var pref = null, i;
    try { pref = localStorage.getItem('cp_sub'); } catch (e) {}
    if (pref && pref !== 'off') {
      for (i = 0; i < opts.length; i++) {
        if (opts[i].lang === pref || opts[i].label === pref) { selectSub(opts[i], true); return; }
      }
    }
    if (pref === 'off') { selectSub(null, true); return; }
    var tl = ttList();
    for (i = 0; i < tl.length; i++) {
      if (tl[i].mode === 'showing') {
        for (var j = 0; j < opts.length; j++) {
          if (opts[j].k === 'tt' && opts[j].t === tl[i]) { selectSub(opts[j], true); return; }
        }
      }
    }
  }

  function cleanCue(txt) {
    return String(txt || '').replace(/<[^>]*>/g, '').replace(/\{\\[^}]*\}/g, '')
      .replace(/&nbsp;/g, ' ').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
      .replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&amp;/g, '&');
  }

  function setSub(txt) {
    if (txt === subLast) return;
    subLast = txt;
    while (subEl.firstChild) subEl.removeChild(subEl.firstChild);
    if (!txt) return;
    txt.split('\n').forEach(function (line) {
      if (!line.trim()) return;
      var d = document.createElement('div');
      d.className = 'cp-sl';
      var s = document.createElement('span');
      s.className = 'cp-st';
      s.textContent = line;
      d.appendChild(s);
      subEl.appendChild(d);
    });
  }

  function renderSub() {
    var tt = activeTT();
    if (!tt || !v) { setSub(''); return; }
    var now = Date.now();
    if (now - subChk < 90) return;
    subChk = now;
    var cues = tt.cues;
    if (!cues || !cues.length) { setSub(''); return; }
    var t = v.currentTime - subDelay, texts = [];
    for (var i = 0; i < cues.length; i++) {
      var c = cues[i];
      if (c.startTime <= t && t < c.endTime) texts.push(cleanCue(c.text));
    }
    setSub(texts.join('\n'));
  }

  // ---------- settings panel ----------
  function build() {
    if (!panelOpen || !v) return;
    var na = [];
    function reg(fn) { na.push(fn); return na.length - 1; }
    function opt(label, sel, fn, sub) {
      return '<button class="cp-opt' + (sel ? ' cp-sel' : '') + '" data-a="act" data-i="' + reg(fn) + '">' +
        '<span>' + esc(label) + (sub ? '<small>' + esc(sub) + '</small>' : '') + '</span>' +
        '<span class="cp-ck">' + ic(P.check, 18) + '</span></button>';
    }
    function chip(label, sel, fn) {
      return '<button class="cp-chip2' + (sel ? ' cp-sel' : '') + '" data-a="act" data-i="' + reg(fn) + '">' + esc(label) + '</button>';
    }
    var h = '';

    if (tab === 0) {
      var Q = getQuality();
      if (Q.loading) h = '<div class="cp-note">Checking available qualities...</div>';
      else if (Q.items) Q.items.forEach(function (it) { h += opt(it.label, it.sel, function () { Q.set(it); }, it.sub); });
      else h = '<div class="cp-note">' + esc(Q.note || "Quality options aren't available for this video. The site picks the quality automatically.") + '</div>';
    }
    else if (tab === 1) {
      var A = getAudio();
      if (A) A.forEach(function (it) { h += opt(it.label, it.sel, it.fn, it.sub); });
      else h = '<div class="cp-note">This video has a single audio track. If the site offers other languages as separate versions of the title (for example [English] or [Tagalog]), pick that version from the site.</div>';
    }
    else if (tab === 2) {
      var opts = subOptions();
      if (!opts.length) {
        h = '<div class="cp-note">No subtitle tracks were found for this video. If the picture already shows text, those subtitles are part of the video and cannot be changed here.</div>';
      } else {
        h += opt('Off', !subCur, function () { subTouched = true; selectSub(null); savePref('off'); });
        opts.forEach(function (o) {
          var sub = (o.lang && langName(o.lang) !== o.label) ? langName(o.lang) : '';
          h += opt(o.label, isCur(o), function () { subTouched = true; selectSub(o); savePref(o.lang || o.label); }, sub);
        });
        h += '<div class="cp-sec">Text size</div><div class="cp-chips">';
        SUBSIZES.forEach(function (s, i) {
          h += chip(s[0], subSizeIdx === i, function () {
            subSizeIdx = i;
            root.style.setProperty('--ss', s[1] + 'px');
            try { localStorage.setItem('cp_ssize', String(i)); } catch (e) {}
          });
        });
        h += '</div>';
        var dl = (subDelay > 0 ? '+' : '') + subDelay.toFixed(1) + 's';
        h += '<div class="cp-sec">Timing (' + dl + ')</div><div class="cp-chips">' +
          chip('Earlier', false, function () { subDelay = Math.round((subDelay - 0.5) * 10) / 10; subChk = 0; }) +
          chip('Reset', subDelay === 0, function () { subDelay = 0; subChk = 0; }) +
          chip('Later', false, function () { subDelay = Math.round((subDelay + 0.5) * 10) / 10; subChk = 0; }) +
          '</div>';
      }
    }
    else {
      h += '<div class="cp-sec">Playback speed</div><div class="cp-chips">';
      SPEEDS.forEach(function (s) {
        h += chip(s + 'x', v.playbackRate === s, function () { v.playbackRate = s; toast('Speed ' + s + 'x'); });
      });
      h += '</div><div class="cp-sec">Picture</div><div class="cp-chips">';
      FITS.forEach(function (f, i) {
        h += chip(FIT_LABELS[f], fitIdx === i, function () {
          fitIdx = i;
          v.style.setProperty('object-fit', f, 'important');
          toast(FIT_LABELS[f]);
        });
      });
      h += '</div>';
    }

    acts = na;
    var tabs = root.querySelectorAll('.cp-tab');
    for (var k = 0; k < tabs.length; k++) tabs[k].classList.toggle('cp-sel', k === tab);
    if (h !== lastHtml) { lastHtml = h; list.innerHTML = h; }
  }

  // ---------- resume position ----------
  function key() { return 'cp_pos:' + location.pathname + location.search; }
  function save() {
    var now = Date.now();
    if (now - lastSave < 5000 || !v || !isFinite(v.duration)) return;
    lastSave = now;
    try { localStorage.setItem(key(), String(v.currentTime)); } catch (e) {}
  }

  function onState(e) {
    var n = e.type;
    if (n === 'waiting' || n === 'seeking') root.classList.add('cp-wait');
    if (n === 'playing' || n === 'canplay' || n === 'seeked') root.classList.remove('cp-wait');
    if (n === 'timeupdate') { save(); return; }
    if (n === 'progress') { updateBuf(); return; }
    if (n === 'ended') { try { localStorage.removeItem(key()); } catch (x) {} }
    if (n === 'pause' || n === 'ended') showUI();
    if (n === 'playing') showUI();
    sync();
  }

  function onMeta() {
    if (!v) return;
    if (switching) { sync(); return; }
    try {
      var p = parseFloat(localStorage.getItem(key()));
      if (p > 10 && isFinite(v.duration) && p < v.duration - 15) {
        v.currentTime = p;
        toast('Resumed at ' + fmt(p));
      }
    } catch (e) {}
    sync(); updateBuf(); updateProgress(true);
  }

  // ---------- fullscreen ----------
  function setFS(on) {
    if (!v || on === fs) return;
    fs = on;
    root.classList.toggle('cp-fs', on);
    if (on) {
      savedStyle = v.getAttribute('style');
      var s = {
        'position': 'fixed', 'left': '0', 'top': '0',
        'width': '100vw', 'height': '100vh',
        'max-width': 'none', 'max-height': 'none', 'margin': '0',
        'z-index': '2147483646', 'background': '#000'
      };
      for (var k in s) v.style.setProperty(k, s[k], 'important');
      document.documentElement.style.setProperty('overflow', 'hidden', 'important');
      post('landscape');
    } else {
      if (savedStyle === null) v.removeAttribute('style');
      else v.setAttribute('style', savedStyle);
      v.style.setProperty('object-fit', FITS[fitIdx], 'important');
      document.documentElement.style.removeProperty('overflow');
      post('portrait');
    }
    barW = 0;
    sync();
  }

  // ---------- attach / detach ----------
  function detach() {
    if (!v) return;
    if (fs) setFS(false);
    EVENTS.forEach(function (n) { v.removeEventListener(n, onState); });
    v.removeEventListener('loadedmetadata', onMeta);
    v = null;
    root.style.display = 'none';
    vis = false; lw = lh = 0; lx = ly = -1;
    closePanel();
    subCur = null; subSig = ''; subTouched = false; subDelay = 0; lastHtml = ''; switching = false;
    setSub('');
  }

  function attach(el) {
    if (v === el) return;
    detach();
    v = el;
    v.controls = false;
    v.removeAttribute('controls');
    v.setAttribute('playsinline', '');
    v.setAttribute('webkit-playsinline', '');
    v.style.setProperty('object-fit', FITS[fitIdx], 'important');
    EVENTS.forEach(function (n) { v.addEventListener(n, onState); });
    v.addEventListener('loadedmetadata', onMeta);
    titleEl.textContent = document.title || '';
    root.classList.remove('cp-wait');
    lastT = -1; lastSec = -1; barW = 0;
    if (v.readyState >= 1) onMeta();
    sync(); updateBuf(); showUI();
    startLoop();
  }

  function pickVideo() {
    var vs = document.querySelectorAll('video'), best = null, area = 0;
    for (var i = 0; i < vs.length; i++) {
      var r = vs[i].getBoundingClientRect();
      var a = r.width * r.height;
      if (r.bottom > 0 && r.top < innerHeight && a > area) { area = a; best = vs[i]; }
    }
    return (best && area > 120 * 80) ? best : null;
  }

  // ---------- smooth render loop ----------
  function frame() {
    if (!document.contains(v)) return;
    var r = v.getBoundingClientRect();
    if (r.width < 120 || r.height < 80 || r.bottom < 0 || r.top > innerHeight) {
      if (vis) { root.style.display = 'none'; vis = false; }
      return;
    }
    if (!vis) { root.style.display = 'block'; vis = true; lw = 0; lx = -1; barW = 0; }
    if (r.width !== lw || r.height !== lh) {
      root.style.width = r.width + 'px';
      root.style.height = r.height + 'px';
      lw = r.width; lh = r.height; barW = 0;
      lastT = -1;
    }
    if (r.left !== lx || r.top !== ly) {
      root.style.transform = 'translate3d(' + r.left + 'px,' + r.top + 'px,0)';
      lx = r.left; ly = r.top;
    }
    if (uiShown && !dragging && !locked) updateProgress(false);
    renderSub();
  }
  function loop() {
    if (!v) { rafOn = false; return; }
    frame();
    requestAnimationFrame(loop);
  }
  function startLoop() { if (!rafOn) { rafOn = true; requestAnimationFrame(loop); } }

  function tick() {
    if (v && !document.contains(v)) detach();
    var best = fs ? v : pickVideo();
    if (best && best !== v) attach(best);
    else if (!best && v) detach();
    if (v) { syncSubs(); if (panelOpen) build(); }
  }

  // ---------- buttons ----------
  root.addEventListener('click', function (e) {
    var t = e.target;
    var b = t.closest ? t.closest('[data-a]') : null;
    if (!b || !v) return;
    e.stopPropagation();
    var a = b.getAttribute('data-a');

    if (a === 'tab') { tab = parseInt(b.getAttribute('data-t'), 10); list.scrollTop = 0; lastHtml = ''; build(); return; }
    if (a === 'act') {
      var fn = acts[parseInt(b.getAttribute('data-i'), 10)];
      if (fn) { try { fn(); } catch (x) {} }
      build(); sync(); showUI();
      return;
    }
    if (a === 'gear') { if (panelOpen) closePanel(); else openPanel(tab); return; }
    if (a === 'cc') { if (panelOpen && tab === 2) closePanel(); else openPanel(2); return; }

    if (a === 'play') toggle();
    else if (a === 'back') skip(-10, false);
    else if (a === 'fwd') skip(10, false);
    else if (a === 'mute') { v.muted = !v.muted; toast(v.muted ? 'Muted' : 'Sound on'); }
    else if (a === 'rotate') {
      var land = innerWidth > innerHeight;
      post(land ? 'portrait' : 'landscape');
      toast(land ? 'Portrait' : 'Landscape');
    }
    else if (a === 'fs') setFS(!fs);
    else if (a === 'lock') { setLock(true); return; }
    else if (a === 'unlock') { setLock(false); return; }
    sync();
    showUI();
  });

  // ---------- seek bar with time preview ----------
  function ratioFrom(e) {
    var r = bar.getBoundingClientRect();
    return Math.max(0, Math.min(1, (e.clientX - r.left) / r.width));
  }
  function scrub(e) {
    var p = ratioFrom(e);
    measure();
    playedEl.style.transform = 'scaleX(' + p + ')';
    thumb.style.transform = 'translate3d(' + (p * barW) + 'px,0,0)';
    var x = Math.max(28, Math.min(barW - 28, p * barW));
    tip.style.transform = 'translate3d(' + x + 'px,0,0) translateX(-50%)';
    var t = p * v.duration;
    tip.textContent = fmt(t);
    curEl.textContent = fmt(t);
  }
  function endScrub(e, cancel) {
    if (!dragging) return;
    dragging = false;
    root.classList.remove('cp-drag');
    if (!cancel && v && isFinite(v.duration)) v.currentTime = ratioFrom(e) * v.duration;
    lastT = -1; lastSec = -1;
    showUI();
  }
  bar.addEventListener('pointerdown', function (e) {
    if (!v || !isFinite(v.duration)) return;
    e.stopPropagation();
    dragging = true;
    try { bar.setPointerCapture(e.pointerId); } catch (x) {}
    root.classList.add('cp-drag');
    clearTimeout(hideTimer);
    scrub(e);
  });
  bar.addEventListener('pointermove', function (e) { if (dragging) scrub(e); });
  bar.addEventListener('pointerup', function (e) { endScrub(e, false); });
  bar.addEventListener('pointercancel', function (e) { endScrub(e, true); });

  // ---------- gestures ----------
  var holdTimer = null, held = false, prevRate = 1, lastTap = 0, tapTimer = null;
  tap.addEventListener('pointerdown', function () {
    held = false;
    clearTimeout(holdTimer);
    if (locked) return;
    holdTimer = setTimeout(function () {
      if (!v) return;
      held = true;
      prevRate = v.playbackRate;
      v.playbackRate = 2;
      toast('2x speed');
    }, 500);
  });
  function endPress(e, cancelled) {
    clearTimeout(holdTimer);
    if (held) { held = false; if (v) v.playbackRate = prevRate; sync(); return; }
    if (cancelled || !v) return;
    if (locked) { flashUnlock(); return; }
    if (panelOpen) { closePanel(); showUI(); return; }
    var r = tap.getBoundingClientRect();
    var x = (e.clientX - r.left) / r.width;
    var now = Date.now();
    if (now - lastTap < 300) {
      clearTimeout(tapTimer);
      lastTap = 0;
      if (x < 0.35) skip(-10, true);
      else if (x > 0.65) skip(10, true);
      else toggle();
    } else {
      lastTap = now;
      tapTimer = setTimeout(toggleUI, 300);
    }
  }
  tap.addEventListener('pointerup', function (e) { endPress(e, false); });
  tap.addEventListener('pointercancel', function (e) { endPress(e, true); });
  root.addEventListener('contextmenu', function (e) { e.preventDefault(); });

  window.addEventListener('resize', function () { barW = 0; lastT = -1; });
  window.addEventListener('orientationchange', function () { barW = 0; lastT = -1; });
  setInterval(tick, 500);
})();
"""#
