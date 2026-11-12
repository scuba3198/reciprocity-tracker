import { state, commit } from '../state.js';
import { DEFAULT_DELTA, clampDelta } from '../core/cure.js';
import { uid } from '../core/util.js';
import { $ } from './dom.js';

export function initAddPerson() {
  $('add').onclick = () => {
    const n = $('nname').value.trim();
    if (!n) { $('nname').focus(); return; }
    const id = 'p' + uid();
    state.people.push({ id, name: n, delta: clampDelta($('ndelta').value), events: [] });
    $('nname').value = '';
    $('ndelta').value = DEFAULT_DELTA;
    state.editing = null;
    state.selected = id;
    state.query = ''; $('search').value = '';
    commit();
  };
  $('nname').addEventListener('keydown', e => { if (e.key === 'Enter') $('add').click(); });
}
