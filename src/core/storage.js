import { normPerson } from './model.js';

export const KEY = 'cure_tracker_v14';
const OLD_KEYS = ['cure_tracker_v13'];

export const BACKUP_KEY = KEY + '_unreadable';

function parse(raw) {
  const arr = JSON.parse(raw);
  if (!Array.isArray(arr)) throw new Error('stored data is not a list');
  return arr.map(p => normPerson(p, true)).filter(Boolean);
}

export function load(storage = globalThis.localStorage) {
  let cur = null;
  try {
    cur = storage.getItem(KEY);
    if (cur) return parse(cur);
    for (const k of OLD_KEYS) {
      const old = storage.getItem(k);
      if (old) {
        const migrated = parse(old);
        storage.setItem(KEY, JSON.stringify(migrated));
        return migrated;
      }
    }
  } catch (e) {
    // Unreadable data would be overwritten by the next save; keep a copy so it can be recovered.
    try { if (cur) storage.setItem(BACKUP_KEY, cur); } catch (e2) {}
  }
  return [];
}

export function save(people, storage = globalThis.localStorage) {
  try { storage.setItem(KEY, JSON.stringify(people)); } catch (e) {}
}
