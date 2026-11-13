// The status message line above the detail pane, with optional action buttons.
import { $, el } from './dom.js';

/** Show `text` with buttons, each `[label, onClick]`. A button clears the line before running. Empty text clears it. */
export function notify(text, actions = []) {
  const m = $('imsg');
  m.innerHTML = '';
  if (!text) return;
  m.appendChild(el('span', '', text));
  actions.forEach(([label, fn]) => {
    const b = el('button', 'btn sm', label);
    b.onclick = () => { notify(''); fn(); };
    m.appendChild(b);
  });
}

/**
 * A short message pinned to the bottom of the screen with one action, e.g. Undo.
 * Used where the status line may be scrolled out of view. Hides itself after a few seconds.
 */
let toastT;
export function toast(text, [label, fn]) {
  let t = $('toast');
  if (!t) {
    t = el('div', 'toast');
    t.id = 'toast';
    t.setAttribute('role', 'status');
    document.body.appendChild(t);
  }
  clearTimeout(toastT);
  t.innerHTML = '';
  const b = el('button', 'btn sm', label);
  b.onclick = () => { clearTimeout(toastT); t.hidden = true; fn(); };
  t.append(el('span', '', text), b);
  t.hidden = false;
  toastT = setTimeout(() => { t.hidden = true; }, 8000);
}

/** Show or hide the "changes aren't being saved" warning. */
export function drawSaveWarning(failed) {
  $('savewarn').hidden = !failed;
}
