import { HELP } from '../core/help-content.js';
import { mobile } from '../state.js';
import { $, el } from './dom.js';

export function helpBtn(key, label) {
  const b = el('button', 'q', '?');
  b.setAttribute('aria-label', label || 'help');
  b.onclick = e => { e.stopPropagation(); openHelp(key); };
  return b;
}

export function helpOpen() { return $('helpov').classList.contains('open'); }

let opener = null;

export function openHelp(key) {
  const h = HELP[key];
  if (!h) return;
  if (!helpOpen()) opener = document.activeElement;
  const box = $('helpbox');
  box.innerHTML = '';
  box.appendChild(el('h3', '', h.t));
  (h.p || []).forEach(x => box.appendChild(el('p', '', x)));
  (h.m || []).forEach(x => box.appendChild(el('p', 'm', x)));
  const c = el('button', 'btn close', 'Got it');
  c.onclick = closeHelp;
  box.appendChild(c);
  box.scrollTop = 0;
  $('helpov').classList.add('open');
  document.body.style.overflow = 'hidden';
  if (!mobile.matches) c.focus();
}

export function closeHelp() {
  $('helpov').classList.remove('open');
  document.body.style.overflow = '';
  // Hand keyboard focus back to whatever opened the dialog, if it is still on the page.
  if (opener && opener.isConnected && $('helpov').contains(document.activeElement)) opener.focus();
  opener = null;
}

export function initHelp() {
  $('helpov').onclick = e => { if (e.target === $('helpov')) closeHelp(); };
  $('qTop').onclick = () => openHelp('overview');
  $('qTol').onclick = () => openHelp('tolerance');
}
