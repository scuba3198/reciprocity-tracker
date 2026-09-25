type move = Cooperate | Defect
type phase = Open | Grace(int) | Protect

type entry = {move: move, note: string, date: string}
type person = {id: string, name: string, entries: array<entry>}

@module("./InteractionDate.js") external orderedEntries: array<entry> => array<entry> = "orderedEntries"

let advance = (phase, move) => switch (phase, move) {
| (Open, Cooperate) => Open
| (Open, Defect) => Grace(0)
| (Grace(0), Cooperate) => Grace(1)
| (Grace(_), Cooperate) => Open
| (Grace(_), Defect) => Protect
| (Protect, Cooperate) => Grace(1)
| (Protect, Defect) => Protect
}

let phase = (entries: array<entry>) =>
  entries->orderedEntries->Array.reduce(Open, (current, entry) => advance(current, entry.move))

let nextMove = phase => switch phase {
| Protect => Defect
| _ => Cooperate
}

let label = move => switch move {
| Cooperate => "Cooperated"
| Defect => "Defected"
}

let phaseLabel = phase => switch phase {
| Open => "In good standing"
| Grace(0) => "One chance given"
| Grace(_) => "Trust rebuilding"
| Protect => "Hold your boundary"
}

let explanation = phase => switch phase {
| Open => "Keep cooperating. A first slip gets one pass."
| Grace(0) => "You forgave one defection. Two cooperative moves in a row clear it."
| Grace(_) => "One clean move down. One more clears the strike."
| Protect => "A second defection came before trust was rebuilt. Withhold cooperation until they cooperate."
}
