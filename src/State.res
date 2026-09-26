type move = Cooperate | Defect
type entry = {move: move, myMove: option<move>, note: string, date: string}
type person = {id: string, name: string, entries: array<entry>}
type historyItem = {entry: entry, recommended: option<move>}
type memory = {mine: string, theirs: string, known: int}
type decision = {move: option<move>, rule: string, explanation: string}

@module("./InteractionDate.js") external orderedEntries: array<entry> => array<entry> = "orderedEntries"

let code = move => switch move { | Cooperate => "c" | Defect => "d" }
let initial = {mine: "ccc", theirs: "ccc", known: 3}

let remember = (memory, entry) => switch entry.myMove {
| None => {mine: "", theirs: "", known: 0}
| Some(mine) => {
    let minePrefix = memory.known == 3 ? memory.mine->String.slice(~start=1) : memory.mine
    let theirPrefix = memory.known == 3 ? memory.theirs->String.slice(~start=1) : memory.theirs
    {mine: minePrefix ++ code(mine), theirs: theirPrefix ++ code(entry.move), known: memory.known == 3 ? 3 : memory.known + 1}
  }
}

// Table 3 in Murase & Baek (2020): own last three moves are rows, their last three are columns.
let decide = memory => {
  if memory.known < 3 {
    {move: None, rule: "Complete three paired rounds", explanation: "An older entry has no recorded move from you. CAPRI needs three consecutive rounds with both moves to make an exact suggestion."}
  } else {
    switch (memory.mine, memory.theirs) {
    | ("ccc", "ccc") => {move: Some(Cooperate), rule: "C · Cooperate", explanation: "Continue mutual cooperation."}
    | ("ccd", "ccc") | ("cdc", "ccd") | ("dcc", "cdc") | ("ccc", "dcc") =>
      {move: Some(Cooperate), rule: "A · Accept", explanation: "Accept the other person’s response to your earlier defection and return to cooperation."}
    | ("ccc", "ccd") => {move: Some(Defect), rule: "P · Punish", explanation: "Respond once to their defection from mutual cooperation."}
    | ("ccd", "cdc") | ("cdc", "dcc") | ("dcc", "ccc") =>
      {move: Some(Cooperate), rule: "P · Punish", explanation: "The response has happened. Return to cooperation."}
    | ("ddd", "ddc") | ("ddc", "dcc") | ("ddc", "ddd") | ("dcc", "ddc") | ("ddc", "ddc") | ("dcc", "dcc") =>
      {move: Some(Cooperate), rule: "R · Recover", explanation: "A cooperative move offers a path out of mutual defection."}
    | _ => {move: Some(Defect), rule: "I · Defect otherwise", explanation: "CAPRI calls for a boundary in this three-round pattern."}
    }
  }
}

let next = (entries: array<entry>) => entries->orderedEntries->Array.reduce(initial, remember)->decide

let history = (entries: array<entry>): array<historyItem> => {
  let memory = ref(initial)
  entries->orderedEntries->Array.map(entry => {
    let recommended = decide(memory.contents).move
    memory.contents = remember(memory.contents, entry)
    {entry, recommended}
  })
}

let label = move => switch move { | Cooperate => "Cooperated" | Defect => "Defected" }
