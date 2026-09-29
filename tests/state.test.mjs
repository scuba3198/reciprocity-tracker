import assert from 'node:assert/strict'
import test from 'node:test'
import {next, orderedEntries, history, replaceEntry, validChoices, actionFromChoice, choiceFromAction, differentFromRecommendation} from '../src/State.res.mjs'
import {load, save, loadTolerance, saveTolerance, decodeBackup, serialize} from '../src/Storage.res.mjs'
import {calendarMonth, normalize, today} from '../src/InteractionDate.js'
import {trendPath} from '../src/Dashboard.res.mjs'
import {readFile} from '../src/LocalBackup.js'

const action = value => ({Cooperate: 'Cooperated', Defect: 'Defected', Request: 'Requested', Unable: 'Unable', NoAction: 'NoAction'})[value]
const entry = (mine, theirs, date, category = '') => ({myMove: action(mine), move: action(theirs), note: '', date, category, myActionDate: '', theirActionDate: ''})

test('dashboard line rises when the defection difference decreases', () => {
  assert.equal(trendPath([0, 1, 0]), '0,4 30,20 60,4')
  assert.equal(trendPath([0, -1, 0]), '0,20 30,4 60,20')
})

test('choices map to actions and allow a NoAction side when the other side acts', () => {
  assert.equal(validChoices('Cooperate', 'NoAction'), true)
  assert.equal(validChoices('Defect', 'NoAction'), true)
  assert.equal(validChoices('NoAction', 'Cooperate'), true)
  assert.equal(validChoices('NoAction', 'Defect'), true)
  assert.equal(validChoices('NoAction', 'NoAction'), false)
  assert.equal(validChoices('Request', 'Cooperate'), true)
  assert.equal(validChoices('Cooperate', 'Request'), true)
  assert.equal(validChoices('Request', 'Defect'), true)
  assert.equal(validChoices('Defect', 'Request'), true)
  assert.equal(validChoices('Request', 'Request'), false)
  assert.equal(validChoices('Request', 'NoAction'), false)
  assert.equal(validChoices('NoAction', 'Request'), false)
  assert.equal(validChoices('Unable', 'NoAction'), false)
  assert.equal(validChoices('NoAction', 'Unable'), false)
  assert.equal(validChoices('Request', 'Unable'), true)
  assert.equal(validChoices('Unable', 'Request'), true)
  assert.equal(validChoices('Unable', 'Unable'), false)
  assert.equal(validChoices('invalid', 'Cooperate'), false)
  assert.equal(actionFromChoice('Cooperate'), 'Cooperated')
  assert.equal(actionFromChoice('Defect'), 'Defected')
  assert.equal(actionFromChoice('Request'), 'Requested')
  assert.equal(actionFromChoice('Unable'), 'Unable')
  assert.equal(actionFromChoice('NoAction'), 'NoAction')
  assert.equal(actionFromChoice(''), undefined)
  assert.deepEqual(['Cooperated', 'Defected', 'Requested', 'Unable', 'NoAction'].map(choiceFromAction), ['Cooperate', 'Defect', 'Request', 'Unable', 'NoAction'])
})

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
    entry('Cooperate', 'Defect', '2024-03-04'),
  ]
  assert.equal(next(breaches.slice(0, 2), 1).move, 'Defect')
  assert.equal(next(breaches.slice(0, 2), 2).move, 'Cooperate')
  assert.equal(next(breaches.slice(0, 2)).move, 'Cooperate')
  assert.equal(next(breaches.slice(0, 3), 2).move, 'Defect')
  assert.equal(next(breaches.slice(0, 3), 3).move, 'Cooperate')
  assert.equal(next(breaches.slice(0, 3)).move, 'Cooperate')
  assert.equal(next(breaches, 3).move, 'Defect')
  assert.equal(next(breaches).move, 'Defect')
  assert.equal(history(breaches, 1)[2].recommended, 'Defect')
  assert.equal(history(breaches, 2)[2].recommended, 'Cooperate')
  assert.equal(history(breaches, 2)[3].recommended, 'Defect')
  assert.equal(history(breaches, 3)[3].recommended, 'Cooperate')
  assert.equal(history(breaches)[3].recommended, 'Cooperate')
  assert.match(next(breaches, 3).explanation, /more than 3/)
})

test('CURE tolerance defaults to 3 and persists all selected levels in this browser', () => {
  let stored = null
  globalThis.localStorage = {
    getItem: key => key === 'good-faith.cure-tolerance' ? stored : null,
    setItem: (key, value) => { assert.equal(key, 'good-faith.cure-tolerance'); stored = value },
  }
  try {
    assert.equal(loadTolerance(), 3)
    for (const choice of [1, 2, 3]) {
      assert.equal(saveTolerance(choice), true)
      assert.equal(loadTolerance(), choice)
    }
    stored = 'invalid'
    assert.equal(loadTolerance(), 3)
    globalThis.localStorage.setItem = () => { throw new Error('storage unavailable') }
    assert.equal(saveTolerance(1), false)
  } finally {
    delete globalThis.localStorage
  }
})

test('local backups accept complete ledgers and reject malformed or partial data', () => {
  const people = [{id: 'one', name: 'A person', entries: [entry('Cooperate', 'Defect', '2024-03-01')], drafts: [
    {id: 'draft', move: '', myMove: 'Request', note: 'in progress', date: '', category: '', myActionDate: '', theirActionDate: ''},
  ]}]
  const backup = {version: 1, people: people.map(person => ({...person, entries: person.entries.map(item => ({...item, move: 'Defect', myMove: 'Cooperate'}))})), tolerance: 1}
  for (const tolerance of [1, 2, 3]) {
    assert.deepEqual(decodeBackup(JSON.stringify({...backup, tolerance})), [people, tolerance, '[]'])
  }
  assert.equal(decodeBackup(JSON.stringify({...backup, people: [{...people[0], entries: [{...people[0].entries[0], move: 'invalid'}]}]})), undefined)
  assert.equal(decodeBackup(JSON.stringify({...backup, people: [{...people[0], drafts: [null]}]})), undefined)
  assert.equal(decodeBackup(JSON.stringify({...backup, people: [backup.people[0], backup.people[0]]})), undefined)
  assert.equal(decodeBackup(JSON.stringify({...backup, tolerance: 4})), undefined)
  assert.equal(decodeBackup('{"version":1,"people":[]}'), undefined)
})

test('local backup roundtrip preserves raw date text in saved drafts', () => {
  const people = [{id: 'one', name: 'A person', entries: [], drafts: [
    {id: 'draft', move: 'Request', myMove: 'Unable', note: 'still editing', date: '20240928', category: 'Work', myActionDate: '2024092', theirActionDate: ''},
  ]}]
  const backupJSON = JSON.stringify({version: 1, people: JSON.parse(serialize(people)), tolerance: 2})
  assert.deepEqual(decodeBackup(backupJSON), [people, 2, '[]'])
})

test('backup file input resets after capturing the selected file', async () => {
  const input = {files: [{text: async () => 'backup'}], value: 'selected.json'}
  assert.equal(await readFile(input), 'backup')
  assert.equal(input.value, '')
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

test('one-sided defection changes CURE only for the acting side; edits and backdating replay', () => {
  for (const [mine, theirs, difference] of [
    ['Request', 'Cooperate', 0], ['Request', 'Defect', 1],
    ['Cooperate', 'Request', 0], ['Defect', 'Request', -1],
    ['Unable', 'Cooperate', 0], ['Unable', 'Defect', 1],
    ['Cooperate', 'Unable', 0], ['Defect', 'Unable', -1],
    ['Request', 'Unable', 0], ['Unable', 'Request', 0],
    ['Cooperate', 'Cooperate', 0], ['Cooperate', 'Defect', 1],
    ['Defect', 'Cooperate', -1], ['Defect', 'Defect', 0],
  ]) assert.equal(next([entry(mine, theirs, '2024-03-01')]).difference, difference)
  const interaction = entry('Cooperate', 'Defect', '2024-03-03')
  const oneSided = entry('Request', 'Defect', '2024-03-02')
  assert.equal(next([interaction, oneSided]).difference, 2)
  assert.deepEqual(history([interaction, oneSided], 1).map(item => [item.entry.date, item.differenceBefore, item.recommended]),
    [['2024-03-02', 0, 'Cooperate'], ['2024-03-03', 1, 'Cooperate']])
  const entries = [interaction, oneSided]
  const revised = replaceEntry(entries, 0, entry('Request', 'Cooperate', '2024-03-01'))
  assert.deepEqual(orderedEntries(revised).map(item => item.date), ['2024-03-01', '2024-03-02'])
  assert.equal(next(revised).difference, 1)
  assert.equal(next([entry('Defect', 'Request', '2024-03-01'), oneSided]).difference, 0)
})

test('NoAction is neutral to CURE and entries can be edited to or from it', () => {
  for (const [mine, theirs, difference] of [
    ['Cooperate', 'NoAction', 0], ['Defect', 'NoAction', -1],
    ['NoAction', 'Cooperate', 0], ['NoAction', 'Defect', 1],
  ]) assert.equal(next([entry(mine, theirs, '2024-03-01')]).difference, difference)

  const prior = entry('Defect', 'Cooperate', '2024-03-01')
  const edited = replaceEntry([prior], 0, entry('NoAction', 'Cooperate', prior.date))
  assert.equal(next(edited).difference, 0)
  assert.equal(next(replaceEntry(edited, 0, prior)).difference, -1)
  assert.equal(next([entry('Defect', 'NoAction', '2024-03-01')]).move, 'Cooperate')
  assert.equal(next([entry('NoAction', 'Defect', '2024-03-01')]).move, 'Cooperate')
  assert.equal(differentFromRecommendation('NoAction', 'Defect'), false)
  assert.equal(differentFromRecommendation('Cooperated', 'Cooperate'), false)
  assert.equal(differentFromRecommendation('Cooperated', 'Defect'), true)
  assert.equal(differentFromRecommendation('Defected', 'Cooperate'), true)
  assert.equal(differentFromRecommendation('Defected', 'Defect'), false)
})

test('history edits map duplicate-date rows to the exact source entry and recompute CURE', () => {
  const entries = [
    {...entry('Cooperate', 'Defect', '2024-03-01'), note: 'first'},
    {...entry('Cooperate', 'Defect', '2024-03-01'), note: 'second'},
  ]
  const selected = history(entries).find(item => item.entry.note === 'second')
  assert.equal(selected.sourceIndex, 1)
  const replacement = {...entries[1], myMove: action('Cooperate'), move: action('Cooperate')}
  const updated = replaceEntry(entries, selected.sourceIndex, replacement)
  assert.equal(updated[0].note, 'first')
  assert.equal(updated[1].note, 'second')
  assert.equal(next(entries).difference, 2)
  assert.equal(next(updated).difference, 1)
})

test('CURE starts a fresh ledger and loads only its new storage key', () => {
  const people = [{id: 'one', name: 'A person', entries: [{myMove: 'Cooperate', move: 'Defect', note: '', date: '2024-03-01', category: '', myActionDate: '', theirActionDate: ''}], drafts: []}]
  const saved = {'good-faith.people.v1': JSON.stringify(people)}
  globalThis.localStorage = {getItem: key => saved[key] ?? null}
  try {
    assert.deepEqual(load(), [])
    saved['good-faith.people.v2'] = JSON.stringify(people)
    assert.deepEqual(load()[0].entries, [entry('Cooperate', 'Defect', '2024-03-01')])
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

test('saved ledgers ignore unknown fields and retain CURE history', () => {
  const person = {id: 'one', name: 'A person', entries: [entry('Cooperate', 'Defect', '2024-03-01', 'Work')], drafts: []}
  let stored
  globalThis.localStorage = {getItem: () => stored, setItem: (_, value) => { stored = value }}
  try {
    save([person])
    const [serialized] = JSON.parse(stored)
    stored = JSON.stringify([{...serialized, oldAnalysis: {recommendation: 'Defect'}, entries: [{...serialized.entries[0], oldPrediction: 0.75}]}])
    assert.deepEqual(load(), [person])
    assert.equal(next(load()[0].entries).difference, 1)
    save(load())
    assert.deepEqual(JSON.parse(stored), [serialized])
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
    const second = {id: 'second', myMove: '', move: 'Request', note: 'second request', date: '', category: 'Social', myActionDate: '', theirActionDate: ''}
    const third = {id: 'third', myMove: 'Defect', move: 'Cooperate', note: '', date: '', category: '', myActionDate: '', theirActionDate: ''}
    const fourth = {id: 'fourth', myMove: 'Request', move: '', note: '', date: '', category: '', myActionDate: '2024-03-01', theirActionDate: ''}
    const fifth = {id: 'fifth', myMove: '', move: 'Unable', note: '', date: '', category: '', myActionDate: '', theirActionDate: ''}
    save([{id: 'one', name: 'A person', entries: [], drafts: [first, second, third, fourth, fifth]}])
    const reopened = load()[0]
    assert.deepEqual(reopened.drafts, [first, second, third, fourth, fifth])
    assert.equal(reopened.drafts[3].myMove, 'Request')
    assert.equal(reopened.drafts[3].move, '')
    assert.equal(reopened.drafts[4].move, 'Unable')
    assert.equal(reopened.drafts[4].myMove, '')
    assert.equal(next(reopened.entries).difference, 0)

    const confirmed = entry(first.myMove, first.move, first.date, first.category)
    const remaining = reopened.drafts.filter(draft => draft.id !== first.id)
    save([{...reopened, entries: [...reopened.entries, confirmed], drafts: remaining}])
    const after = load()[0]
    assert.equal(next(after.entries).difference, 1)
    assert.deepEqual(after.drafts, [second, third, fourth, fifth])
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
    assert.deepEqual(JSON.parse(stored)[0].entries[0], {
      myMove: 'Cooperate', move: 'Defect', note: '', date: '2024-03-01', category: '', myActionDate: '2024-02-29', theirActionDate: '',
    })
  } finally {
    delete globalThis.localStorage
  }
})

test('Request, Unable, and NoAction roundtrip; NoAction/NoAction entries are rejected', () => {
  let stored
  globalThis.localStorage = {getItem: () => stored ?? null, setItem: (_, value) => { stored = value }}
  try {
    const people = [{id: 'one', name: 'A person', entries: [entry('Request', 'Cooperate', '2024-03-03'), entry('Request', 'Unable', '2024-03-04'), entry('Defect', 'NoAction', '2024-03-05')], drafts: []}]
    save(people)
    assert.equal(JSON.parse(stored)[0].entries[0].myMove, 'Request')
    assert.equal(JSON.parse(stored)[0].entries[1].move, 'Unable')
    assert.equal(JSON.parse(stored)[0].entries[2].move, 'NoAction')
    assert.deepEqual(load(), people)
    const invalidBoth = [{...people[0], entries: [entry('NoAction', 'NoAction', '2024-03-06')]}]
    globalThis.localStorage.getItem = () => JSON.stringify(invalidBoth)
    assert.deepEqual(load(), [])
    for (const invalid of [undefined, 'garbage', null]) {
      const bad = JSON.parse(stored)
      if (invalid === undefined) delete bad[0].entries[0].myMove
      else bad[0].entries[0].myMove = invalid
      globalThis.localStorage.getItem = () => JSON.stringify(bad)
      assert.deepEqual(load(), [])
    }
  } finally {
    delete globalThis.localStorage
  }
})

test('old C/D entries still load and NoAction backups restore', () => {
  const oldEntry = {myMove: 'Cooperate', move: 'Defect', note: '', date: '2024-03-01'}
  const oldPerson = {id: 'old', name: 'Older person', entries: [oldEntry], drafts: []}
  globalThis.localStorage = {getItem: () => JSON.stringify([oldPerson])}
  try {
    assert.equal(load()[0].entries[0].myMove, 'Cooperated')
    const withNoAction = [{id: 'one', name: 'A person', entries: [entry('Cooperate', 'NoAction', '2024-03-02')], drafts: []}]
    const backup = {version: 1, people: JSON.parse(serialize(withNoAction)), tolerance: 2}
    assert.deepEqual(decodeBackup(JSON.stringify(backup)), [withNoAction, 2, '[]'])
  } finally {
    delete globalThis.localStorage
  }
})

test('request action dates are allowed', () => {
  let stored
  globalThis.localStorage = {getItem: () => stored ?? null, setItem: (_, value) => { stored = value }}
  try {
    const person = {id: 'one', name: 'A person', entries: [
      {...entry('Request', 'Cooperate', '2024-03-02'), myActionDate: '2024-03-01'},
    ], drafts: []}
    save([person])
    assert.deepEqual(load(), [person])
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
