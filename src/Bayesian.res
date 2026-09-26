type estimate = {myMove: State.move, probability: float, observed: int, evidence: string}

// An observation-count cue for readers, not a posterior credible interval or statistical confidence.
let evidenceLabel = count =>
  if count <= 2 {"Very limited"}
  else if count <= 5 {"Limited"}
  else if count <= 14 {"Moderate"}
  else {"Strong"}

let countFor = (entries: array<State.entry>, myMove, category) => {
  entries->Array.reduce((0, 0), (counts, entry) =>
    if entry.myMove != myMove || (category != "" && entry.category != category) {
      counts
    } else {
      let (cooperations, total) = counts
      (cooperations + (if entry.move == State.Cooperate {1} else {0}), total + 1)
    }
  )
}

let estimate = (entries: array<State.entry>, myMove: State.move, category: option<string>): estimate => {
  let (overallCooperations, overallCount) = countFor(entries, myMove, "")
  let overall = (1. +. Float.fromInt(overallCooperations)) /. (2. +. Float.fromInt(overallCount))
  let (probability, observed) = switch category {
  | None => (overall, overallCount)
  | Some(category) => {
    let (cooperations, count) = countFor(entries, myMove, category)
    // Two pseudo-observations at the person's overall rate soften sparse category estimates.
    ((Float.fromInt(cooperations) +. 2. *. overall) /. (Float.fromInt(count) +. 2.), count)
  }
  }
  {myMove, probability, observed, evidence: evidenceLabel(observed)}
}
