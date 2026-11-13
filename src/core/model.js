// Data normalisation (also migrates older versions).
import { DEFAULT_DELTA, clampDelta } from './cure.js';
import { today, uid } from './util.js';

export function normEvent(ev) {
  if (!ev || (ev.dir !== 'iAsked' && ev.dir !== 'theyAsked')) return null;
  let outcome = ev.outcome;
  let note = typeof ev.note === 'string' ? ev.note : '';
  if (outcome === 'couldnt') { // paper: an unintended defection is still a defection
    outcome = 'no';
    note = note ? note + " (couldn't)" : "couldn't";
  }
  if (outcome !== 'yes' && outcome !== 'no' && outcome !== 'waiting') return null;
  return {
    id: typeof ev.id === 'string' ? ev.id : uid(),
    dir: ev.dir,
    outcome,
    note,
    date: typeof ev.date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(ev.date) ? ev.date : today(),
    t: typeof ev.t === 'number' ? ev.t : Date.now()
  };
}

export function normPerson(x, keepId) {
  if (!x || typeof x.name !== 'string' || !x.name.trim() || !Array.isArray(x.events)) return null;
  return {
    id: keepId && typeof x.id === 'string' ? x.id : 'p' + uid(),
    name: x.name.trim(),
    delta: x.delta === undefined ? DEFAULT_DELTA : clampDelta(x.delta),
    events: uniqueIds(x.events.map(normEvent).filter(Boolean))
  };
}

/** Give any event whose id is already taken a fresh one. Edit, resolve and delete look events up by id. */
function uniqueIds(events, taken = new Set()) {
  events.forEach(ev => {
    while (taken.has(ev.id)) ev.id = uid();
    taken.add(ev.id);
  });
  return events;
}

/** Merge imported people into existing ones by name, skipping duplicate events. Mutates `people`. */
export function mergePeople(people, incoming) {
  incoming.forEach(imp => {
    const ex = people.find(p => p.name.toLowerCase() === imp.name.toLowerCase());
    if (!ex) { people.push(imp); return; }
    const taken = new Set(ex.events.map(x => x.id));
    imp.events.forEach(ev => {
      const dup = ex.events.some(x => x.date === ev.date && x.dir === ev.dir && x.outcome === ev.outcome && x.note === ev.note);
      if (dup) return;
      uniqueIds([ev], taken);
      ex.events.push(ev);
    });
  });
  return people;
}

export function outLabel(dir, outcome) {
  if (dir === 'theyAsked') return outcome === 'yes' ? 'you cooperated' : outcome === 'no' ? 'you defected' : 'awaiting your answer';
  return outcome === 'yes' ? 'they cooperated' : outcome === 'no' ? 'they defected' : 'awaiting their answer';
}
