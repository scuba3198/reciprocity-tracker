import assert from 'node:assert/strict'
import test from 'node:test'
import {next, orderedEntries, history} from '../src/State.res.mjs'
import {backup, load, parseBackup, save} from '../src/Storage.res.mjs'
import {calendarMonth, normalize, today} from '../src/InteractionDate.js'

const entry = (mine, theirs, date, category = '') => ({myMove: mine, move: theirs, note: '', date, category, myActionDate: '', theirActionDate: ''})

test('CURE uses their total defections minus yours with inclusive tolerance 1', () => {
  const breach = entry('Cooperate', 'Defect', '2024-03-01')
  const repeated = entry('Cooperate', 'Defect', '2024-03-02')
  const repair = entry('Defect', 'Cooperate', '2024-03-03')
  assert.deepEqual([next([]).move, next([breach]).move, next([breach, repeated]).move, next([breach, repeated, repair]).move],
    ['Cooperate', 'Cooperate', 'Defect', 'Cooperate'])
  assert.equal(next([breach, repeated]).difference, 2)
  assert.deepEqual(next([breach, {...repeated, category: 'Money'}]), next([breach, repeated]))
  assert.deepEqual(next([breach, {...repeated, myActionDate: '2024-03-01', theirActionDate: '2024-03-01'}]), next([breach, repeated]))
  assert.equal(next([entry('Defect', 'Cooperate', '2024-03-01')]).move, 'Cooperate')
  assert.equal(next([entry('Defect', 'Defect', '2024-03-01')]).difference, 0)
})

test('CURE remembers the full history and recomputes the advice before each round', () => {
  const rounds = [
    entry('Cooperate', 'Defect', '2024-03-01'),
    entry('Cooperate', 'Defect', '2024-03-02'),
    entry('Defect', 'Cooperate', '2024-03-03'),
    entry('Cooperate', 'Cooperate', '2024-03-04'),
    entry('Cooperate', 'Defect', '2024-03-05'),
    entry('Cooperate', 'Cooperate', '2024-03-06'),
  ]
  assert.deepEqual(history(rounds).map(item => [item.differenceBefore, item.recommended]),
    [[0, 'Cooperate'], [1, 'Cooperate'], [2, 'Defect'], [1, 'Cooperate'], [1, 'Cooperate'], [2, 'Defect']])
  assert.equal(next(rounds).move, 'Defect')
  assert.equal(next([...rounds, entry('Defect', 'Cooperate', '2024-03-07')]).move, 'Cooperate')
})

test('backup round-trips action dates and defaults them for older entries', () => {
  const people = [{id: 'one', name: 'A person', entries: [{move: 'Defect', myMove: 'Cooperate', note: 'Missed a promise', date: '2024-02-29', category: 'Commitment', myActionDate: '2024-02-27', theirActionDate: ''}]}]
  assert.deepEqual(parseBackup(backup(people)), {TAG: 'Ok', _0: people})
  const legacy = JSON.parse(backup(people))
  delete legacy.people[0].entries[0].category
  delete legacy.people[0].entries[0].myActionDate
  delete legacy.people[0].entries[0].theirActionDate
  assert.deepEqual(parseBackup(JSON.stringify(legacy))._0[0].entries[0].category, '')
  assert.deepEqual([parseBackup(JSON.stringify(legacy))._0[0].entries[0].myActionDate, parseBackup(JSON.stringify(legacy))._0[0].entries[0].theirActionDate], ['', ''])
  for (const date of [null, 7, {}, '2024-02-30', '2024-03-01']) {
    const malformed = JSON.parse(backup(people))
    malformed.people[0].entries[0].myActionDate = date
    assert.equal(parseBackup(JSON.stringify(malformed)).TAG, 'Error')
  }
  for (const category of [null, 7, {}]) {
    const malformed = JSON.parse(backup(people))
    malformed.people[0].entries[0].category = category
    assert.equal(parseBackup(JSON.stringify(malformed)).TAG, 'Error')
  }
  assert.equal(parseBackup('{broken').TAG, 'Error')
  assert.equal(parseBackup(JSON.stringify({format: 'other', version: 1, people})).TAG, 'Error')
  assert.equal(parseBackup(JSON.stringify({format: 'good-faith-backup', version: 4, people: [{...people[0], entries: [{move: 'Other', myMove: 'Cooperate', note: '', date: '2024-02-29'}]}]})).TAG, 'Error')
  assert.equal(parseBackup(JSON.stringify({format: 'good-faith-backup', version: 4, people: [{...people[0], entries: [{move: 'Defect', myMove: 'Other', note: '', date: '2024-02-29'}]}]})).TAG, 'Error')
  assert.equal(parseBackup(JSON.stringify({format: 'good-faith-backup', version: 4, people: [people[0], people[0]]})).TAG, 'Error')
  assert.equal(parseBackup(JSON.stringify({format: 'good-faith-backup', version: 3, people})).TAG, 'Error')
})

test('CURE starts a fresh ledger and loads only its new storage key', () => {
  const people = [{id: 'one', name: 'A person', entries: [entry('Cooperate', 'Defect', '2024-03-01')]}]
  const saved = {'good-faith.people.v1': JSON.stringify(people)}
  globalThis.localStorage = {getItem: key => saved[key] ?? null}
  try {
    assert.deepEqual(load(), [])
    saved['good-faith.people.v2'] = JSON.stringify(people)
    assert.deepEqual(load(), people)
    const legacy = JSON.parse(saved['good-faith.people.v2'])
    delete legacy[0].entries[0].category
    saved['good-faith.people.v2'] = JSON.stringify(legacy)
    assert.equal(load()[0].entries[0].category, '')
    assert.equal(load()[0].entries[0].myActionDate, '')
    assert.equal(load()[0].entries[0].theirActionDate, '')
  } finally {
    delete globalThis.localStorage
  }
})

test('save persists both action dates', () => {
  let stored
  globalThis.localStorage = {setItem: (_, value) => { stored = value }}
  try {
    const people = [{id: 'one', name: 'A person', entries: [{...entry('Cooperate', 'Defect', '2024-03-01'), myActionDate: '2024-02-29', theirActionDate: ''}]}]
    save(people)
    assert.deepEqual(JSON.parse(stored)[0].entries[0], people[0].entries[0])
  } finally {
    delete globalThis.localStorage
  }
})

test('interaction dates are valid local dates and backdated moves are replayed in date order', () => {
  assert.equal(normalize('20240229'), '2024-02-29')
  assert.equal(normalize('2024-02-30'), null)
  assert.equal(normalize('9999-12-31'), null)
  assert.equal(normalize(today()), today())

  const later = entry('Defect', 'Cooperate', '2024-03-02')
  const earlier = entry('Cooperate', 'Defect', '2024-03-01')
  assert.deepEqual(orderedEntries([later, earlier]), [earlier, later])
  assert.deepEqual(orderedEntries([{...later, myActionDate: '2024-02-28'}, earlier]).map(item => item.date), ['2024-03-01', '2024-03-02'])
  assert.equal(next([later, earlier]).move, 'Cooperate')
})

test('calendar includes leap day and disables future dates', () => {
  const leapMonth = calendarMonth('2024-02')
  assert.equal(leapMonth.days.filter(day => day.date).length, 29)
  assert.equal(leapMonth.days.find(day => day.date === '2024-02-29').disabled, false)
  const currentMonth = calendarMonth(today().slice(0, 7))
  assert.equal(currentMonth.nextDisabled, true)
  assert.ok(currentMonth.days.filter(day => day.date > today()).every(day => day.disabled))
})

test('theme choice persists and auto follows the system', async () => {
  let saved = 'dark'
  let onSystemChange
  const media = {matches: false, addEventListener: (_, listener) => { onSystemChange = listener }}
  globalThis.localStorage = {getItem: () => saved, setItem: (_, value) => { saved = value }}
  globalThis.matchMedia = () => media
  globalThis.document = {documentElement: {dataset: {}}}
  try {
    const {apply, load} = await import('../src/Theme.js')
    assert.equal(load(), 'dark')
    assert.equal(document.documentElement.dataset.theme, 'dark')
    apply('auto')
    assert.equal(saved, 'auto')
    assert.equal(document.documentElement.dataset.theme, 'light')
    media.matches = true
    onSystemChange()
    assert.equal(document.documentElement.dataset.theme, 'dark')
    apply('light')
    onSystemChange()
    assert.equal(document.documentElement.dataset.theme, 'light')
  } finally {
    delete globalThis.localStorage
    delete globalThis.matchMedia
    delete globalThis.document
  }
})
