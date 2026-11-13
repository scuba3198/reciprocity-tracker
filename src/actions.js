// State mutations triggered by the UI. Each one persists and redraws.
import { state, commit, render, findPerson, dstate } from './state.js';
import { today, uid } from './core/util.js';

export function log(pid, dir, outcome) {
  const p = findPerson(pid); if (!p) return;
  const s = dstate(pid);
  p.events.push({ id: uid(), dir, outcome, note: s.note.trim(), date: s.date || today(), t: Date.now() });
  s.note = '';
  commit();
}

export function resolve(pid, eid, outcome) {
  const p = findPerson(pid); if (!p) return;
  const e = p.events.find(x => x.id === eid); if (!e) return;
  e.outcome = outcome;
  commit();
}

/** Delete an entry. Returns a function that puts it back where it was, or null if nothing was deleted. */
export function del(pid, eid) {
  const p = findPerson(pid); if (!p) return null;
  const at = p.events.findIndex(x => x.id === eid); if (at < 0) return null;
  const [gone] = p.events.splice(at, 1);
  if (state.editing && state.editing.eid === eid) state.editing = null;
  commit();
  return () => {
    // Look the person up again: the list may have been replaced (import, another tab) since.
    const q = findPerson(pid);
    if (!q || q.events.some(x => x.id === gone.id)) return;
    q.events.splice(Math.min(at, q.events.length), 0, gone);
    commit();
  };
}

export function startEdit(pid, ev) {
  state.editing = { pid, eid: ev.id, date: ev.date, note: ev.note || '', dir: ev.dir, outcome: ev.outcome };
  state.focusEditor = true;
  render();
}

export function saveEdit() {
  const ed = state.editing;
  if (!ed) return;
  const p = findPerson(ed.pid);
  const e = p && p.events.find(x => x.id === ed.eid);
  if (e) {
    e.date = /^\d{4}-\d{2}-\d{2}$/.test(ed.date) ? ed.date : e.date;
    e.note = ed.note.trim();
    e.dir = ed.dir;
    e.outcome = ed.outcome;
  }
  state.editing = null;
  commit();
}

export function cancelEdit() { state.editing = null; render(); }

export function deletePerson(pid) {
  state.people = state.people.filter(x => x.id !== pid);
  delete state.draft[pid];
  state.editing = null;
  state.selected = state.people.length ? state.people[0].id : null;
  commit();
}

export function clearHistory(pid) {
  const p = findPerson(pid); if (!p) return;
  p.events = [];
  state.editing = null;
  commit();
}
