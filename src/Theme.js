const key = 'good-faith-theme'
const valid = new Set(['auto', 'light', 'dark'])
const systemDark = matchMedia('(prefers-color-scheme: dark)')

export function load() {
  try {
    const choice = localStorage.getItem(key)
    return valid.has(choice) ? choice : 'auto'
  } catch {
    return 'auto'
  }
}

function render(choice) {
  document.documentElement.dataset.theme = choice === 'auto' ? (systemDark.matches ? 'dark' : 'light') : choice
}

export function apply(choice) {
  if (!valid.has(choice)) return
  try { localStorage.setItem(key, choice) } catch {}
  render(choice)
}

systemDark.addEventListener('change', () => { if (load() === 'auto') render('auto') })
render(load())
