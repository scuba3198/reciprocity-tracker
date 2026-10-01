type move = Cooperate | Defect
type action = Cooperated | Defected | Requested | Unable | NoAction
type entry = {move: action, myMove: action, note: string, date: string, category: string, myActionDate: string, theirActionDate: string}
type draft = {id: string, move: string, myMove: string, note: string, date: string, category: string, myActionDate: string, theirActionDate: string}
type ledger = {id: string, name: string, entries: array<entry>, drafts: array<draft>, cureDeltaOverride?: int}
type person = {id: string, name: string, entries: array<entry>, drafts: array<draft>, cureDeltaOverride?: int, generalCureDeltaOverride?: int, ledgers?: array<ledger>}
type historyItem = {entry: entry, recommended: move, differenceBefore: int, sourceIndex: int}
type indexedEntry = {entry: entry, sourceIndex: int}
type decision = {move: move, rule: string, explanation: string, difference: int}

@module("./InteractionDate.js") external orderedEntries: array<entry> => array<entry> = "orderedEntries"
@module("./InteractionDate.js") external orderedIndexedEntries: array<entry> => array<indexedEntry> = "orderedIndexedEntries"

// Li et al. (2022): d is their total defections minus yours, before the next round.
let update = (difference, entry: entry) =>
  difference + (entry.move == Defected ? 1 : 0) - (entry.myMove == Defected ? 1 : 0)

let actionFromChoice = choice => switch choice {
| "Cooperate" => Some(Cooperated)
| "Defect" => Some(Defected)
| "Request" => Some(Requested)
| "Unable" => Some(Unable)
| "NoAction" => Some(NoAction)
| _ => None
}
let choiceFromAction = action => switch action {
| Cooperated => "Cooperate"
| Defected => "Defect"
| Requested => "Request"
| Unable => "Unable"
| NoAction => "NoAction"
}
let validChoices = (mine, theirs) => {
  let chosen = choice => choice == "Cooperate" || choice == "Defect" || choice == "Request" || choice == "Unable" || choice == "NoAction"
  let acted = choice => choice == "Cooperate" || choice == "Defect"
  chosen(mine) && chosen(theirs) && (acted(mine) || acted(theirs) || (mine == "Request" && theirs == "Unable") || (mine == "Unable" && theirs == "Request"))
}

let effectiveTolerance = (global: int, personOverride: option<int>, ledgerOverride: option<int>) =>
  switch (ledgerOverride, personOverride) {
  | (Some(value), _) when value >= 1 && value <= 3 => value
  | (_, Some(value)) when value >= 1 && value <= 3 => value
  | _ when global >= 1 && global <= 3 => global
  | _ => 2
  }

let toleranceName = tolerance => switch tolerance { | 1 => "Guarded" | 3 => "Forgiving" | _ => "Balanced" }
let toleranceLabel = tolerance => toleranceName(tolerance) ++ " (Δ" ++ Int.toString(tolerance) ++ ")"
let toleranceHelp = tolerance => switch tolerance {
| 1 => "Responds sooner to persistent imbalance. Better suited to short, uncertain, or exploitation-prone interactions."
| 3 => "Allows more temporary imbalance before retaliation. Better suited to long-term or noisy relationships where mistakes and misunderstandings are common."
| _ => "Balances exploitation resistance with forgiveness. Recommended as the general default for repeated interactions."
}
let toleranceFromChoice = choice => switch choice { | "1" => Some(1) | "2" => Some(2) | "3" => Some(3) | _ => None }

let ledgerView = (person: person, ledgerId: string): person => switch ledgerId {
| "" => person
| id => switch person.ledgers->Option.getOr([])->Array.find(ledger => ledger.id == id) {
  | Some(ledger) => {...person, entries: ledger.entries, drafts: ledger.drafts}
  | None => {...person, entries: [], drafts: []}
  }
}

let allLedgers = (person: person): array<ledger> => {
  let general: ledger = {
    id: "", name: "General", entries: person.entries, drafts: person.drafts,
    cureDeltaOverride: ?person.generalCureDeltaOverride,
  }
  [general, ...person.ledgers->Option.getOr([])]
}

let updateLedger = (person: person, ledgerId: string, change: person => person): person => switch ledgerId {
| "" => change(person)
| id => {
    let changed = change(ledgerView(person, id))
    {...person, ledgers: ?Some(person.ledgers->Option.getOr([])->Array.map(ledger =>
      {...ledger, entries: ledger.id == id ? changed.entries : ledger.entries, drafts: ledger.id == id ? changed.drafts : ledger.drafts}))}
  }
}

let removeLedger = (person: person, ledgerId: string): person =>
  ledgerId == "" ? person : {...person, ledgers: person.ledgers->Option.getOr([])->Array.filter(ledger => ledger.id != ledgerId)}

let decide = (difference, tolerance) => {
  let activeTolerance = toleranceLabel(tolerance)
  let rule = "CURE · difference " ++ Int.toString(difference) ++ " · " ++ activeTolerance
  if difference <= tolerance {
    {move: Cooperate, rule, explanation: "The other person's cumulative defection advantage is " ++ Int.toString(difference) ++ ". Your " ++ toleranceName(tolerance) ++ " tolerance allows an imbalance of up to " ++ Int.toString(tolerance) ++ ".", difference}
  } else {
    {move: Defect, rule, explanation: "The other person's cumulative defection advantage is " ++ Int.toString(difference) ++ ". This exceeds your " ++ toleranceName(tolerance) ++ " tolerance of " ++ Int.toString(tolerance) ++ ".", difference}
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

let differentFromRecommendation = (action, recommended) => switch action {
| Cooperated => recommended != Cooperate
| Defected => recommended != Defect
| Requested | Unable | NoAction => false
}

let actionLabel = action => switch action { | Cooperated => "Cooperated" | Defected => "Defected" | Requested => "Requested" | Unable => "Unable" | NoAction => "No action" }
