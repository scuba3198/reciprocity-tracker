// Purely presentational motion layer. It observes DOM re-renders (it never touches app state)
// and animates what changed: count rolls, the d puck, fresh rows, rail FLIP, click bursts.
// Call once, after the first render.
import { $ } from './dom.js';

export function initMotion() {
  const reduce = matchMedia('(prefers-reduced-motion: reduce)');
  const detail = $('detail'), rail = $('rail'), strip = $('stripwrap'), imsg = $('imsg'), ov = $('helpov');
  const top = document.querySelector('.top');
  const num = s => parseInt(String(s).replace('−', '-'), 10) || 0;

  function keyOf(it, seen) {
    const pn = it.querySelector('.pnm');
    const n = pn ? pn.dataset.real ?? pn.textContent : '';
    seen[n] = (seen[n] || 0) + 1;
    return n + '#' + seen[n];
  }
  function multiset(nodes, fn) {
    const m = new Map();
    nodes.forEach(n => { const k = fn(n); m.set(k, (m.get(k) || 0) + 1); });
    return m;
  }
  const txt = (n, s) => (n.querySelector(s) || {}).textContent || '';
  const evKey = n => txt(n, '.dt') + '|' + txt(n, '.tx') + '|' + txt(n, '.res');
  const srKey = n => txt(n, '.who') + '|' + txt(n, '.dt') + '|' + txt(n, '.tx');

  function snapshot() {
    const cur = detail.querySelector('.cell.cur');
    const ver = detail.querySelector('.verdict');
    const tol = detail.querySelector('.head input[type=number]');
    const pos = new Map(), dots = new Map(), seen = {};
    let sel = null;
    rail.querySelectorAll('.pitem').forEach(it => {
      const k = keyOf(it, seen);
      pos.set(k, { x: it.offsetLeft, y: it.offsetTop });
      dots.set(k, (it.querySelector('.pdot') || {}).style?.background);
      if (it.classList.contains('on')) sel = k;
    });
    return {
      pid: tol ? tol.id : null,
      vals: [...detail.querySelectorAll('.cnt .v')].map(v => v.dataset.v ?? v.textContent),
      verdict: ver ? (ver.classList.contains('yes') ? 'yes' : 'no') : null,
      cur: cur ? { x: cur.offsetLeft, w: cur.offsetWidth } : null,
      evs: multiset(detail.querySelectorAll('.ev'), evKey),
      editor: !!detail.querySelector('.editor'),
      strip: multiset(strip.querySelectorAll('.srow'), srKey),
      hasStrip: !!strip.firstChild,
      badge: txt(strip, '.badge') || null,
      pos, dots, sel
    };
  }

  function markFresh(nodes, prevMap, keyFn, cls) {
    const left = new Map(prevMap);
    nodes.forEach(x => {
      const k = keyFn(x), c = left.get(k) || 0;
      if (c > 0) { left.set(k, c - 1); return; }
      x.classList.add(cls);
      const nx = x.nextElementSibling;
      if (nx && nx.classList.contains('resolver')) nx.classList.add('fresh');
    });
  }

  // Decode-style intro: each letter flickers through random glyphs, then locks onto the real
  // character, left to right. Every letter keeps its final width so nothing jitters, and the
  // real name sits in data-real (keyOf reads it) until the plain text is restored at the end.
  const seg = typeof Intl !== 'undefined' && Intl.Segmenter ? new Intl.Segmenter() : null;
  const GL = { up: 'ABCDEFGHJKLMNPQRSTUVWXYZ#%&@', lo: 'abcdefghjkmnpqrstuvwxyz*+=?/' };
  const glyph = c => {
    const set = c === c.toLowerCase() && c !== c.toUpperCase() ? GL.lo : GL.up;
    return set[Math.random() * set.length | 0];
  };
  function unjumble(node, delay = 0) {
    if (!node || node.dataset.real !== undefined) return;
    const text = node.textContent;
    const chars = seg ? [...seg.segment(text)].map(s => s.segment) : [...text];
    if (chars.filter(c => c.trim()).length < 2) return;
    node.dataset.real = text;
    node.textContent = '';
    const letters = [];
    let word = null;
    chars.forEach(c => {
      if (!c.trim()) { word = null; node.append(c); return; }
      if (!word) { word = document.createElement('span'); word.className = 'jw'; node.append(word); }
      const s = document.createElement('span'); s.className = 'jl'; s.textContent = c;
      word.append(s); letters.push(s);
    });
    const t0 = performance.now() + delay;
    const jobs = letters.map((s, i) => {
      s.style.width = s.getBoundingClientRect().width + 'px';
      s.classList.add('jg');
      const c = s.textContent;
      s.textContent = glyph(c);
      return { s, c, at: 180 + i * 42 + Math.random() * 140, next: 0 };
    });
    const end = Math.max(...jobs.map(j => j.at));
    // setTimeout rather than rAF: a background tab would otherwise freeze names mid-scramble.
    (function tick() {
      if (!node.isConnected) return;
      const now = performance.now();
      const t = now - t0;
      jobs.forEach(j => {
        if (j.done) return;
        if (t >= j.at) { j.done = true; j.s.textContent = j.c; j.s.classList.replace('jg', 'jk'); return; }
        if (now >= j.next) { j.s.textContent = glyph(j.c); j.next = now + 45 + Math.random() * 40; }
      });
      if (t < end + 260) setTimeout(tick, 30);
      else { node.textContent = text; delete node.dataset.real; }
    })();
  }

  function enterDetail() {
    unjumble(detail.querySelector('.head h2'), 60);
    let i = 0;
    [...detail.children].forEach(c => {
      if (c.classList.contains('counts')) {
        [...c.children].forEach(x => { x.style.setProperty('--i', i++); x.classList.add('in'); });
      } else if (c.classList.contains('hist')) {
        [...c.children].forEach((x, j) => { x.style.setProperty('--i', i + Math.min(j, 14)); x.classList.add('in'); });
        i++;
      } else {
        c.style.setProperty('--i', i++); c.classList.add('in');
      }
    });
    const cells = detail.querySelector('.cells');
    if (cells) { [...cells.children].forEach((c, j) => c.style.setProperty('--j', j)); cells.classList.add('wave'); }
  }

  function rollCounts(a, b) {
    detail.querySelectorAll('.cnt .v').forEach((v, k) => {
      if (a[k] === undefined || a[k] === b[k]) return;
      v.dataset.v = b[k];
      v.style.setProperty('--rd', num(b[k]) > num(a[k]) ? '100%' : '-100%');
      v.textContent = '';
      const nw = document.createElement('span'); nw.className = 'rv-new'; nw.textContent = b[k];
      const old = document.createElement('span'); old.className = 'rv-old'; old.textContent = a[k];
      old.setAttribute('aria-hidden', 'true');
      old.addEventListener('animationend', () => old.remove());
      v.append(nw, old);
      v.closest('.cnt').classList.add('hit');
    });
  }

  function movePuck(old) {
    const cur = detail.querySelector('.cell.cur'), cells = detail.querySelector('.cells');
    if (!cur || !cells) return;
    const dx = old ? old.x - cur.offsetLeft : 0;
    if (!dx) { cur.classList.add('landed'); return; }
    const pk = document.createElement('div');
    pk.className = 'cell-puck';
    pk.style.left = cur.offsetLeft + 'px';
    pk.style.width = cur.offsetWidth + 'px';
    cur.classList.add('landing');
    cells.appendChild(pk);
    pk.animate(
      [{ transform: `translateX(${dx}px)`, width: old.w + 'px' }, { transform: 'none', width: cur.offsetWidth + 'px' }],
      { duration: 460, easing: 'cubic-bezier(.34,1.3,.64,1)' }
    ).onfinish = () => { pk.remove(); cur.classList.remove('landing'); cur.classList.add('landed'); };
  }

  function railFlip(p, n) {
    const seen = {};
    let i = 0;
    rail.querySelectorAll('.pitem').forEach(it => {
      const k = keyOf(it, seen);
      if (it.classList.contains('dragging')) return;
      const o = p.pos.get(k);
      if (!o) {
        it.style.setProperty('--i', i);
        it.classList.add('in');
        unjumble(it.querySelector('.pnm'), Math.min(i++, 12) * 30);
        return;
      }
      const dx = o.x - it.offsetLeft, dy = o.y - it.offsetTop;
      if (dx || dy) {
        it.getAnimations().forEach(a => a.cancel());
        it.animate([{ transform: `translate(${dx}px,${dy}px)` }, { transform: 'none' }],
          { duration: 340, easing: 'cubic-bezier(.22,1,.36,1)' });
      }
      const dot = it.querySelector('.pdot');
      if (dot && p.dots.get(k) !== dot.style.background) dot.classList.add('ping');
      if (k === n.sel && p.sel !== n.sel) it.classList.add('sel-in');
    });
  }

  let prev = {
    pid: undefined, vals: [], verdict: null, cur: null, evs: new Map(), editor: false,
    strip: new Map(), hasStrip: false, badge: null, pos: new Map(), dots: new Map(), sel: null
  };

  function onRender() {
    const now = snapshot();
    if (!reduce.matches) {
      if (now.pid !== prev.pid) enterDetail();
      else {
        rollCounts(prev.vals, now.vals);
        const ver = detail.querySelector('.verdict');
        if (ver && prev.verdict && prev.verdict !== now.verdict) ver.classList.add('flip');
        if (prev.vals[2] !== now.vals[2]) movePuck(prev.cur);
        markFresh(detail.querySelectorAll('.ev'), prev.evs, evKey, 'fresh');
        const ed = detail.querySelector('.editor');
        if (ed && !prev.editor) ed.classList.add('in-ed');
      }
      if (now.hasStrip && !prev.hasStrip) strip.firstChild.classList.add('in');
      else if (now.hasStrip) {
        markFresh(strip.querySelectorAll('.srow'), prev.strip, srKey, 'fresh');
        const b = strip.querySelector('.badge');
        if (b && prev.badge !== now.badge) b.classList.add('bump');
      }
      railFlip(prev, now);
    }
    prev = now;
  }

  const mo = new MutationObserver(onRender);
  [detail, rail, strip].forEach(n => mo.observe(n, { childList: true }));

  // status message
  new MutationObserver(() => {
    if (!imsg.firstChild) return;
    imsg.classList.remove('in'); void imsg.offsetWidth; imsg.classList.add('in');
  }).observe(imsg, { childList: true });

  // help overlay close animation
  let closeT;
  new MutationObserver(recs => {
    const was = recs[0].oldValue || '';
    const isOpen = ov.classList.contains('open');
    // Only touch the class when it is actually there: classList.remove() rewrites the
    // attribute even when nothing changes, which re-triggers this observer forever.
    if (isOpen) { clearTimeout(closeT); if (ov.classList.contains('closing')) ov.classList.remove('closing'); return; }
    if (reduce.matches || !/\bopen\b/.test(was) || ov.classList.contains('closing')) return;
    ov.classList.add('closing');
    closeT = setTimeout(() => ov.classList.remove('closing'), 230);
  }).observe(ov, { attributes: true, attributeFilter: ['class'], attributeOldValue: true });

  // particle burst on logging / answering
  const layer = document.createElement('div');
  layer.className = 'fx-layer';
  document.body.appendChild(layer);
  function burst(x, y, col) {
    const ease = 'cubic-bezier(.16,1,.3,1)';
    const ring = document.createElement('div');
    ring.className = 'fx-ring';
    ring.style.cssText = `left:${x}px;top:${y}px;border-color:${col}`;
    layer.appendChild(ring);
    ring.animate([{ transform: 'scale(.4)', opacity: .9 }, { transform: 'scale(4.5)', opacity: 0 }],
      { duration: 560, easing: ease }).onfinish = () => ring.remove();
    for (let i = 0; i < 12; i++) {
      const p = document.createElement('div');
      p.className = 'fx-p';
      p.style.cssText = `left:${x}px;top:${y}px;background:${col}`;
      layer.appendChild(p);
      const ang = (i / 12) * Math.PI * 2 + Math.random() * .5;
      const dist = 26 + Math.random() * 36, s = .2 + Math.random() * .3;
      p.animate([
        { transform: 'translate(0,0) scale(1)', opacity: 1 },
        { transform: `translate(${Math.cos(ang) * dist}px,${Math.sin(ang) * dist + 12}px) scale(${s})`, opacity: 0 }
      ], { duration: 600 + Math.random() * 260, easing: ease }).onfinish = () => p.remove();
    }
  }
  document.addEventListener('click', e => {
    if (reduce.matches) return;
    const b = e.target.closest('.logger .grp .btn, .resolver .btn, .srow .grp .btn, #add');
    if (!b) return;
    if (b.id === 'add' && !$('nname').value.trim()) return;
    const t = b.textContent.toLowerCase();
    const col = b.id === 'add' ? 'var(--accent)'
      : /defect/.test(t) ? 'var(--neg)'
      : /cooperat/.test(t) ? 'var(--pos)' : 'var(--warn)';
    let x = e.clientX, y = e.clientY;
    if (!e.detail) { const r = b.getBoundingClientRect(); x = r.left + r.width / 2; y = r.top + r.height / 2; }
    burst(x, y, col);
  }, true);

  // header shadow on scroll
  addEventListener('scroll', () => top.classList.toggle('scrolled', scrollY > 4), { passive: true });

  // intro
  if (!reduce.matches) top.classList.add('in');
  onRender();
}
