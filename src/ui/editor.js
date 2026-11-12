// Inline editor for one history entry.
import { state, render } from '../state.js';
import { effect } from '../core/cure.js';
import { signed } from '../core/util.js';
import { saveEdit, cancelEdit } from '../actions.js';
import { el, seg, effColor } from './dom.js';

export function drawEditor() {
  const st = state.editing;
  const box = el('div', 'editor');

  const r1 = el('div', 'r');
  const di = el('input');
  di.type = 'date'; di.value = st.date; di.setAttribute('aria-label', 'Date of the ask');
  di.onchange = () => { st.date = di.value; };
  const ni = el('input', 'grow');
  ni.placeholder = 'What was the ask? (optional)';
  ni.value = st.note;
  ni.setAttribute('data-edit-note', '');
  ni.oninput = () => { st.note = ni.value; };
  ni.onkeydown = e => { if (e.key === 'Enter') { e.preventDefault(); saveEdit(); } };
  r1.append(di, ni);

  const r2 = el('div', 'r');
  r2.append(el('span', 'lbl', 'Who asked'),
    seg([['theyAsked', 'They asked you'], ['iAsked', 'You asked them']], st.dir, v => { st.dir = v; render(); }));

  const r3 = el('div', 'r');
  r3.append(el('span', 'lbl', 'Outcome'),
    seg([
      ['yes', st.dir === 'theyAsked' ? 'You cooperated' : 'They cooperated'],
      ['no', st.dir === 'theyAsked' ? 'You defected' : 'They defected'],
      ['waiting', 'Not answered yet']
    ], st.outcome, v => { st.outcome = v; render(); }));

  const r4 = el('div', 'r acts');
  const prev = el('span', 'prev');
  if (st.outcome === 'waiting') prev.textContent = 'Effect on d: none until answered';
  else {
    const f = effect(st);
    prev.append(document.createTextNode('Effect on d: '));
    const b = el('b', '', signed(f));
    b.style.color = effColor(f);
    prev.appendChild(b);
  }
  const sv = el('button', 'btn primary sm', 'Save');
  sv.onclick = saveEdit;
  const cn = el('button', 'btn quiet sm', 'Cancel');
  cn.onclick = cancelEdit;
  r4.append(prev, cn, sv);

  box.append(r1, r2, r3, r4);
  return box;
}
