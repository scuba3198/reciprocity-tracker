// JSON export, import (replace or merge), and the status message line.
import { state, commit, findPerson } from '../state.js';
import { normPerson, mergePeople } from '../core/model.js';
import { today, plural } from '../core/util.js';
import { $, el } from './dom.js';

export const EXPORT_VERSION = 14;

function msg(t, choice) {
  const m = $('imsg');
  m.innerHTML = '';
  if (!t) return;
  m.appendChild(el('span', '', t));
  if (choice) {
    [['Replace everything', 'replace'], ['Merge', 'merge'], ['Cancel', 'cancel']].forEach(([label, mode]) => {
      const b = el('button', 'btn sm', label);
      b.onclick = () => { if (mode === 'cancel') { state.incoming = null; msg(''); } else applyImport(mode); };
      m.appendChild(b);
    });
  }
}

function applyImport(mode) {
  if (!state.incoming) return;
  if (mode === 'replace') state.people = state.incoming;
  else mergePeople(state.people, state.incoming);
  state.incoming = null;
  state.editing = null;
  if (!findPerson(state.selected)) state.selected = state.people.length ? state.people[0].id : null;
  commit();
  msg('Imported.');
}

function exportJson() {
  const payload = { app: 'reciprocity-tracker', version: EXPORT_VERSION, model: 'CURE (Li et al. 2022)', exported: new Date().toISOString(), people: state.people };
  const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = 'reciprocity-tracker-' + today() + '.json';
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}

/** Parse an export file's text into normalised people, or return an error message. */
export function parseImport(text) {
  let data;
  try { data = JSON.parse(text); }
  catch (err) { return { error: 'That file is not valid JSON.' }; }
  const arr = Array.isArray(data) ? data : data && data.people;
  if (!Array.isArray(arr)) return { error: 'No list of people found in that file.' };
  const people = arr.map(x => normPerson(x, false)).filter(Boolean);
  if (!people.length) return { error: 'Nothing usable in that file.' };
  return { people };
}

export function initImportExport() {
  $('export').onclick = exportJson;
  $('importBtn').onclick = () => $('file').click();
  $('file').onchange = async e => {
    const f = e.target.files && e.target.files[0];
    e.target.value = '';
    if (!f) return;
    const { error, people } = parseImport(await f.text());
    if (error) { msg(error); return; }
    state.incoming = people;
    msg(people.length + ' ' + plural(people.length, 'person') + ' read from file.', true);
  };
}
