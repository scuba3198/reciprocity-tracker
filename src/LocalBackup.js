import {normalize} from './InteractionDate.js'
import {decode as decodeScenarios} from './ThinkAheadStorage.js'

const choices = new Set(['Cooperate', 'Defect', 'Request', 'Unable'])
const fields = (value, names) => value && typeof value === 'object' && !Array.isArray(value) && names.every(name => Object.hasOwn(value, name))
const text = value => typeof value === 'string'
const validDate = value => value === '' || normalize(value) === value
const validMove = value => choices.has(value)
const validPair = (mine, theirs) => validMove(mine) && validMove(theirs) &&
  (mine === 'Cooperate' || mine === 'Defect' || theirs === 'Cooperate' || theirs === 'Defect' || (mine === 'Request' && theirs === 'Unable') || (mine === 'Unable' && theirs === 'Request'))

const validDraft = draft => fields(draft, ['id', 'move', 'myMove', 'note', 'date', 'category', 'myActionDate', 'theirActionDate']) &&
  ['id', 'move', 'myMove', 'note', 'date', 'category', 'myActionDate', 'theirActionDate'].every(key => text(draft[key])) &&
  draft.id.trim() !== '' && [draft.move, draft.myMove].every(value => value === '' || validMove(value))

const validEntry = entry => fields(entry, ['move', 'myMove', 'note', 'date', 'category', 'myActionDate', 'theirActionDate']) &&
  ['move', 'myMove', 'note', 'date', 'category', 'myActionDate', 'theirActionDate'].every(key => text(entry[key])) &&
  validPair(entry.myMove, entry.move) && validDate(entry.date) && entry.date !== '' && validDate(entry.myActionDate) && validDate(entry.theirActionDate) &&
  (!entry.myActionDate || entry.myActionDate <= entry.date) && (!entry.theirActionDate || entry.theirActionDate <= entry.date)

const validPerson = person => fields(person, ['id', 'name', 'entries', 'drafts']) && text(person.id) && person.id.trim() !== '' &&
  text(person.name) && person.name.trim() !== '' && Array.isArray(person.entries) && person.entries.every(validEntry) &&
  Array.isArray(person.drafts) && person.drafts.every(validDraft)

export function decode(raw) {
  try {
    const backup = JSON.parse(raw)
    if (!fields(backup, ['version', 'people', 'tolerance']) || backup.version !== 1 ||
        ![1, 2].includes(backup.tolerance) || !Array.isArray(backup.people) || !backup.people.every(validPerson) ||
        new Set(backup.people.map(person => person.id)).size !== backup.people.length) return undefined
    if (backup.scenarios !== undefined && !Array.isArray(backup.scenarios)) return undefined
    const scenarios = backup.scenarios === undefined ? [] : decodeScenarios(backup.scenarios)
    if (backup.scenarios !== undefined && scenarios.length !== backup.scenarios.length) return undefined
    return [JSON.stringify(backup.people), backup.tolerance, JSON.stringify(scenarios)]
  } catch {
    return undefined
  }
}

export function download(peopleJSON, tolerance, scenariosJSON = '[]') {
  const blob = new Blob([JSON.stringify({version: 1, people: JSON.parse(peopleJSON), tolerance, scenarios: JSON.parse(scenariosJSON)}, null, 2)], {type: 'application/json'})
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = 'reciprocity-tracker-backup.json'
  link.click()
  URL.revokeObjectURL(url)
}

export function readFile(input) {
  const file = input.files[0]
  input.value = ''
  return file ? file.text() : Promise.resolve('')
}
