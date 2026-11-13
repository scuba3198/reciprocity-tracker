// Selected person's view: header, counts, verdict, number line, logger, history.
import { state, mobile, findPerson, dstate, commit } from '../state.js';
import { MAX_DELTA, clampDelta, stats, effect, explain } from '../core/cure.js';
import { signed, plural, sd, today } from '../core/util.js';
import { outLabel } from '../core/model.js';
import { log, resolve, del, startEdit, deletePerson, clearHistory } from '../actions.js';
import { $, el, effColor } from './dom.js';
import { helpBtn, openHelp } from './help.js';
import { drawEditor } from './editor.js';
import { toast } from './status.js';

function header(p) {
  const head = el('div', 'head');
  const hl = el('div');
  const meta = el('div', 'meta');
  const tl = el('label', '', 'Tolerance Δ');
  const tol = el('input');
  tol.type = 'number'; tol.min = 0; tol.max = MAX_DELTA; tol.step = 1; tol.value = p.delta;
  tol.inputMode = 'numeric';
  tol.id = 'tol-' + p.id; tl.htmlFor = tol.id;
  tol.onchange = () => { p.delta = clampDelta(tol.value); commit(); };
  const answered = p.events.filter(e => e.outcome !== 'waiting').length;
  meta.append(tl, tol, helpBtn('tolerance', 'What tolerance means'), el('span', '', '· ' + answered + ' answered ' + plural(answered, 'ask')));
  hl.append(el('h2', '', p.name), meta);
  const rm = el('button', 'btn quiet sm', 'Delete person');
  rm.onclick = () => { if (confirm('Delete ' + p.name + ' and all their entries?')) deletePerson(p.id); };
  head.append(hl, rm);
  return head;
}

function counts({ nA, nB, d }) {
  const box = el('div', 'counts');
  function cnt(k, v, sub, helpKey) {
    const c = el('div', 'cnt');
    const kk = el('div', 'k');
    kk.appendChild(el('span', '', k));
    if (helpKey) kk.appendChild(helpBtn(helpKey));
    c.append(kk, el('div', 'v', v), el('div', 's', sub));
    return c;
  }
  box.append(
    cnt('They defected', String(nB), 'n_B'),
    cnt('You defected', String(nA), 'n_A'),
    cnt('Difference d', signed(d), 'n_B − n_A', 'counts')
  );
  return box;
}

function verdict(d, D) {
  const coop = d <= D;
  const v = el('div', 'verdict ' + (coop ? 'yes' : 'no'));
  const vt = el('div', 'vt');
  vt.append(el('span', 'big', coop ? 'Their next ask: cooperate' : 'Their next ask: defect'), helpBtn('rule', 'What to do next'));
  v.appendChild(vt);
  const { why, note } = explain(d, D);
  v.appendChild(el('div', 'why', why));
  if (note) v.appendChild(el('div', 'why2', note));
  return v;
}

function numberLine(d, D) {
  const line = el('div', 'line');
  const cells = el('div', 'cells');
  const span = Math.max(D + 3, Math.abs(d) + 2, 5);
  let lo = -span, hi = span;
  const MAXC = 15;
  if (mobile.matches && hi - lo + 1 > MAXC) {
    // keep d and the cooperate/defect boundary in view when they fit together
    const a = Math.min(d, D), b = Math.max(d, D + 1);
    const mid = (b - a + 1 <= MAXC - 2) ? Math.round((a + b) / 2) : d;
    lo = mid - 7; hi = mid + 7;
  }
  const total = hi - lo + 1;
  const showAll = total <= (mobile.matches ? 13 : 25);
  for (let x = lo; x <= hi; x++) {
    if (x === D + 1) cells.appendChild(el('div', 'sep'));
    const c = el('div', 'cell ' + (x <= D ? 'y' : 'n') + (x === d ? ' cur' : '') + (x === 0 ? ' zero' : ''));
    if (showAll || x === 0 || x === d || x === D) c.textContent = signed(x);
    c.title = 'd = ' + signed(x) + ': rule says ' + (x <= D ? 'cooperate' : 'defect');
    cells.appendChild(c);
  }
  const sc = el('div', 'scale');
  sc.append(el('span', '', '← you have defected more'), el('span', '', 'even'), el('span', '', 'they have defected more →'));
  line.append(cells, sc);
  return line;
}

function logger(p, coop) {
  const s = dstate(p.id);
  const box = el('div', 'logger');
  const r1 = el('div', 'r');
  const dateIn = el('input');
  dateIn.type = 'date'; dateIn.value = s.date || today(); dateIn.setAttribute('aria-label', 'Date of the ask');
  dateIn.onchange = () => { s.date = dateIn.value === today() ? '' : dateIn.value; };
  const noteIn = el('input', 'in-note');
  noteIn.placeholder = 'What was the ask? (optional)';
  noteIn.value = s.note;
  noteIn.oninput = () => { s.note = noteIn.value; };
  r1.append(dateIn, noteIn);
  box.appendChild(r1);

  [
    ['They asked you', 'theyAsked', [['yes', 'You cooperated'], ['no', 'You defected'], ['waiting', 'Not answered yet']]],
    ['You asked them', 'iAsked', [['yes', 'They cooperated'], ['no', 'They defected'], ['waiting', 'No answer yet']]]
  ].forEach(([label, dir, opts], idx) => {
    const r = el('div', 'r out');
    const t = el('span', 'tag');
    t.appendChild(el('span', '', label));
    if (idx === 0) t.appendChild(helpBtn('logging', 'How logging works'));
    const g = el('div', 'grp');
    opts.forEach(([o, txt]) => {
      const rec = dir === 'theyAsked' && o !== 'waiting' && ((o === 'yes') === coop);
      const b = el('button', 'btn' + (o === 'waiting' ? ' wait' : '') + (rec ? ' rec' : ''), txt);
      if (rec) b.appendChild(el('span', 'rtag', 'rule'));
      b.onclick = () => log(p.id, dir, o);
      g.appendChild(b);
    });
    r.append(t, g);
    box.appendChild(r);
  });
  const lf = el('div', 'r foot');
  const why1 = el('button', 'linkish', 'Why does every defection count as 1, even a genuine "couldn\'t"?');
  why1.onclick = () => openHelp('errors');
  lf.appendChild(why1);
  box.appendChild(lf);
  return box;
}

function history(p, coop) {
  const hist = el('div', 'hist');
  const hh = el('div', 'hh');
  hh.append(el('h3', '', 'History'), helpBtn('history'));
  hist.appendChild(hh);
  const ordered = p.events.slice().sort((a, b) => {
    const aw = a.outcome === 'waiting' ? 0 : 1, bw = b.outcome === 'waiting' ? 0 : 1;
    if (aw !== bw) return aw - bw;
    return (b.date || '').localeCompare(a.date || '') || b.t - a.t;
  });
  ordered.forEach(ev => {
    if (state.editing && state.editing.eid === ev.id) {
      hist.appendChild(drawEditor());
      return;
    }
    const pend = ev.outcome === 'waiting';
    const row = el('div', 'ev' + (pend ? ' pend' : ''));
    const tx = el('span', 'tx');
    tx.append(el('span', 'dir', ev.dir === 'theyAsked' ? 'They asked: ' : 'You asked: '), document.createTextNode(ev.note || '—'));
    const res = el('span', 'res', outLabel(ev.dir, ev.outcome));
    const f = effect(ev);
    const eff = el('span', 'eff', pend ? '' : signed(f));
    eff.style.color = effColor(f);
    eff.title = f > 0 ? 'they defected: d +1' : f < 0 ? 'you defected: d −1' : pend ? 'not counted until answered' : 'cooperation: no effect';
    const ed = el('button', 'ed', '✎');
    ed.title = 'Edit this entry';
    ed.setAttribute('aria-label', 'Edit this entry');
    ed.onclick = () => startEdit(p.id, ev);
    const x = el('button', 'x', '×');
    x.title = 'Delete this entry';
    x.setAttribute('aria-label', 'Delete this entry');
    x.onclick = () => {
      const undo = del(p.id, ev.id);
      if (undo) toast('Entry deleted.', ['Undo', undo]);
    };
    row.append(el('span', 'dt', sd(ev.date)), tx, res, eff, ed, x);
    hist.appendChild(row);
    if (pend) {
      const rr = el('div', 'resolver');
      rr.appendChild(el('span', 'tag', 'Answer:'));
      ['yes', 'no'].forEach(o => {
        const rec = ev.dir === 'theyAsked' && ((o === 'yes') === coop);
        const b = el('button', 'btn sm' + (rec ? ' rec' : ''), outLabel(ev.dir, o));
        b.onclick = () => resolve(p.id, ev.id, o);
        rr.appendChild(b);
      });
      hist.appendChild(rr);
    }
  });
  return hist;
}

function historyFooter(p) {
  const foot = el('div');
  foot.style.cssText = 'margin-top:22px;display:flex;gap:8px;align-items:center';
  const clr = el('button', 'btn sm quiet', 'Clear all history');
  clr.onclick = () => { if (confirm('Delete every entry for ' + p.name + '? This cannot be undone.')) clearHistory(p.id); };
  foot.appendChild(clr);
  return foot;
}

function focusEditorIfRequested(root) {
  if (!state.focusEditor) return;
  state.focusEditor = false;
  const ed = root.querySelector('.editor');
  if (!ed) return;
  if (mobile.matches) ed.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
  else { const n = ed.querySelector('[data-edit-note]'); if (n) { n.focus(); n.setSelectionRange(n.value.length, n.value.length); } }
}

export function drawDetail() {
  const root = $('detail');
  root.innerHTML = '';
  const p = findPerson(state.selected);
  if (!p) {
    root.appendChild(el('div', 'placeholder', state.people.length ? (mobile.matches ? 'Pick someone above.' : 'Pick someone on the left.') : 'Add someone to start tracking.'));
    return;
  }
  if (state.editing && state.editing.pid !== p.id) state.editing = null;
  const st = stats(p);
  const coop = st.d <= p.delta;

  root.append(header(p), counts(st), verdict(st.d, p.delta), numberLine(st.d, p.delta), logger(p, coop));
  if (p.events.length) root.append(history(p, coop), historyFooter(p));
  focusEditorIfRequested(root);
}
