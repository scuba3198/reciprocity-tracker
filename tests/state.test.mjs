import assert from 'node:assert/strict'
import test from 'node:test'
import {next, orderedEntries, history, replaceEntry} from '../src/State.res.mjs'
import {load, save, loadTolerance, saveTolerance} from '../src/Storage.res.mjs'
import {calendarMonth, normalize, today} from '../src/InteractionDate.js'

const entry = (mine, theirs, date, category = '') => ({myMove: mine, move: theirs, note: '', date, category, myActionDate: '', theirActionDate: ''})

test('CURE uses their total defections minus yours with inclusive tolerance 1', () => {
  const breach = entry('Cooperate', 'Defect', '2024-03-01')
  const repeated = entry('Cooperate', 'Defect', '2024-03-02')
  const repair = entry('Defect', 'Cooperate', '2024-03-03')
  assert.deepEqual([next([], 1).move, next([breach], 1).move, next([breach, repeated], 1).move, next([breach, repeated, repair], 1).move],
    ['Cooperate', 'Cooperate', 'Defect', 'Cooperate'])
  assert.equal(next([breach, repeated]).difference, 2)
  assert.deepEqual(next([breach, {...repeated, category: 'Money'}]), next([breach, repeated]))
  assert.deepEqual(next([breach, {...repeated, myActionDate: '2024-03-01', theirActionDate: '2024-03-01'}]), next([breach, repeated]))
  assert.equal(next([entry('Defect', 'Cooperate', '2024-03-01')]).move, 'Cooperate')
  assert.equal(next([entry('Defect', 'Defect', '2024-03-01')]).difference, 0)
})

test('switching CURE tolerance recalculates current and historical recommendations', () => {
  const breaches = [
    entry('Cooperate', 'Defect', '2024-03-01'),
    entry('Cooperate', 'Defect', '2024-03-02'),
    entry('Cooperate', 'Defect', '2024-03-03'),
  ]
  assert.equal(next(breaches.slice(0, 2), 1).move, 'Defect')
  assert.equal(next(breaches.slice(0, 2), 2).move, 'Cooperate')
  assert.equal(next(breaches.slice(0, 2)).move, 'Cooperate')
  assert.equal(next(breaches, 2).move, 'Defect')
  assert.equal(history(breaches, 1)[2].recommended, 'Defect')
  assert.equal(history(breaches, 2)[2].recommended, 'Cooperate')
  assert.equal(history(breaches)[2].recommended, 'Cooperate')
  assert.match(next(breaches, 2).explanation, /more than 2/)
})

test('CURE tolerance defaults to 2 and persists the selected level in this browser', () => {
  let stored = null
  globalThis.localStorage = {
    getItem: key => key === 'good-faith.cure-tolerance' ? stored : null,
    setItem: (key, value) => { assert.equal(key, 'good-faith.cure-tolerance'); stored = value },
  }
  try {
    assert.equal(loadTolerance(), 2)
    saveTolerance(1)
    assert.equal(loadTolerance(), 1)
    stored = 'invalid'
    assert.equal(loadTolerance(), 2)
  } finally {
    delete globalThis.localStorage
  }
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
  assert.deepEqual(history(rounds, 1).map(item => [item.differenceBefore, item.recommended]),
    [[0, 'Cooperate'], [1, 'Cooperate'], [2, 'Defect'], [1, 'Cooperate'], [1, 'Cooperate'], [2, 'Defect']])
  assert.equal(next(rounds, 1).move, 'Defect')
  assert.equal(next([...rounds, entry('Defect', 'Cooperate', '2024-03-07')], 1).move, 'Cooperate')
})

test('history edits map duplicate-date rows to the exact source entry and recompute CURE', () => {
  const entries = [
    {...entry('Cooperate', 'Defect', '2024-03-01'), note: 'first'},
    {...entry('Cooperate', 'Defect', '2024-03-01'), note: 'second'},
  ]
  const selected = history(entries).find(item => item.entry.note === 'second')
  assert.equal(selected.sourceIndex, 1)
  const replacement = {...entries[1], myMove: 'Cooperate', move: 'Cooperate'}
  const updated = replaceEntry(entries, selected.sourceIndex, replacement)
  assert.equal(updated[0].note, 'first')
  assert.equal(updated[1].note, 'second')
  assert.equal(next(entries).difference, 2)
  assert.equal(next(updated).difference, 1)
})

test('CURE starts a fresh ledger and loads only its new storage key', () => {
  const people = [{id: 'one', name: 'A person', entries: [entry('Cooperate', 'Defect', '2024-03-01')], drafts: []}]
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

test('multiple drafts roundtrip, migrate a legacy draft, and confirm independently', () => {
  let stored
  globalThis.localStorage = {getItem: () => stored ?? null, setItem: (_, value) => { stored = value }}
  try {
    const legacy = {id: 'legacy', name: 'Older person', entries: [], draft: {saved: true, move: '', myMove: 'Cooperate', note: 'old request', date: '2024-03-02', category: 'Work', myActionDate: '', theirActionDate: ''}}
    stored = JSON.stringify([legacy])
    const {saved, ...legacyFields} = legacy.draft
    assert.deepEqual(load()[0].drafts, [{...legacyFields, id: 'legacy-legacy'}])

    const first = {id: 'first', myMove: 'Cooperate', move: 'Defect', note: 'first request', date: '2024-03-02', category: 'Work', myActionDate: '', theirActionDate: ''}
    const second = {id: 'second', myMove: '', move: '', note: 'second request', date: '', category: 'Social', myActionDate: '', theirActionDate: ''}
    save([{id: 'one', name: 'A person', entries: [], drafts: [first, second]}])
    const reopened = load()[0]
    assert.deepEqual(reopened.drafts, [first, second])
    assert.equal(next(reopened.entries).difference, 0)

    const confirmed = entry(first.myMove, first.move, first.date, first.category)
    const remaining = reopened.drafts.filter(draft => draft.id !== first.id)
    save([{...reopened, entries: [...reopened.entries, confirmed], drafts: remaining}])
    const after = load()[0]
    assert.equal(next(after.entries).difference, 1)
    assert.deepEqual(after.drafts, [second])
  } finally {
    delete globalThis.localStorage
  }
})

test('save persists both action dates', () => {
  let stored
  globalThis.localStorage = {setItem: (_, value) => { stored = value }}
  try {
    const people = [{id: 'one', name: 'A person', entries: [{...entry('Cooperate', 'Defect', '2024-03-01'), myActionDate: '2024-02-29', theirActionDate: ''}], drafts: []}]
    save(people)
    assert.deepEqual(JSON.parse(stored)[0].entries[0], people[0].entries[0])
  } finally {
    delete globalThis.localStorage
  }
})

test('interaction dates are valid local dates and backdated moves are replayed in date order', () => {
  assert.equal(normalize('20240229'), '2024-02-29')
  assert.equal(normalize('2024-02-30'), null)
  assert.equal(normalize('9999-12-31'), '9999-12-31')
  assert.equal(normalize(today()), today())

  const later = entry('Defect', 'Cooperate', '2024-03-02')
  const earlier = entry('Cooperate', 'Defect', '2024-03-01')
  assert.deepEqual(orderedEntries([later, earlier]), [earlier, later])
  assert.deepEqual(orderedEntries([{...later, myActionDate: '2024-02-28'}, earlier]).map(item => item.date), ['2024-03-01', '2024-03-02'])
  assert.equal(next([later, earlier]).move, 'Cooperate')
})

test('calendar includes leap day and permits future dates', () => {
  const leapMonth = calendarMonth('2024-02')
  assert.equal(leapMonth.days.filter(day => day.date).length, 29)
  assert.equal(leapMonth.days.find(day => day.date === '2024-02-29').disabled, false)
  const future = `${Number(today().slice(0, 4)) + 1}-01`
  const futureMonth = calendarMonth(future)
  assert.equal(futureMonth.nextDisabled, false)
  assert.ok(futureMonth.days.filter(day => day.date).every(day => !day.disabled))
  let stored
  globalThis.localStorage = {getItem: () => stored ?? null, setItem: (_, value) => { stored = value }}
  try {
    const futureEntry = entry('Cooperate', 'Defect', `${future}-01`)
    save([{id: 'future', name: 'Future round', entries: [futureEntry], drafts: []}])
    assert.equal(load()[0].entries[0].date, futureEntry.date)
  } finally {
    delete globalThis.localStorage
  }
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
