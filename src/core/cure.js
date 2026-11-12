// Implements CURE from Li, Zhao, Li, Rossetti, Hilbe & Xia (2022),
// "Evolution of cooperation through cumulative reciprocity", Nat. Comput. Sci. 2, 677–686.
// n_A = my defections, n_B = their defections. d = n_B − n_A.
// I cooperate iff d ≤ Δ; I defect iff d > Δ. Every defection counts as exactly 1. Nothing is ever reset.
// Storage note: outcomes are stored as 'yes' (cooperated), 'no' (defected), 'waiting' for backward compatibility.

import { signed, plural } from './util.js';

export const DEFAULT_DELTA = 1;
export const MAX_DELTA = 20;

export function clampDelta(v) {
  const n = parseInt(v, 10);
  return isNaN(n) ? DEFAULT_DELTA : Math.max(0, Math.min(MAX_DELTA, n));
}

/** Effect of one event on d: they defected → n_B+1 → d+1; I defected → n_A+1 → d−1. */
export function effect(e) {
  if (e.outcome !== 'no') return 0;
  return e.dir === 'iAsked' ? 1 : -1;
}

export function stats(p) {
  let nA = 0, nB = 0;
  p.events.forEach(e => {
    if (e.outcome !== 'no') return;
    if (e.dir === 'iAsked') nB++; else nA++;
  });
  return { nA, nB, d: nB - nA };
}

export function ruleCooperates(p) { return stats(p).d <= p.delta; }

/** Plain-language explanation of the rule's verdict for a given d and Δ. */
export function explain(d, D) {
  let why;
  if (d <= D) {
    const h = D - d;
    why = 'd = ' + signed(d) + ' ≤ Δ = ' + D + '. ' + (h === 0
      ? 'You are on the line: one more defection from them takes d to ' + signed(D + 1) + ' and switches the rule to defect.'
      : 'They can defect ' + h + ' more ' + plural(h, 'time') + ' and the rule still says cooperate. The defection after that takes d to ' + signed(D + 1) + ' and switches it to defect.');
  } else {
    const k = d - D;
    why = 'd = ' + signed(d) + ' > Δ = ' + D + '. Each defection from you lowers d by 1. ' + (k === 1
      ? 'After one defection, d is back to ' + signed(D) + ' and you cooperate again.'
      : 'After ' + k + ' defections from you, d is back to ' + signed(D) + ' and you cooperate again.') +
      ' From then on, each defection from them is matched by one from you.';
  }
  const note = d < 0
    ? 'You have defected ' + (-d) + ' more ' + plural(-d, 'time') + ' than they have. The rule still says cooperate.'
    : null;
  return { why, note };
}
