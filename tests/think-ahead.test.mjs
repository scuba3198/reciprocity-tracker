import assert from 'node:assert/strict'
import test from 'node:test'
import {decode, load, save} from '../src/ThinkAheadStorage.js'
import {decode as decodeBackup} from '../src/LocalBackup.js'
import {history, next} from '../src/State.res.mjs'
import {closeCall, result, score} from '../src/ThinkAhead.res.mjs'

const consequence = (utility, likelihood = 'Likely', credibility = 'Probably yes') => ({
  id: crypto.randomUUID(), description: 'A later outcome', likelihood, utility,
  dependsOnPerson: true, credibility,
})
const scenario = {
  id: 'one', title: 'A decision', personId: '', createdAt: '2026-09-28T00:00:00.000Z', updatedAt: '2026-09-28T00:00:00.000Z',
  choiceA: {label: 'A', immediateUtility: 2, consequences: [consequence(-2)]},
  choiceB: {label: 'B', immediateUtility: 1, consequences: []},
}

test('old browser data loads without scenarios; scenarios use a separate key', () => {
  const values = new Map([['good-faith.people.v2', '[]']])
  globalThis.localStorage = {
    getItem: key => values.get(key) ?? null,
    setItem: (key, value) => values.set(key, value),
  }
  try {
    assert.deepEqual(load(), [])
    save([scenario])
    assert.deepEqual(load(), [scenario])
    assert.equal(values.get('good-faith.people.v2'), '[]')
    assert.deepEqual(decode('malformed'), [])
  } finally {
    delete globalThis.localStorage
  }
})

test('a failed browser write reports failure without changing saved scenarios', () => {
  globalThis.localStorage = {getItem: () => JSON.stringify([scenario]), setItem: () => { throw new Error('storage full') }}
  try {
    assert.throws(() => save([]), /storage full/)
    assert.deepEqual(load(), [scenario])
  } finally {
    delete globalThis.localStorage
  }
})

test('old backup loads with empty Think Ahead; new backup includes scenarios', () => {
  const old = {version: 1, people: [], tolerance: 2}
  assert.deepEqual(decodeBackup(JSON.stringify(old)), ['[]', 2, '[]'])
  assert.deepEqual(decodeBackup(JSON.stringify({...old, scenarios: [scenario]})), ['[]', 2, JSON.stringify([scenario])])
  assert.equal(decodeBackup(JSON.stringify({...old, scenarios: [{...scenario, choiceA: {label: 'bad'}}]})), undefined)
  assert.equal(decodeBackup(JSON.stringify({...old, scenarios: {length: 0}})), undefined)
})

test('Think Ahead changes cannot affect CURE difference or historical recommendations', () => {
  const entries = [{move: 'Defected', myMove: 'Cooperated', note: '', date: '2026-09-28', category: '', myActionDate: '', theirActionDate: ''}]
  const before = [next(entries).difference, history(entries).map(item => item.recommended)]
  const changed = {...scenario, choiceA: {...scenario.choiceA, consequences: [consequence(2)]}}
  assert.deepEqual(decode(JSON.stringify([changed])), [changed])
  assert.deepEqual([next(entries).difference, history(entries).map(item => item.recommended)], before)
})

test('immediate scores, negative and positive future outcomes, and multiple outcomes', () => {
  const choice = {label: 'A', immediateUtility: 2, consequences: []}
  assert.equal(score(choice), 2)
  assert.equal(score({...choice, consequences: [consequence(-2)]}), 0.5)
  assert.equal(score({...choice, consequences: [consequence(2, 'Possible')]}), 3)
  assert.equal(score({...choice, consequences: [consequence(-2), consequence(2, 'Possible')]}), 1.5)
})

test('credibility lowers only outcomes that depend on another person', () => {
  const choice = {label: 'A', immediateUtility: 2, consequences: [consequence(-2, 'Likely', 'Maybe')]}
  assert.equal(score(choice), 1.1)
  assert.equal(score({...choice, consequences: [consequence(-2, 'Likely', 'Probably not')]}), 1.625)
  assert.equal(score({...choice, consequences: [{...choice.consequences[0], dependsOnPerson: false}]}), 0.5)
})

test('equal scores tie and a narrow difference warns that assumptions can reverse the result', () => {
  const a = {label: 'A', immediateUtility: 1, consequences: []}
  const b = {label: 'B', immediateUtility: 1, consequences: []}
  assert.deepEqual(result(a, b), [1, 1, 'Neither option'])
  assert.equal(closeCall(a, b), true)
  assert.equal(closeCall({...a, consequences: [consequence(2, 'Very unlikely')]}, b), true)
  assert.equal(closeCall({...a, immediateUtility: 2}, b), false)
})
