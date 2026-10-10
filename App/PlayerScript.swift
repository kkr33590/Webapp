let playerJS = #"""
(function () {
  if (window.__cpLoaded) return;
  window.__cpLoaded = true;

  var SPEEDS = [0.5, 0.75, 1, 1.25, 1.5, 2];
  var FITS = ['contain', 'cover', 'fill'];
  var FIT_LABELS = { contain: 'Fit', cover: 'Fill', fill: 'Stretch' };
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
    fit: 'M19 12h-2v3h-3v2h5v-5zM7 9h3V7H5v5h2V9zm14-6H3c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h18c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16.01H3V4.99h18v14.02z',
    lock: 'M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z',
    unlock: 'M12 17c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm6-9h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6h1.9c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm0 12H6V10h12v10z'
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

  // ---------- state ----------
  var v = null, fs = false, dragging = false, locked = false, menuOpen = false;
  var uiShown = true, vis = false, rafOn = false;
  var hideTimer = null, toastTimer = null, lockTimer = null;
  var fitIdx = 0, savedStyle = null, lastSave = 0;
  var lx = -1, ly = -1, lw = 0, lh = 0, barW = 0, lastT = -1, lastSec = -1;

  function post(m) {
    try { window.webkit.messageHandlers.orient.postMessage(m); } catch (e) {}
  }

  // ---------- styles (no backdrop blur: it re-renders every video frame) ----------
  var css = document.createElement('style');
  css.textContent = [
    'video::-webkit-media-controls{display:none !important}',
    'video::-webkit-media-controls-enclosure{display:none !important}',
    '.cp-root{position:fixed;left:0;top:0;z-index:2147483647;display:none;overflow:hidden;will-change:transform;color:#fff;font-family:-apple-system,BlinkMacSystemFont,"Helvetica Neue",Arial,sans-serif;-webkit-user-select:none;user-select:none;-webkit-touch-callout:none}',
    '.cp-root *{box-sizing:border-box;-webkit-tap-highlight-color:transparent}',
    '.cp-root button{font-family:inherit;outline:0;margin:0;padding:0}',
    '.cp-tap{position:absolute;left:0;top:0;right:0;bottom:0;touch-action:manipulation}',
    '.cp-glass{background:rgba(10,14,20,.5);border:1px solid rgba(255,255,255,.16)}',
    '.cp-ui{position:absolute;left:0;top:0;right:0;bottom:0;display:flex;flex-direction:column;justify-content:space-between;pointer-events:none;transition:opacity .25s ease}',
    '.cp-ui.cp-hide,.cp-locked .cp-ui{opacity:0}',
    '.cp-ui.cp-hide *,.cp-locked .cp-ui *{pointer-events:none !important}',
    '.cp-top{display:flex;align-items:center;justify-content:space-between;gap:8px;padding:10px 12px 26px;background:linear-gradient(rgba(0,0,0,.7),rgba(0,0,0,0))}',
    '.cp-fs .cp-top{padding-top:max(10px,env(safe-area-inset-top));padding-left:max(12px,env(safe-area-inset-left));padding-right:max(12px,env(safe-area-inset-right))}',
    '.cp-title{flex:1;min-width:0;font-size:14px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;text-shadow:0 1px 4px rgba(0,0,0,.6)}',
    '.cp-tr{display:flex;gap:8px;align-items:center}',
    '.cp-btn{pointer-events:auto;display:flex;align-items:center;justify-content:center;width:38px;height:38px;border-radius:19px;color:#fff;transition:transform .15s ease,background .15s ease}',
    '.cp-btn:active{transform:scale(.88);background:rgba(255,255,255,.28)}',
    '.cp-chip{width:auto;min-width:48px;padding:0 12px !important;font-size:13px;font-weight:700}',
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
    '.cp-menu{position:absolute;top:56px;right:12px;width:200px;display:none;flex-wrap:wrap;gap:6px;padding:10px;border-radius:16px;pointer-events:auto}',
    '.cp-fs .cp-menu{right:max(12px,env(safe-area-inset-right))}',
    '.cp-menu.cp-open{display:flex}',
    '.cp-chip2{flex:1 0 28%;height:34px;border:0;border-radius:17px;background:rgba(255,255,255,.14);color:#fff;font-size:13px;font-weight:700}',
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
    '<div class="cp-spin"></div>' +
    '<div class="cp-ui">' +
      '<div class="cp-top">' +
        '<div class="cp-title"></div>' +
        '<div class="cp-tr">' +
          '<button class="cp-btn cp-glass cp-chip" data-a="speed">1x</button>' +
          '<button class="cp-btn cp-glass" data-a="fit"></button>' +
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
      '<div class="cp-menu cp-glass"></div>' +
    '</div>' +
    '<button class="cp-btn cp-glass cp-unlock" data-a="unlock"></button>' +
    '<div class="cp-toast"></div>';
  document.documentElement.appendChild(root);

  function q(s) { return root.querySelector(s); }
  var ui = q('.cp-ui'), tap = q('.cp-tap'), bar = q('.cp-bar');
  var bufEl = q('.cp-buf'), playedEl = q('.cp-played'), thumb = q('.cp-thumb'), tip = q('.cp-tip');
  var curEl = q('[data-r=cur]'), durEl = q('[data-r=dur]'), titleEl = q('.cp-title');
  var toastEl = q('.cp-toast'), menu = q('.cp-menu'), unlockBtn = q('.cp-unlock');
  var ripL = q('.cp-rl'), ripR = q('.cp-rr');
  function btn(a) { return root.querySelector('[data-a=' + a + ']'); }
  var bPlay = btn('play'), bMute = btn('mute'), bSpeed = btn('speed'), bFs = btn('fs');

  setHTML(btn('back'), icT(P.back, '10'));
  setHTML(btn('fwd'), icT(P.fwd, '10'));
  setHTML(btn('fit'), ic(P.fit));
  setHTML(btn('rotate'), ic(P.rot));
  setHTML(btn('lock'), ic(P.lock));
  setHTML(unlockBtn, ic(P.unlock, 24));
  menu.innerHTML = SPEEDS.map(function (s) {
    return '<button class="cp-chip2" data-s="' + s + '">' + s + 'x</button>';
  }).join('');

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
    toastTimer = setTimeout(function () { toastEl.classList.remove('cp-on'); }, 900);
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
    bSpeed.textContent = v.playbackRate + 'x';
    durEl.textContent = isFinite(v.duration) ? fmt(v.duration) : 'LIVE';
    var chips = menu.children;
    for (var i = 0; i < chips.length; i++) {
      chips[i].classList.toggle('cp-sel', parseFloat(chips[i].getAttribute('data-s')) === v.playbackRate);
    }
  }

  function showUI() {
    if (locked) return;
    ui.classList.remove('cp-hide');
    uiShown = true;
    clearTimeout(hideTimer);
    updateProgress(true);
    hideTimer = setTimeout(function () {
      if (v && !v.paused && !dragging && !menuOpen) hideUI();
    }, 3500);
  }
  function hideUI() {
    clearTimeout(hideTimer);
    ui.classList.add('cp-hide');
    uiShown = false;
    closeMenu();
  }
  function toggleUI() { if (uiShown) hideUI(); else showUI(); }

  function openMenu() { menuOpen = true; menu.classList.add('cp-open'); clearTimeout(hideTimer); }
  function closeMenu() { menuOpen = false; menu.classList.remove('cp-open'); }

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

  // Double-tap ripple with accumulating seconds
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
    closeMenu();
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

  // ---------- smooth render loop: GPU transforms, only writes when something changed ----------
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
  }

  // ---------- buttons ----------
  root.addEventListener('click', function (e) {
    var t = e.target;
    var b = t.closest ? t.closest('[data-a],[data-s]') : null;
    if (!b || !v) return;
    e.stopPropagation();
    var s = b.getAttribute('data-s');
    if (s) {
      v.playbackRate = parseFloat(s);
      closeMenu(); toast('Speed ' + s + 'x'); sync(); showUI();
      return;
    }
    var a = b.getAttribute('data-a');
    if (a === 'play') toggle();
    else if (a === 'back') skip(-10, false);
    else if (a === 'fwd') skip(10, false);
    else if (a === 'speed') { if (menuOpen) closeMenu(); else openMenu(); return; }
    else if (a === 'mute') { v.muted = !v.muted; toast(v.muted ? 'Muted' : 'Sound on'); }
    else if (a === 'fit') {
      fitIdx = (fitIdx + 1) % FITS.length;
      v.style.setProperty('object-fit', FITS[fitIdx], 'important');
      toast(FIT_LABELS[FITS[fitIdx]]);
    }
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

  // ---------- gestures: tap = controls, double-tap sides = skip, double-tap middle = play/pause, hold = 2x ----------
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
    if (menuOpen) { closeMenu(); showUI(); return; }
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
