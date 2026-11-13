// JSON export and import (replace or merge).
import { state, commit, findPerson } from '../state.js';
import { normPerson, mergePeople } from '../core/model.js';
import { backupBeforeImport } from '../core/storage.js';
import { today, plural } from '../core/util.js';
import { $ } from './dom.js';
import { notify } from './status.js';

export const EXPORT_VERSION = 14;

function fixSelection() {
  if (!findPerson(state.selected)) state.selected = state.people.length ? state.people[0].id : null;
}

function applyImport(mode) {
  if (!state.incoming) return;
  // Keep the pre-import data, in storage and for the Undo button. Merge mutates in place, so copy it.
  const before = JSON.parse(JSON.stringify(state.people));
  backupBeforeImport(before);
  if (mode === 'replace') state.people = state.incoming;
  else mergePeople(state.people, state.incoming);
  state.incoming = null;
  state.editing = null;
  fixSelection();
  commit();
  notify(mode === 'replace' ? 'Replaced everything with the file.' : 'Merged the file in.', [['Undo', () => {
    state.people = before;
    state.editing = null;
    fixSelection();
    commit();
    notify('Import undone.');
  }]]);
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
    if (error) { notify(error); return; }
    state.incoming = people;
    notify(people.length + ' ' + plural(people.length, 'person') + ' read from file.', [
      ['Replace everything', () => applyImport('replace')],
      ['Merge', () => applyImport('merge')],
      ['Cancel', () => { state.incoming = null; }]
    ]);
  };
}
