type move = Cooperate | Defect
type entry = {move: option<move>, myMove: option<move>, note: string, date: string, category: string, myActionDate: string, theirActionDate: string}
type draft = {id: string, move: string, myMove: string, note: string, date: string, category: string, myActionDate: string, theirActionDate: string}
type person = {id: string, name: string, entries: array<entry>, drafts: array<draft>}
type historyItem = {entry: entry, recommended: move, differenceBefore: int, sourceIndex: int}
type indexedEntry = {entry: entry, sourceIndex: int}
type decision = {move: move, rule: string, explanation: string, difference: int}

@module("./InteractionDate.js") external orderedEntries: array<entry> => array<entry> = "orderedEntries"
@module("./InteractionDate.js") external orderedIndexedEntries: array<entry> => array<indexedEntry> = "orderedIndexedEntries"

// Li et al. (2022): d is their total defections minus yours, before the next round.
let update = (difference, entry: entry) =>
  difference + (entry.move == Some(Defect) ? 1 : 0) - (entry.myMove == Some(Defect) ? 1 : 0)

let actionFromChoice = choice => switch choice {
| "Cooperate" => Some(Cooperate)
| "Defect" => Some(Defect)
| _ => None
}
let choiceFromAction = action => switch action {
| Some(Cooperate) => "Cooperate"
| Some(Defect) => "Defect"
| None => "NoAction"
}
let validChoices = (mine, theirs) => {
  let chosen = choice => choice == "Cooperate" || choice == "Defect" || choice == "NoAction"
  chosen(mine) && chosen(theirs) && (mine != "NoAction" || theirs != "NoAction")
}

let decide = (difference, tolerance) => {
  let rule = "CURE · difference " ++ Int.toString(difference) ++ " · tolerance " ++ Int.toString(tolerance)
  if difference <= tolerance {
    {move: Cooperate, rule, explanation: "The cumulative defection difference is within your tolerance. Cooperate.", difference}
  } else {
    {move: Defect, rule, explanation: "Their cumulative defections exceed yours by more than " ++ Int.toString(tolerance) ++ ". Withhold until the difference falls to " ++ Int.toString(tolerance) ++ " or less.", difference}
  }
}

let next = (entries: array<entry>, ~tolerance=2) => decide(entries->orderedEntries->Array.reduce(0, update), tolerance)

let history = (entries: array<entry>, ~tolerance=2): array<historyItem> => {
  let difference = ref(0)
  entries->orderedIndexedEntries->Array.map(({entry, sourceIndex}) => {
    let before = difference.contents
    let recommended = decide(before, tolerance).move
    difference.contents = update(before, entry)
    {entry, recommended, differenceBefore: before, sourceIndex}
  })
}

let replaceEntry = (entries: array<entry>, index: int, replacement: entry) =>
  entries->Array.mapWithIndex((entry, current) => current == index ? replacement : entry)

let actionLabel = action => switch action { | Some(Cooperate) => "Cooperated" | Some(Defect) => "Withheld" | None => "No action" }
