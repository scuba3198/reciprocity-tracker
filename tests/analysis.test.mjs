import assert from 'node:assert/strict'
import test from 'node:test'
import {estimate, evidenceLabel} from '../src/Bayesian.res.mjs'
import {defaults, decide, expectedUtility, utility} from '../src/DecisionAnalysis.res.mjs'

const entry = (mine, theirs, category = '', date = '2024-01-01') => ({myMove: mine, move: theirs, category, note: '', date, myActionDate: '', theirActionDate: ''})

test('conditional estimates use Beta(1,1) and condition on my move', () => {
  const entries = [entry('Cooperate', 'Cooperate'), entry('Cooperate', 'Defect'), entry('Defect', 'Cooperate')]
  assert.deepEqual(estimate(entries, 'Cooperate', undefined), {
    myMove: 'Cooperate', probability: 0.5, observed: 2, evidence: 'Very limited',
  })
  assert.equal(estimate(entries, 'Defect', undefined).probability, 2 / 3)
  assert.equal(estimate([], 'Defect', undefined).probability, 0.5)
  assert.equal(estimate([entry('Cooperate', 'Defect')], 'Cooperate', undefined).probability, 1 / 3)
  const eightAndTwo = [...Array.from({length: 8}, () => entry('Cooperate', 'Cooperate')), ...Array.from({length: 2}, () => entry('Cooperate', 'Defect'))]
  assert.equal(estimate(eightAndTwo, 'Cooperate', undefined).probability, 0.75)
})

test('category estimate pools toward the matching overall conditional estimate', () => {
  const entries = [entry('Cooperate', 'Cooperate', 'A'), entry('Cooperate', 'Defect', 'B'), entry('Cooperate', 'Defect', 'B')]
  const estimateA = estimate(entries, 'Cooperate', 'A')
  assert.equal(estimateA.observed, 1)
  assert.equal(estimateA.probability, (1 + 2 * 0.4) / 3)
  assert.equal(estimate(entries, 'Cooperate', 'missing').probability, estimate(entries, 'Cooperate', undefined).probability)
  assert.notEqual(estimate(entries, 'Cooperate', 'A').probability, estimate(entries, 'Cooperate', 'B').probability)
  const backdated = [entry('Cooperate', 'Defect', 'A', '2024-02-01'), entry('Cooperate', 'Cooperate', 'A', '2024-01-01')]
  assert.deepEqual(estimate(backdated, 'Cooperate', 'A'), estimate([...backdated].reverse(), 'Cooperate', 'A'))
})

test('evidence labels use the specified count bands', () => {
  assert.deepEqual([0, 2, 3, 5, 6, 14, 15].map(evidenceLabel), [
    'Very limited', 'Very limited', 'Limited', 'Limited', 'Moderate', 'Moderate', 'Strong',
  ])
})

test('illustrative utilities and expected-utility decision report ties explicitly', () => {
  assert.deepEqual(defaults, {value: 3, cost: 3, exploitation: 3, relationship: 3})
  assert.deepEqual([
    utility(defaults, 'Cooperate', 'Cooperate'),
    utility(defaults, 'Cooperate', 'Defect'),
    utility(defaults, 'Defect', 'Cooperate'),
    utility(defaults, 'Defect', 'Defect'),
  ], [3, -6, -1.5, -3])
  assert.equal(expectedUtility(defaults, 1, 'Cooperate'), 3)
  const tied = decide({value: 0, cost: 0, exploitation: 0, relationship: 0}, 0.5, 0.5)
  assert.equal(tied.move, undefined)
  assert.match(tied.explanation, /tie/i)
  assert.match(decide(defaults, 0, 1).explanation, /0%.*100%.*-6\.0.*-1\.5/)
  assert.equal(decide(defaults, 0, 1).move, 'Defect')
  const withCost = {...defaults, cost: 5}
  const withExploitation = {...defaults, exploitation: 5}
  const withValue = {...defaults, value: 5}
  const withRelationship = {...defaults, relationship: 5}
  assert.ok(expectedUtility(withCost, 0.5, 'Cooperate') < expectedUtility(defaults, 0.5, 'Cooperate'))
  assert.ok(expectedUtility(withExploitation, 0.1, 'Cooperate') < expectedUtility(defaults, 0.1, 'Cooperate'))
  assert.ok(expectedUtility(withValue, 0.5, 'Cooperate') > expectedUtility(defaults, 0.5, 'Cooperate'))
  assert.ok(utility(withRelationship, 'Cooperate', 'Cooperate') > utility(defaults, 'Cooperate', 'Cooperate'))
  assert.ok(utility(withRelationship, 'Defect', 'Defect') < utility(defaults, 'Defect', 'Defect'))
  assert.equal(decide(defaults, 1, 0).move, 'Cooperate')
})
