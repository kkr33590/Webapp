let playerJS = #"""
(function () {
  if (window.__cpLoaded) return;
  window.__cpLoaded = true;

  var SPEEDS = [0.5, 0.75, 1, 1.25, 1.5, 2];
  var FITS = ['contain', 'cover', 'fill'];
  var FIT_LABELS = { contain: 'Fit', cover: 'Fill', fill: 'Stretch' };
  var EVENTS = ['play', 'pause', 'timeupdate', 'durationchange', 'volumechange', 'ratechange', 'ended'];
  var v = null, fs = false, dragging = false, hideTimer = null;
  var fitIdx = 0, savedStyle = null, lastSave = 0, toastTimer = null;

  function post(m) {
    try { window.webkit.messageHandlers.orient.postMessage(m); } catch (e) {}
  }

  var css = document.createElement('style');
  css.textContent = [
    'video::-webkit-media-controls{display:none !important}',
    '.cp-root{position:fixed;z-index:2147483647;display:none;font-family:-apple-system,Helvetica,Arial,sans-serif;color:#fff;-webkit-user-select:none;user-select:none;-webkit-touch-callout:none}',
    '.cp-tap{position:absolute;left:0;top:0;right:0;bottom:0;touch-action:manipulation}',
    '.cp-ui{position:absolute;left:0;top:0;right:0;bottom:0;display:flex;flex-direction:column;justify-content:space-between;pointer-events:none;transition:opacity .25s}',
    '.cp-ui.cp-hide{opacity:0}',
    '.cp-ui.cp-hide *{pointer-events:none !important}',
    '.cp-top{display:flex;justify-content:flex-end;flex-wrap:wrap;gap:8px;padding:10px 12px;background:linear-gradient(rgba(0,0,0,.65),rgba(0,0,0,0))}',
    '.cp-mid{display:flex;justify-content:center;align-items:center;gap:30px}',
    '.cp-bot{padding:6px 12px 12px;background:linear-gradient(rgba(0,0,0,0),rgba(0,0,0,.7))}',
    '.cp-row{display:flex;align-items:center;gap:10px}',
    '.cp-btn{pointer-events:auto;background:rgba(255,255,255,.18);color:#fff;border:0;border-radius:18px;min-width:36px;height:36px;padding:0 12px;font-size:14px;font-weight:600}',
    '.cp-btn:active{background:rgba(255,255,255,.4)}',
    '.cp-big{width:58px;height:58px;border-radius:29px;font-size:22px;padding:0}',
    '.cp-seek{pointer-events:auto;flex:1;height:28px;accent-color:#2ff58b}',
    '.cp-time{font-size:12px;min-width:42px;font-variant-numeric:tabular-nums}',
    '.cp-toast{position:absolute;top:18%;left:50%;transform:translateX(-50%);background:rgba(0,0,0,.72);padding:8px 16px;border-radius:16px;font-size:14px;opacity:0;transition:opacity .2s;pointer-events:none}',
    '.cp-toast.cp-on{opacity:1}'
  ].join('\n');
  document.documentElement.appendChild(css);

  var root = document.createElement('div');
  root.className = 'cp-root';
  root.innerHTML =
    '<div class="cp-tap"></div>' +
    '<div class="cp-ui">' +
      '<div class="cp-top">' +
        '<button class="cp-btn" data-a="fit">Fit</button>' +
        '<button class="cp-btn" data-a="speed">1x</button>' +
        '<button class="cp-btn" data-a="mute">🔊</button>' +
        '<button class="cp-btn" data-a="rotate">Rotate</button>' +
        '<button class="cp-btn" data-a="fs">Full</button>' +
      '</div>' +
      '<div class="cp-mid">' +
        '<button class="cp-btn cp-big" style="font-size:15px" data-a="back">-10s</button>' +
        '<button class="cp-btn cp-big" data-a="play">▶</button>' +
        '<button class="cp-btn cp-big" style="font-size:15px" data-a="fwd">+10s</button>' +
      '</div>' +
      '<div class="cp-bot"><div class="cp-row">' +
        '<span class="cp-time" data-r="cur">0:00</span>' +
        '<input class="cp-seek" type="range" min="0" max="1000" value="0">' +
        '<span class="cp-time" data-r="dur">0:00</span>' +
      '</div></div>' +
    '</div>' +
    '<div class="cp-toast"></div>';
  document.documentElement.appendChild(root);

  var ui = root.querySelector('.cp-ui');
  var tap = root.querySelector('.cp-tap');
  var seek = root.querySelector('.cp-seek');
  var toastEl = root.querySelector('.cp-toast');
  var curEl = root.querySelector('[data-r=cur]');
  var durEl = root.querySelector('[data-r=dur]');
  function btn(a) { return root.querySelector('[data-a=' + a + ']'); }

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

  function showUI() {
    ui.classList.remove('cp-hide');
    clearTimeout(hideTimer);
    hideTimer = setTimeout(function () {
      if (v && !v.paused && !dragging) ui.classList.add('cp-hide');
    }, 3500);
  }

  function toggleUI() {
    if (ui.classList.contains('cp-hide')) showUI();
    else { clearTimeout(hideTimer); ui.classList.add('cp-hide'); }
  }

  function skip(sec) {
    if (!v) return;
    var t = v.currentTime + sec;
    if (isFinite(v.duration)) t = Math.min(v.duration, t);
    v.currentTime = Math.max(0, t);
    toast((sec > 0 ? '+' : '') + sec + 's');
    showUI();
  }

  function toggle() {
    if (!v) return;
    if (v.paused) { var p = v.play(); if (p && p.catch) p.catch(function () {}); }
    else v.pause();
    showUI();
  }

  function key() { return 'cp_pos:' + location.pathname + location.search; }

  function save() {
    var now = Date.now();
    if (now - lastSave < 5000 || !v || !isFinite(v.duration)) return;
    lastSave = now;
    try { localStorage.setItem(key(), String(v.currentTime)); } catch (e) {}
  }

  function sync() {
    if (!v) return;
    btn('play').textContent = v.paused ? '▶' : '❚❚';
    btn('mute').textContent = (v.muted || v.volume === 0) ? '🔇' : '🔊';
    btn('speed').textContent = v.playbackRate + 'x';
    btn('fs').textContent = fs ? 'Exit' : 'Full';
    btn('fit').textContent = FIT_LABELS[FITS[fitIdx]];
    curEl.textContent = fmt(v.currentTime);
    durEl.textContent = isFinite(v.duration) ? fmt(v.duration) : 'LIVE';
    if (!dragging && isFinite(v.duration) && v.duration > 0) {
      seek.value = Math.round(v.currentTime / v.duration * 1000);
    }
  }

  function onState(e) {
    sync();
    if (e.type === 'timeupdate') save();
    if (e.type === 'pause') showUI();
    if (e.type === 'ended') { try { localStorage.removeItem(key()); } catch (x) {} }
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
    sync();
  }

  function setFS(on) {
    if (!v || on === fs) return;
    fs = on;
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
    sync();
    reposition();
  }

  function detach() {
    if (!v) return;
    if (fs) setFS(false);
    EVENTS.forEach(function (n) { v.removeEventListener(n, onState); });
    v.removeEventListener('loadedmetadata', onMeta);
    v = null;
    root.style.display = 'none';
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
    if (v.readyState >= 1) onMeta();
    sync();
    showUI();
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

  function reposition() {
    if (!v || !document.contains(v)) { root.style.display = 'none'; return; }
    var r = v.getBoundingClientRect();
    if (r.width < 120 || r.height < 80 || r.bottom < 0 || r.top > innerHeight) {
      root.style.display = 'none';
      return;
    }
    root.style.display = 'block';
    root.style.left = r.left + 'px';
    root.style.top = r.top + 'px';
    root.style.width = r.width + 'px';
    root.style.height = r.height + 'px';
  }

  function tick() {
    if (v && !document.contains(v)) detach();
    var best = fs ? v : pickVideo();
    if (best && best !== v) attach(best);
    else if (!best && v) detach();
    reposition();
  }

  // Buttons
  root.addEventListener('click', function (e) {
    var b = e.target.closest ? e.target.closest('[data-a]') : null;
    if (!b || !v) return;
    e.stopPropagation();
    var a = b.getAttribute('data-a');
    if (a === 'play') toggle();
    else if (a === 'back') skip(-10);
    else if (a === 'fwd') skip(10);
    else if (a === 'speed') {
      var i = (SPEEDS.indexOf(v.playbackRate) + 1) % SPEEDS.length;
      v.playbackRate = SPEEDS[i];
      toast('Speed ' + SPEEDS[i] + 'x');
    }
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
    sync();
    showUI();
  });

  // Seek bar
  seek.addEventListener('input', function () {
    dragging = true;
    clearTimeout(hideTimer);
    if (v && isFinite(v.duration)) curEl.textContent = fmt(seek.value / 1000 * v.duration);
  });
  seek.addEventListener('change', function () {
    if (v && isFinite(v.duration)) v.currentTime = seek.value / 1000 * v.duration;
    dragging = false;
    showUI();
  });

  // Gestures: tap = show/hide controls, double-tap sides = +/-10s,
  // double-tap center = play/pause, hold = 2x speed
  var holdTimer = null, held = false, prevRate = 1, lastTap = 0, tapTimer = null;
  tap.addEventListener('pointerdown', function () {
    held = false;
    clearTimeout(holdTimer);
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
    var r = tap.getBoundingClientRect();
    var x = (e.clientX - r.left) / r.width;
    var now = Date.now();
    if (now - lastTap < 300) {
      clearTimeout(tapTimer);
      lastTap = 0;
      if (x < 0.35) skip(-10);
      else if (x > 0.65) skip(10);
      else toggle();
    } else {
      lastTap = now;
      tapTimer = setTimeout(toggleUI, 300);
    }
  }
  tap.addEventListener('pointerup', function (e) { endPress(e, false); });
  tap.addEventListener('pointercancel', function (e) { endPress(e, true); });
  root.addEventListener('contextmenu', function (e) { e.preventDefault(); });

  window.addEventListener('scroll', reposition, { passive: true, capture: true });
  window.addEventListener('resize', function () { setTimeout(reposition, 100); });
  window.addEventListener('orientationchange', function () { setTimeout(reposition, 300); });
  setInterval(tick, 400);
})();
"""#
