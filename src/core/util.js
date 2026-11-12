export function today() {
  const d = new Date(), p = n => String(n).padStart(2, '0');
  return d.getFullYear() + '-' + p(d.getMonth() + 1) + '-' + p(d.getDate());
}
export function uid() { return Math.random().toString(36).slice(2, 9) + Date.now().toString(36); }
export function signed(n) { return n > 0 ? '+' + n : n < 0 ? '−' + (-n) : '0'; }
export function plural(n, w) { return n === 1 ? w : w + 's'; }
/** ISO date → "DD/MM". */
export function sd(iso) { const a = (iso || '').split('-'); return a.length === 3 ? a[2] + '/' + a[1] : '—'; }
/** Days since the event's date. */
export function age(ev) { const t = new Date(ev.date + 'T00:00:00').getTime(); return isNaN(t) ? 0 : Math.floor((Date.now() - t) / 864e5); }
/** Lowercase and strip diacritics, for search. */
export function fold(s) { return s.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, ''); }
export const byName = (a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base', numeric: true });
