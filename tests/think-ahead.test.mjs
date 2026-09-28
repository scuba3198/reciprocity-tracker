import assert from 'node:assert/strict'
import test from 'node:test'
import {readFileSync} from 'node:fs'
import React from 'react'
import {renderToStaticMarkup} from 'react-dom/server'
import {decode, load, save} from '../src/ThinkAheadStorage.js'
import {decode as decodeBackup} from '../src/LocalBackup.js'
import {history, next} from '../src/State.res.mjs'
import {canSave, closeCall, credibilityValue, credibilities, likelihoodValue, likelihoods, make, prefillScenario, result, score} from '../src/ThinkAhead.res.mjs'

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

test('existing scenario labels and saved likelihood values still load', () => {
  const old = {...scenario, choiceA: {...scenario.choiceA, label: 'Stay at current job'}}
  assert.deepEqual(decode(JSON.stringify([old])), [old])
  assert.equal(score(old.choiceA), 0.5)
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

test('display percentages match the unchanged likelihood and credibility weights', () => {
  for (const [value, label] of likelihoods) {
    assert.match(label, new RegExp(`~${likelihoodValue(value) * 100}%`))
  }
  for (const [value, label] of credibilities) {
    assert.match(label, new RegExp(`~${credibilityValue(value) * 100}%`))
  }
  assert.deepEqual(credibilities, [
    ['Probably not', 'Weak reason (~25% weight)'],
    ['Maybe', 'Plausible reason (~60% weight)'],
    ['Probably yes', 'Strong reason (~100% weight)'],
  ])
})

test('saving requires nonblank names and descriptions, but no future outcomes', () => {
  const immediateOnly = {...scenario, choiceA: {...scenario.choiceA, consequences: []}}
  assert.equal(canSave(immediateOnly), true)
  assert.equal(canSave({...immediateOnly, choiceB: {...immediateOnly.choiceB, label: immediateOnly.choiceA.label}}), true)
  assert.equal(canSave({...immediateOnly, title: '  '}), false)
  assert.equal(canSave({...immediateOnly, choiceA: {...immediateOnly.choiceA, label: '  '}}), false)
  assert.equal(canSave({...immediateOnly, choiceB: {...immediateOnly.choiceB, label: ''}}), false)
  assert.equal(canSave({...scenario, choiceA: {...scenario.choiceA, consequences: [{...scenario.choiceA.consequences[0], description: '  '}]}}), false)
  assert.equal(score(immediateOnly.choiceA), 2)
})

test('choice names are edited in Choices and reused as Possible outcomes headings', () => {
  const source = readFileSync(new URL('../src/ThinkAhead.res', import.meta.url), 'utf8')
  const choices = source.split('{step == 0 ?')[1].split(': step == 1 ?')[0]
  const outcomes = source.split('let choiceCard =')[1].split('<section className="think-ahead">')[0]
  assert.match(choices, /"Option A name" : "Option B name"/)
  assert.match(choices, /<input value=\{choice\.label\}/)
  assert.match(outcomes, /<h3>\{React\.string\(choice\.label\)\}<\/h3>/)
  assert.doesNotMatch(outcomes, /<input value=\{choice\.label\}/)
  assert.doesNotMatch(outcomes, /Immediate effect/)
})

test('CURE handoff prefills only decision context and never saves on opening', () => {
  const person = {id: 'person-1', name: 'Mira', entries: [], drafts: []}
  for (const [move, a, b] of [
    ['Cooperate', 'Follow CURE: Cooperate', 'Withhold cooperation'],
    ['Defect', 'Follow CURE: Withhold cooperation', 'Cooperate'],
  ]) {
    const draft = prefillScenario(person, move)
    assert.equal(draft.title, 'What should I do with Mira?')
    assert.equal(draft.personId, person.id)
    assert.equal(draft.choiceA.label, a)
    assert.equal(draft.choiceB.label, b)
    for (const choice of [draft.choiceA, draft.choiceB]) {
      assert.equal(choice.immediateUtility, 0)
      assert.deepEqual(choice.consequences, [])
    }
    let writes = 0
    const html = renderToStaticMarkup(React.createElement(make, {
      scenarios: [], people: [person], initialDraft: draft,
      onChange: async () => {writes++; return true}, onDirtyChange: () => {},
    }))
    assert.match(html, /What decision are you considering\?/)
    assert.match(html, /<option value="person-1" selected=""/)
    assert.match(html, /1\. Choices/)
    assert.doesNotMatch(html, /Your scenarios/)
    assert.equal(writes, 0)
  }
})

test('standalone Think Ahead opens the scenario list', () => {
  const html = renderToStaticMarkup(React.createElement(make, {
    scenarios: [], people: [], initialDraft: undefined,
    onChange: async () => true, onDirtyChange: () => {},
  }))
  assert.match(html, /Your scenarios/)
  assert.match(html, /\+ New scenario/)
  assert.doesNotMatch(html, /What decision are you considering\?/)
})

test('comparative results are rendered only in Compare, and both confirmations exist', () => {
  const thinkAhead = readFileSync(new URL('../src/ThinkAhead.res', import.meta.url), 'utf8')
  const app = readFileSync(new URL('../src/App.res', import.meta.url), 'utf8')
  const stepTwo = thinkAhead.split(': step == 1 ?')[1].split(': <>')[0]
  assert.doesNotMatch(stepTwo, /score\(|resultPanel|Favors|ta-live-strip|Current estimate favors/)
  assert.match(thinkAhead, /resultPanel\("Live comparison"/)
  assert.match(thinkAhead, /Discard unsaved changes\?/)
  assert.match(thinkAhead, /Keep editing/)
  assert.match(thinkAhead, /Keep scenario/)
  assert.match(app, /showThinkAhead && thinkAheadDirty/)
  assert.match(app, /Discard unsaved changes\?/)
  assert.match(app, /navigate\(Ledger\)/)
  assert.match(app, /navigate\(Home\)/)
  assert.match(app, /navigate\(Insights\)/)
  assert.match(app, /navigate\(Settings\)/)
  assert.match(app, /let addPerson = event =>[\s\S]*?navigate\(CreatePerson\(name\)\)/)
  assert.match(app, /\| CreatePerson\(name\) => createPerson\(name\)/)
})
