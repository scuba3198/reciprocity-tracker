import assert from 'node:assert/strict'
import test from 'node:test'
import {decide, next, orderedEntries, history} from '../src/State.res.mjs'
import {backup, parseBackup} from '../src/Storage.res.mjs'
import {calendarMonth, normalize, today} from '../src/InteractionDate.js'

const entry = (mine, theirs, date) => ({myMove: mine, move: theirs, note: '', date})

test('CAPRI matches every cell of Murase and Baek Table 3', () => {
  const triples = ['ccc', 'ccd', 'cdc', 'cdd', 'dcc', 'dcd', 'ddc', 'ddd']
  const cooperate = new Set([
    'ccc/ccc', 'ccc/dcc',
    'ccd/ccc', 'ccd/cdc',
    'cdc/ccd', 'cdc/dcc',
    'dcc/ccc', 'dcc/cdc', 'dcc/dcc', 'dcc/ddc',
    'ddc/dcc', 'ddc/ddc', 'ddc/ddd',
    'ddd/ddc',
  ])
  for (const mine of triples) for (const theirs of triples) {
    assert.equal(decide({mine, theirs, known: 3}).move, cooperate.has(`${mine}/${theirs}`) ? 'Cooperate' : 'Defect', `${mine}/${theirs}`)
  }
  assert.equal(cooperate.size, 14)
})

test('CAPRI responds to a breach, accepts punishment, and recovers from mutual defection', () => {
  assert.equal(next([]).move, 'Cooperate')
  assert.equal(next([entry('Cooperate', 'Defect', '2024-03-01')]).move, 'Defect')
  assert.equal(next([entry('Cooperate', 'Defect', '2024-03-01'), entry('Defect', 'Cooperate', '2024-03-02')]).move, 'Cooperate')
  assert.equal(next([entry('Defect', 'Cooperate', '2024-03-01')]).move, 'Cooperate')
  assert.equal(decide({mine: 'ddd', theirs: 'ddc', known: 3}).move, 'Cooperate')
})

test('backup round-trips and rejects incomplete or unrelated files', () => {
  const people = [{id: 'one', name: 'A person', entries: [{move: 'Defect', myMove: 'Cooperate', note: 'Missed a promise', date: '2024-02-29'}]}]
  assert.deepEqual(parseBackup(backup(people)), {TAG: 'Ok', _0: people})
  assert.equal(parseBackup('{broken').TAG, 'Error')
  assert.equal(parseBackup(JSON.stringify({format: 'other', version: 1, people})).TAG, 'Error')
  assert.equal(parseBackup(JSON.stringify({format: 'good-faith-backup', version: 2, people: [{...people[0], entries: [{move: 'Other', note: '', date: '2024-02-29'}]}]})).TAG, 'Error')
  assert.equal(parseBackup(JSON.stringify({format: 'good-faith-backup', version: 3, people: [{...people[0], entries: [{move: 'Defect', myMove: 'Other', note: '', date: '2024-02-29'}]}]})).TAG, 'Error')
  assert.equal(parseBackup(JSON.stringify({format: 'good-faith-backup', version: 2, people: [people[0], people[0]]})).TAG, 'Error')
  const legacy = {format: 'good-faith-backup', version: 1, people: [{id: 'old', name: 'Older backup', entries: [{move: 'Cooperate', note: '', at: new Date(2024, 1, 29, 12).getTime()}]}]}
  assert.equal(parseBackup(JSON.stringify(legacy))._0[0].entries[0].date, '2024-02-29')
  assert.equal(parseBackup(JSON.stringify(legacy))._0[0].entries[0].myMove, undefined)
})

test('interaction dates are valid local dates and backdated moves are replayed in date order', () => {
  assert.equal(normalize('20240229'), '2024-02-29')
  assert.equal(normalize('2024-02-30'), null)
  assert.equal(normalize('9999-12-31'), null)
  assert.equal(normalize(today()), today())

  const later = entry('Defect', 'Cooperate', '2024-03-02')
  const earlier = entry('Cooperate', 'Defect', '2024-03-01')
  assert.deepEqual(orderedEntries([later, earlier]), [earlier, later])
  assert.equal(next([later, earlier]).move, 'Cooperate')
})

test('old unpaired entries are retained but block exact advice until three complete rounds', () => {
  const old = entry(undefined, 'Defect', '2024-03-01')
  const paired = [entry('Cooperate', 'Cooperate', '2024-03-02'), entry('Cooperate', 'Cooperate', '2024-03-03'), entry('Cooperate', 'Defect', '2024-03-04')]
  assert.equal(next([old]).move, undefined)
  assert.equal(next([old, ...paired.slice(0, 2)]).move, undefined)
  assert.equal(next([old, ...paired]).move, 'Defect')
  assert.deepEqual(history([paired[2], old, paired[1], paired[0]]).map(item => item.recommended), ['Cooperate', undefined, undefined, undefined])
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
