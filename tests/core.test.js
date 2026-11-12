import test from 'node:test';
import assert from 'node:assert/strict';
import { clampDelta, effect, stats, ruleCooperates, explain, DEFAULT_DELTA, MAX_DELTA } from '../src/core/cure.js';
import { normEvent, normPerson, mergePeople } from '../src/core/model.js';
import { load, save, KEY } from '../src/core/storage.js';
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
