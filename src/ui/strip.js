// "Waiting on you": unanswered requests from anyone, oldest first.
import { state } from '../state.js';
import { ruleCooperates } from '../core/cure.js';
import { sd, age } from '../core/util.js';
import { resolve } from '../actions.js';
import { $, el } from './dom.js';
import { helpBtn } from './help.js';

export function drawStrip() {
  const w = $('stripwrap');
  w.innerHTML = '';
  const rows = [];
  state.people.forEach(p => p.events.forEach(e => {
    if (e.outcome === 'waiting' && e.dir === 'theyAsked') rows.push({ p, e });
  }));
  if (!rows.length) return;
  rows.sort((a, b) => (a.e.date || '').localeCompare(b.e.date || '') || a.e.t - b.e.t);
  const box = el('div', 'strip');
  const sh = el('div', 'sh');
  sh.append(el('span', 't', 'Waiting on you'), el('span', 'badge', String(rows.length)), helpBtn('pending'));
  box.appendChild(sh);
  rows.forEach(({ p, e }) => {
    const coop = ruleCooperates(p);
    const row = el('div', 'srow');
    row.append(el('span', 'who', p.name), el('span', 'dt', sd(e.date)), el('span', 'tx', e.note || '—'));
    const a = age(e);
    if (a >= 5) row.appendChild(el('span', 'cold', a + 'd old'));
    row.appendChild(el('span', 'pill ' + (coop ? 'yes' : 'no'), 'rule: ' + (coop ? 'cooperate' : 'defect')));
    const g = el('div', 'grp');
    [['yes', 'Cooperate'], ['no', 'Defect']].forEach(([o, label]) => {
      const rec = (o === 'yes') === coop;
      const b = el('button', 'btn sm' + (rec ? ' rec' : ''), label);
      b.onclick = () => resolve(p.id, e.id, o);
      g.appendChild(b);
    });
    row.appendChild(g);
    box.appendChild(row);
  });
  w.appendChild(box);
}
