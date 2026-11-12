// Single shared app state plus a render hook. UI modules read and mutate `state`,
// then call `commit()` (persist + redraw) or `render()` (redraw only).
import { load, save } from './core/storage.js';
import { today } from './core/util.js';

const people = load();

export const state = {
  people,
  selected: people.length ? people[0].id : null,
  draft: {},          // per-person logger inputs: { [pid]: { date, note } }
  incoming: null,     // people parsed from an import file, awaiting replace/merge
  editing: null,      // { pid, eid, date, note, dir, outcome }
  focusEditor: false,
  query: '',          // people search
  reordering: false,  // reorder mode on/off
  orderSnap: null     // order when reorder mode was entered (for Revert)
};

export const mobile = window.matchMedia('(max-width: 880px)');

let renderFn = () => {};
export function setRenderer(fn) { renderFn = fn; }
export function render() { renderFn(); }
export function persist() { save(state.people); }
export function commit() { persist(); render(); }

export function findPerson(id) { return state.people.find(x => x.id === id); }
export function dstate(id) {
  if (!state.draft[id]) state.draft[id] = { date: today(), note: '' };
  return state.draft[id];
}
export function select(id) {
  if (state.selected !== id) state.editing = null;
  state.selected = id;
}
