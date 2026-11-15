import { normPerson } from './model.js';

export const KEY = 'cure_tracker_v14';
const OLD_KEYS = ['cure_tracker_v13'];

export const BACKUP_KEY = KEY + '_unreadable';

function parse(raw) {
  const arr = JSON.parse(raw);
  if (!Array.isArray(arr)) throw new Error('stored data is not a list');
  return arr.map(p => normPerson(p, true)).filter(Boolean);
}

// Reading `localStorage` itself throws when the browser blocks site data, so every function
// resolves it inside its own try rather than as a default parameter.
export function load(storage) {
  let cur = null;
  try {
    storage = storage ?? globalThis.localStorage;
    cur = storage.getItem(KEY);
    if (cur) return parse(cur);
    for (const k of OLD_KEYS) {
      const old = storage.getItem(k);
      if (old) {
        const migrated = parse(old);
        // A refused write must not hide the data that was just read.
        try { storage.setItem(KEY, JSON.stringify(migrated)); } catch (e) {}
        return migrated;
      }
    }
  } catch (e) {
    // Unreadable data would be overwritten by the next save; keep a copy so it can be recovered.
    try { if (cur) storage.setItem(BACKUP_KEY, cur); } catch (e2) {}
  }
  return [];
}

/** Data as it was before the last import, so a bad Replace can be recovered. */
export const IMPORT_BACKUP_KEY = KEY + '_before_import';

/** Returns false when the browser refused the write (storage full, blocked or unavailable). */
export function save(people, storage) {
  try { (storage ?? globalThis.localStorage).setItem(KEY, JSON.stringify(people)); return true; } catch (e) { return false; }
}

export function backupBeforeImport(people, storage) {
  try { (storage ?? globalThis.localStorage).setItem(IMPORT_BACKUP_KEY, JSON.stringify(people)); return true; } catch (e) { return false; }
}
