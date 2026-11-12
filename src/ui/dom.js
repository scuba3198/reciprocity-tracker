export const $ = id => document.getElementById(id);

export function el(tag, cls, text) {
  const e = document.createElement(tag);
  if (cls) e.className = cls;
  if (text !== undefined) e.textContent = text;
  return e;
}

/** Segmented control: opts is [[value, label], ...]. */
export function seg(opts, cur, onPick) {
  const s = el('div', 'seg');
  s.setAttribute('role', 'group');
  opts.forEach(([v, label]) => {
    const b = el('button', v === cur ? 'on' : '', label);
    b.type = 'button';
    b.setAttribute('aria-pressed', String(v === cur));
    b.onclick = () => onPick(v);
    s.appendChild(b);
  });
  return s;
}

/** Colour for an effect on d. */
export const effColor = f => f > 0 ? 'var(--neg)' : f < 0 ? 'var(--pos)' : 'var(--muted)';
