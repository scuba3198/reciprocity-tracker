const key = 'good-faith.think-ahead.v1'
const likelihoods = new Set(['Very unlikely', 'Unlikely', 'Possible', 'Likely', 'Very likely'])
const credibilities = new Set(['Probably not', 'Maybe', 'Probably yes'])
const utility = value => Number.isInteger(value) && value >= -2 && value <= 2
const text = value => typeof value === 'string'

export const validConsequence = value => value && text(value.id) && text(value.description) &&
  likelihoods.has(value.likelihood) && utility(value.utility) && typeof value.dependsOnPerson === 'boolean' &&
  credibilities.has(value.credibility)

export const validChoice = value => value && text(value.label) && utility(value.immediateUtility) &&
  Array.isArray(value.consequences) && value.consequences.every(validConsequence)

export const validScenario = value => value && text(value.id) && value.id.trim() &&
  text(value.title) && text(value.personId) && text(value.createdAt) && text(value.updatedAt) &&
  validChoice(value.choiceA) && validChoice(value.choiceB)

export function decode(raw) {
  try {
    const scenarios = typeof raw === 'string' ? JSON.parse(raw) : raw
    return Array.isArray(scenarios) && scenarios.every(validScenario) &&
      new Set(scenarios.map(item => item.id)).size === scenarios.length ? scenarios : []
  } catch {
    return []
  }
}

export const serialize = scenarios => JSON.stringify(scenarios)
export const load = () => decode(localStorage.getItem(key))
export const save = scenarios => localStorage.setItem(key, serialize(scenarios))
