// People list: selection, search and reorder mode (drag + arrow buttons).
import { state, mobile, persist, render, select } from '../state.js';
import { stats } from '../core/cure.js';
import { signed, fold, byName } from '../core/util.js';
import { $, el } from './dom.js';
import { helpOpen } from './help.js';

function visiblePeople() {
  const q = fold(state.query.trim());
  if (state.reordering || !q) return state.people;
  return state.people.filter(p => fold(p.name).includes(q));
}

export function drawRail() {
  const { people, reordering, selected } = state;
  const r = $('rail');
  r.innerHTML = '';
  $('railbox').classList.toggle('reordering', reordering);
  $('railtools').hidden = !people.length;
  $('search').hidden = reordering;
  const rb = $('reorderBtn');
  rb.hidden = !reordering && people.length < 2;
  rb.textContent = reordering ? 'Done' : 'Reorder';
  rb.classList.toggle('primary', reordering);
  $('reobar').hidden = !reordering;

  if (!people.length) { r.appendChild(el('p', 'rail-empty', 'Nobody yet.')); return; }
  const list = visiblePeople();
  if (!list.length) { r.appendChild(el('p', 'rail-empty', 'No one matches “' + state.query.trim() + '”.')); return; }

  list.forEach((p, i) => {
    const { d } = stats(p);
    const coop = d <= p.delta;
    const dot = el('span', 'pdot');
    dot.style.background = coop ? 'var(--pos)' : 'var(--neg)';

    if (reordering) {
      const row = el('div', 'pitem reo' + (p.id === selected ? ' on' : ''));
      row.dataset.id = p.id;
      const grip = el('span', 'grip', '⋮⋮');
      grip.title = 'Drag to move';
      grip.setAttribute('aria-hidden', 'true');
      grip.addEventListener('pointerdown', e => startDrag(e, row));
      const up = el('button', 'mv up', '↑');
      up.type = 'button';
      up.disabled = i === 0;
      up.setAttribute('aria-label', 'Move ' + p.name + ' up');
      up.onclick = () => movePerson(p.id, -1);
      const dn = el('button', 'mv dn', '↓');
      dn.type = 'button';
      dn.disabled = i === list.length - 1;
      dn.setAttribute('aria-label', 'Move ' + p.name + ' down');
      dn.onclick = () => movePerson(p.id, 1);
      row.append(grip, dot, el('span', 'pnm', p.name), up, dn);
      r.appendChild(row);
      return;
    }

    const b = el('button', 'pitem' + (p.id === selected ? ' on' : ''));
    b.title = 'd = ' + signed(d) + ', Δ = ' + p.delta + ': rule says ' + (coop ? 'cooperate' : 'defect');
    b.append(dot, el('span', 'pnm', p.name), el('span', 'pval', 'd ' + signed(d) + ' · Δ ' + p.delta));
    b.onclick = () => { select(p.id); render(); };
    r.appendChild(b);
  });

  if (mobile.matches && !reordering) {
    const on = r.querySelector('.pitem.on');
    if (on && r.scrollHeight > r.clientHeight) {
      const top = on.offsetTop, bot = top + on.offsetHeight;
      if (top < r.scrollTop || bot > r.scrollTop + r.clientHeight) r.scrollTop = top - 4;
    }
  }
}

function movePerson(id, step) {
  const people = state.people;
  const i = people.findIndex(p => p.id === id), j = i + step;
  if (i < 0 || j < 0 || j >= people.length) return;
  [people[i], people[j]] = [people[j], people[i]];
  persist(); drawRail();
  // keep keyboard focus on the moved person
  const row = $('rail').querySelector('[data-id="' + id + '"]');
  if (!row) return;
  const same = row.querySelector('.mv.' + (step < 0 ? 'up' : 'dn'));
  const other = row.querySelector('.mv:not(:disabled)');
  if (same && !same.disabled) same.focus(); else if (other) other.focus();
}

function startDrag(e, row) {
  if (e.button !== undefined && e.button !== 0) return;
  e.preventDefault();
  const r = $('rail'), grip = e.currentTarget, box = $('railbox');
  try { grip.setPointerCapture(e.pointerId); } catch (err) {}
  row.classList.add('dragging');
  const move = ev => {
    if (!mobile.matches) { // auto-scroll the sidebar near its edges
      const bb = box.getBoundingClientRect();
      if (ev.clientY < bb.top + 40) box.scrollTop -= 12;
      else if (ev.clientY > bb.bottom - 40) box.scrollTop += 12;
    }
    let before = null;
    for (const it of r.querySelectorAll('.pitem:not(.dragging)')) {
      const b = it.getBoundingClientRect();
      if (ev.clientY < b.top + b.height / 2) { before = it; break; }
    }
    if (before) { if (row.nextSibling !== before) r.insertBefore(row, before); }
    else if (r.lastChild !== row) r.appendChild(row);
  };
  const end = () => {
    grip.removeEventListener('pointermove', move);
    grip.removeEventListener('pointerup', end);
    grip.removeEventListener('pointercancel', end);
    const ids = Array.from(r.querySelectorAll('.pitem')).map(x => x.dataset.id);
    state.people.sort((a, b) => ids.indexOf(a.id) - ids.indexOf(b.id));
    persist(); drawRail();
  };
  grip.addEventListener('pointermove', move);
  grip.addEventListener('pointerup', end);
  grip.addEventListener('pointercancel', end);
}

function reorderSort(cmp) { state.people.sort(cmp); persist(); drawRail(); }

export function initRail() {
  // search
  $('search').addEventListener('input', e => { state.query = e.target.value; drawRail(); });
  $('search').addEventListener('keydown', e => {
    if (e.key === 'Enter') {
      const l = visiblePeople();
      if (l.length) { select(l[0].id); render(); }
    } else if (e.key === 'Escape' && state.query) {
      e.stopPropagation();
      state.query = ''; e.target.value = ''; drawRail();
    }
  });
  document.addEventListener('keydown', e => {
    if (e.key !== '/' || e.metaKey || e.ctrlKey || e.altKey || helpOpen() || state.reordering) return;
    const t = e.target;
    if (t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.tagName === 'SELECT' || t.isContentEditable)) return;
    if ($('railtools').hidden) return;
    e.preventDefault();
    $('search').focus(); $('search').select();
  });

  // reorder mode
  $('reorderBtn').onclick = () => {
    if (!state.reordering) {
      state.reordering = true;
      state.orderSnap = state.people.map(p => p.id);
      state.query = ''; $('search').value = '';
    } else {
      state.reordering = false;
      state.orderSnap = null;
    }
    drawRail();
  };
  $('sortAZ').onclick = () => reorderSort(byName);
  $('sortD').onclick = () => reorderSort((a, b) => stats(b).d - stats(a).d || byName(a, b));
  $('revertOrder').onclick = () => {
    const snap = state.orderSnap;
    if (!snap) return;
    const pos = id => { const k = snap.indexOf(id); return k < 0 ? 1e9 : k; };
    reorderSort((a, b) => pos(a.id) - pos(b.id));
  };
}
