import test from 'node:test';
import assert from 'node:assert/strict';
import { clampDelta, effect, stats, ruleCooperates, explain, DEFAULT_DELTA, MAX_DELTA } from '../src/core/cure.js';
import { normEvent, normPerson, mergePeople } from '../src/core/model.js';
import { load, save, backupBeforeImport, KEY, BACKUP_KEY, IMPORT_BACKUP_KEY } from '../src/core/storage.js';
import { signed, sd, fold } from '../src/core/util.js';

const ev = (dir, outcome, extra = {}) => ({ id: Math.random().toString(36), dir, outcome, note: '', date: '2026-01-01', t: 0, ...extra });

test('effect: only defections move d', () => {
  assert.equal(effect(ev('iAsked', 'no')), 1);
  assert.equal(effect(ev('theyAsked', 'no')), -1);
  assert.equal(effect(ev('iAsked', 'yes')), 0);
  assert.equal(effect(ev('theyAsked', 'waiting')), 0);
});

test('stats and the CURE rule', () => {
  const p = { delta: 1, events: [ev('iAsked', 'no'), ev('iAsked', 'no'), ev('theyAsked', 'no'), ev('iAsked', 'yes')] };
  assert.deepEqual(stats(p), { nA: 1, nB: 2, d: 1 });
  assert.equal(ruleCooperates(p), true);           // d = 1 ≤ Δ = 1
  p.events.push(ev('iAsked', 'no'));
  assert.equal(ruleCooperates(p), false);          // d = 2 > Δ = 1
});

test('clampDelta', () => {
  assert.equal(clampDelta('x'), DEFAULT_DELTA);
  assert.equal(clampDelta(-3), 0);
  assert.equal(clampDelta(99), MAX_DELTA);
  assert.equal(clampDelta('3'), 3);
});

test('explain', () => {
  assert.match(explain(1, 1).why, /on the line/);
  assert.match(explain(3, 1).why, /After 2 defections/);
  assert.equal(explain(0, 1).note, null);
  assert.match(explain(-2, 1).note, /defected 2 more times/);
});

test('normEvent migrates "couldnt" into a defection and rejects junk', () => {
  const e = normEvent({ dir: 'iAsked', outcome: 'couldnt', note: 'sick' });
  assert.equal(e.outcome, 'no');
  assert.equal(e.note, "sick (couldn't)");
  assert.equal(normEvent({ dir: 'sideways', outcome: 'yes' }), null);
  assert.equal(normEvent({ dir: 'iAsked', outcome: 'maybe' }), null);
});

test('normPerson validates and fills defaults', () => {
  assert.equal(normPerson({ name: '  ', events: [] }), null);
  const p = normPerson({ id: 'p1', name: ' Ana ', events: [{ dir: 'iAsked', outcome: 'yes' }] }, true);
  assert.equal(p.id, 'p1');
  assert.equal(p.name, 'Ana');
  assert.equal(p.delta, DEFAULT_DELTA);
  assert.equal(p.events.length, 1);
  assert.notEqual(normPerson({ id: 'p1', name: 'Ana', events: [] }, false).id, 'p1');
});

test('mergePeople matches by name and skips duplicate events', () => {
  const people = [{ id: 'a', name: 'Ana', delta: 1, events: [ev('iAsked', 'no', { note: 'x' })] }];
  mergePeople(people, [
    { id: 'b', name: 'ana', delta: 1, events: [ev('iAsked', 'no', { note: 'x' }), ev('theyAsked', 'yes')] },
    { id: 'c', name: 'Bo', delta: 2, events: [] }
  ]);
  assert.equal(people.length, 2);
  assert.equal(people[0].events.length, 2);
});

test('storage round-trips and migrates from v13', () => {
  const mem = new Map();
  const storage = { getItem: k => mem.get(k) ?? null, setItem: (k, v) => mem.set(k, v) };
  mem.set('cure_tracker_v13', JSON.stringify([{ id: 'p1', name: 'Ana', events: [] }]));
  const loaded = load(storage);
  assert.equal(loaded[0].name, 'Ana');
  assert.ok(mem.has(KEY));
  loaded[0].delta = 3;
  save(loaded, storage);
  assert.equal(load(storage)[0].delta, 3);
});

test('formatting helpers', () => {
  assert.equal(signed(2), '+2');
  assert.equal(signed(-2), '−2');
  assert.equal(signed(0), '0');
  assert.equal(sd('2026-11-12'), '12/11');
  assert.equal(fold('Ñandú'), 'nandu');
});

test('merge keeps the local copy of an event the file also has (re-importing an old export after an edit)', () => {
  const people = [{ id: 'a', name: 'Ana', delta: 1, events: [
    ev('theyAsked', 'yes', { id: 'e1' }),
    ev('iAsked', 'no', { id: 'e2', note: 'edited' })
  ] }];
  // The export had e1 unanswered and e2 with its old note. Neither is a second event.
  mergePeople(people, [{ id: 'b', name: 'Ana', delta: 1, events: [
    ev('theyAsked', 'waiting', { id: 'e1' }),
    ev('iAsked', 'no', { id: 'e2', note: 'original' })
  ] }]);
  assert.deepEqual(people[0].events.map(e => [e.id, e.outcome, e.note]), [['e1', 'yes', ''], ['e2', 'no', 'edited']]);
});

test('merge keeps identical events that are genuinely separate', () => {
  const people = [{ id: 'a', name: 'Ana', delta: 1, events: [] }];
  mergePeople(people, [{ id: 'b', name: 'Ana', delta: 1, events: [ev('iAsked', 'no'), ev('iAsked', 'no')] }]);
  assert.equal(people[0].events.length, 2);
  // Same content but logged at a different time is also a separate event.
  mergePeople(people, [{ id: 'c', name: 'Ana', delta: 1, events: [ev('iAsked', 'no', { t: 5 })] }]);
  assert.equal(people[0].events.length, 3);
});

test('merge gives an imported event a fresh id when its id is taken by another merged event', () => {
  const people = [{ id: 'a', name: 'Ana', delta: 1, events: [ev('iAsked', 'yes', { id: 'e1' })] }];
  mergePeople(people, [{ id: 'b', name: 'Ana', delta: 1, events: [ev('iAsked', 'no', { id: 'n1' }), ev('theyAsked', 'no', { id: 'n1' })] }]);
  const ids = people[0].events.map(e => e.id);
  assert.equal(ids.length, 3);
  assert.equal(new Set(ids).size, 3);
});

test('normPerson de-duplicates event ids within a person', () => {
  const p = normPerson({ name: 'Ana', events: [{ id: 'x', dir: 'iAsked', outcome: 'yes' }, { id: 'x', dir: 'iAsked', outcome: 'no' }] });
  assert.equal(new Set(p.events.map(e => e.id)).size, 2);
});

test('save reports whether the browser stored the data; import backup is kept separately', () => {
  const mem = new Map();
  const ok = { getItem: k => mem.get(k) ?? null, setItem: (k, v) => mem.set(k, v) };
  const full = { getItem: () => null, setItem: () => { throw new Error('QuotaExceededError'); } };
  assert.equal(save([], ok), true);
  assert.equal(save([], full), false);
  assert.equal(backupBeforeImport([{ name: 'Ana' }], ok), true);
  assert.equal(JSON.parse(mem.get(IMPORT_BACKUP_KEY))[0].name, 'Ana');
  assert.equal(backupBeforeImport([], full), false);
});

test('unreadable storage is backed up instead of being lost on the next save', () => {
  const mem = new Map();
  const storage = { getItem: k => mem.get(k) ?? null, setItem: (k, v) => mem.set(k, v) };
  mem.set(KEY, '{"people": oops');
  assert.deepEqual(load(storage), []);
  assert.equal(mem.get(BACKUP_KEY), '{"people": oops');
  mem.set(KEY, '{"not":"a list"}');
  assert.deepEqual(load(storage), []);
  assert.equal(mem.get(BACKUP_KEY), '{"not":"a list"}');
});
