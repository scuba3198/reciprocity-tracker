const localDay = date => `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
const monthFormatter = new Intl.DateTimeFormat('en-US', {month: 'long', year: 'numeric'})
const dayFormatter = new Intl.DateTimeFormat('en-US', {weekday: 'long', month: 'long', day: 'numeric', year: 'numeric'})

export const today = () => localDay(new Date())

export function calendarMonth(month) {
  const [year, number] = month.split('-').map(Number)
  const first = new Date(year, number - 1, 1, 12)
  const lastDay = new Date(year, number, 0, 12).getDate()
  const currentDay = today()
  const days = Array.from({length: first.getDay()}, () => ({date: '', label: '', accessible: '', disabled: true}))
  for (let day = 1; day <= lastDay; day++) {
    const date = `${month}-${String(day).padStart(2, '0')}`
    days.push({date, label: String(day), accessible: dayFormatter.format(new Date(year, number - 1, day, 12)), disabled: date > currentDay})
  }
  return {
    title: monthFormatter.format(first),
    days,
    previous: localDay(new Date(year, number - 2, 1, 12)).slice(0, 7),
    next: localDay(new Date(year, number, 1, 12)).slice(0, 7),
    previousDisabled: month <= '0100-01',
    nextDisabled: month >= currentDay.slice(0, 7),
  }
}

export function yesterday() {
  const date = new Date()
  date.setDate(date.getDate() - 1)
  return localDay(date)
}

export function normalize(value) {
  const match = /^(\d{4})-?(\d{2})-?(\d{2})$/.exec(value)
  if (!match) return null
  const normalized = `${match[1]}-${match[2]}-${match[3]}`
  if (normalized > today()) return null
  const [year, month, day] = match.slice(1).map(Number)
  const date = new Date(year, month - 1, day, 12)
  return date.getFullYear() === year && date.getMonth() === month - 1 && date.getDate() === day ? normalized : null
}

export function fromTimestamp(timestamp) {
  const date = new Date(timestamp)
  return Number.isFinite(date.getTime()) ? localDay(date) : null
}

export function orderedEntries(entries) {
  return [...entries].sort((a, b) => a.date < b.date ? -1 : a.date > b.date ? 1 : 0)
}
