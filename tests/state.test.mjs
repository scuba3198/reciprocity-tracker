import assert from 'node:assert/strict'
import test from 'node:test'
import {advance, nextMove, phase, orderedEntries} from '../src/State.res.mjs'
import {backup, parseBackup} from '../src/Storage.res.mjs'
import {calendarMonth, normalize, today} from '../src/InteractionDate.js'

const step = (moves) => moves.reduce(advance, 'Open')
const recommendation = (moves) => nextMove(step(moves))

test('forgive once, reset after two clean moves', () => {
  assert.equal(recommendation(['Defect']), 'Cooperate')
  assert.deepEqual(step(['Defect', 'Cooperate']), {TAG: 'Grace', _0: 1})
  assert.equal(step(['Defect', 'Cooperate', 'Cooperate']), 'Open')
})

test('a second defection triggers a boundary until cooperation returns', () => {
  assert.equal(recommendation(['Defect', 'Defect']), 'Defect')
  assert.equal(recommendation(['Defect', 'Defect', 'Defect']), 'Defect')
  assert.equal(recommendation(['Defect', 'Defect', 'Cooperate']), 'Cooperate')
  assert.deepEqual(step(['Defect', 'Defect', 'Cooperate']), {TAG: 'Grace', _0: 1})
  assert.equal(step(['Defect', 'Defect', 'Cooperate', 'Cooperate']), 'Open')
  assert.equal(recommendation(['Defect', 'Cooperate', 'Defect']), 'Defect')
})

test('backup round-trips and rejects incomplete or unrelated files', () => {
  const people = [{id: 'one', name: 'A person', entries: [{move: 'Defect', note: 'Missed a promise', date: '2024-02-29'}]}]
  assert.deepEqual(parseBackup(backup(people)), {TAG: 'Ok', _0: people})
  assert.equal(parseBackup('{broken').TAG, 'Error')
  assert.equal(parseBackup(JSON.stringify({format: 'other', version: 1, people})).TAG, 'Error')
  assert.equal(parseBackup(JSON.stringify({format: 'good-faith-backup', version: 2, people: [{...people[0], entries: [{move: 'Other', note: '', date: '2024-02-29'}]}]})).TAG, 'Error')
  assert.equal(parseBackup(JSON.stringify({format: 'good-faith-backup', version: 2, people: [people[0], people[0]]})).TAG, 'Error')
  const legacy = {format: 'good-faith-backup', version: 1, people: [{id: 'old', name: 'Older backup', entries: [{move: 'Cooperate', note: '', at: new Date(2024, 1, 29, 12).getTime()}]}]}
  assert.equal(parseBackup(JSON.stringify(legacy))._0[0].entries[0].date, '2024-02-29')
})

test('interaction dates are valid local dates and backdated moves are replayed in date order', () => {
  assert.equal(normalize('20240229'), '2024-02-29')
  assert.equal(normalize('2024-02-30'), null)
  assert.equal(normalize('9999-12-31'), null)
  assert.equal(normalize(today()), today())

  const later = {move: 'Defect', note: '', date: '2024-03-02'}
  const earlier = {move: 'Cooperate', note: '', date: '2024-03-01'}
  assert.deepEqual(orderedEntries([later, earlier]), [earlier, later])
  assert.deepEqual(phase([later, earlier]), {TAG: 'Grace', _0: 0})
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
