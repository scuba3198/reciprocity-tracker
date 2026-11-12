import { normPerson } from './model.js';

export const KEY = 'cure_tracker_v14';
const OLD_KEYS = ['cure_tracker_v13'];

export function load(storage = globalThis.localStorage) {
  try {
    const cur = storage.getItem(KEY);
    if (cur) return (JSON.parse(cur) || []).map(p => normPerson(p, true)).filter(Boolean);
    for (const k of OLD_KEYS) {
      const old = storage.getItem(k);
      if (old) {
        const migrated = (JSON.parse(old) || []).map(p => normPerson(p, true)).filter(Boolean);
        storage.setItem(KEY, JSON.stringify(migrated));
        return migrated;
      }
    }
  } catch (e) {}
  return [];
}

export function save(people, storage = globalThis.localStorage) {
  try { storage.setItem(KEY, JSON.stringify(people)); } catch (e) {}
}
