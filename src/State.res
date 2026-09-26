type move = Cooperate | Defect
type entry = {move: move, myMove: move, note: string, date: string}
type person = {id: string, name: string, entries: array<entry>}
type historyItem = {entry: entry, recommended: move, differenceBefore: int}
type decision = {move: move, rule: string, explanation: string, difference: int}

@module("./InteractionDate.js") external orderedEntries: array<entry> => array<entry> = "orderedEntries"

// Li et al. (2022): d is their total defections minus yours, before the next round.
let tolerance = 1
let update = (difference, entry: entry) =>
  difference + (entry.move == Defect ? 1 : 0) - (entry.myMove == Defect ? 1 : 0)

let decide = difference => {
  let rule = "CURE · difference " ++ Int.toString(difference) ++ " · tolerance " ++ Int.toString(tolerance)
  if difference <= tolerance {
    {move: Cooperate, rule, explanation: "The cumulative defection difference is within your tolerance. Cooperate.", difference}
  } else {
    {move: Defect, rule, explanation: "Their cumulative defections exceed yours by more than one. Withhold until the difference falls to one or less.", difference}
  }
}

let next = (entries: array<entry>) => entries->orderedEntries->Array.reduce(0, update)->decide

let history = (entries: array<entry>): array<historyItem> => {
  let difference = ref(0)
  entries->orderedEntries->Array.map(entry => {
    let before = difference.contents
    let recommended = decide(before).move
    difference.contents = update(before, entry)
    {entry, recommended, differenceBefore: before}
  })
}

let label = move => switch move { | Cooperate => "Cooperated" | Defect => "Defected" }
