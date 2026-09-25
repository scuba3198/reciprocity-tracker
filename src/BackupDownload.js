export function download(json) {
  const url = URL.createObjectURL(new Blob([json], {type: 'application/json'}))
  const link = document.createElement('a')
  link.href = url
  link.download = `good-faith-backup-${new Date().toISOString().slice(0, 10)}.json`
  link.click()
  setTimeout(() => URL.revokeObjectURL(url), 1000)
}
