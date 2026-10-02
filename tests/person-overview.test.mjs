import assert from 'node:assert/strict'
import test from 'node:test'
import React from 'react'
import {renderToStaticMarkup} from 'react-dom/server'
import {make, recentEntries} from '../src/PersonOverview.res.mjs'

const entry = (date, move = 'Cooperated', myMove = 'Cooperated', note = '', category = '') => ({
  date, move, myMove, note, category, myActionDate: '', theirActionDate: '',
})

const render = (person, tolerance = 2) => renderToStaticMarkup(React.createElement(make, {person, tolerance}))

test('overview keeps balances and tolerance per ledger and shows recent confirmed history only', () => {
  const general = [entry('2026-09-01', 'Defected'), entry('2026-09-02', 'Cooperated', 'Defected')]
  const dishes = [entry('2026-09-03', 'Defected', 'Cooperated', 'Shared the cleanup', 'Dishes'), entry('2026-09-03', 'Cooperated', 'Cooperated', 'Earlier confirmation')]
  const person = {
    id: 'p', name: 'Ari', entries: general, drafts: [{note: 'Draft must stay hidden'}],
    cureDeltaOverride: 3, generalCureDeltaOverride: 1,
    ledgers: [
      {id: 'd', name: 'Dishes', entries: dishes, drafts: [{note: 'Hidden draft'}]},
      {id: 'f', name: 'Favors', entries: [entry('2026-09-04', 'Cooperated', 'Defected')], drafts: [], cureDeltaOverride: 2},
    ],
  }
  const before = structuredClone(person)
  const html = render(person, 1)

  assert.match(html, /This is context, not a combined CURE score\./)
  assert.match(html, /Latest six by completion date\. Same-day interactions are grouped by ledger\./)
  assert.match(html, /General<\/th><td>2<\/td><td>0<\/td><td>Guarded \(Δ1\)/)
  assert.match(html, /Dishes<\/th><td>2<\/td><td>1<\/td><td>Forgiving \(Δ3\)/)
  assert.match(html, /Favors<\/th><td>1<\/td><td>-1<\/td><td>Balanced \(Δ2\)/)
  assert.match(html, /positive balance means more of their defections; a negative balance means more of yours/)
  assert.match(html, /Dishes · You: Cooperated · Them: Defected/)
  assert.match(html, /Shared the cleanup/)
  assert.doesNotMatch(html, /Hidden draft|Draft must stay hidden/)

  const history = recentEntries(person)
  assert.deepEqual(history.slice(0, 4).map(({ledgerName, entry: item}) => [ledgerName, item.note || item.category]), [
    ['Favors', ''], ['Dishes', 'Earlier confirmation'], ['Dishes', 'Shared the cleanup'], ['General', ''],
  ])
  assert.deepEqual(person, before)
})

test('overview renders General and an empty-history state for an empty person', () => {
  const html = render({id: 'p', name: 'Ari', entries: [], drafts: []})
  assert.match(html, /General<\/th><td>0<\/td><td>0<\/td>/)
  assert.match(html, /No confirmed interactions yet\./)
  assert.doesNotMatch(html, /Recent confirmed interactions[\s\S]*?<ol/)
})

test('recent entries are limited to six and same-date ordering is deterministic', () => {
  const person = {
    id: 'p', name: 'Ari', entries: [entry('2026-09-05', 'Cooperated', 'Cooperated', 'G1'), entry('2026-09-05', 'Cooperated', 'Cooperated', 'G2')], drafts: [],
    ledgers: [{id: 'd', name: 'Dishes', entries: [entry('2026-09-05', 'Cooperated', 'Cooperated', 'D1'), entry('2026-09-06', 'Cooperated', 'Cooperated', 'D2')], drafts: []}],
  }
  const source = structuredClone(person)
  const history = recentEntries(person)
  assert.deepEqual(history.map(({ledgerName, entry: item}) => [ledgerName, item.note]), [
    ['Dishes', 'D2'], ['General', 'G2'], ['General', 'G1'], ['Dishes', 'D1'],
  ])
  assert.deepEqual(person, source)

  const many = {...person, entries: Array.from({length: 8}, (_, i) => entry(`2026-09-${String(i + 1).padStart(2, '0')}`, 'Cooperated', 'Cooperated', `G${i + 1}`))}
  assert.equal((render(many).match(/· You:/g) || []).length, 6)
})
