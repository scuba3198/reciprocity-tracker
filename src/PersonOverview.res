type recentEntry = {ledgerName: string, ledgerIndex: int, entryIndex: int, entry: State.entry}
@module("./InteractionDate.js") external displayDate: string => string = "displayDate"

let recentEntries = (person: State.person): array<recentEntry> => {
  let entries = person->State.allLedgers->Array.flatMapWithIndex((ledger, ledgerIndex) =>
    ledger.entries->Array.mapWithIndex((entry, entryIndex) => {ledgerName: ledger.name, ledgerIndex, entryIndex, entry})
  )
  let _ = Array.sort(entries, (a, b) =>
    if a.entry.date != b.entry.date {
      a.entry.date > b.entry.date ? -1. : 1.
    } else if a.ledgerIndex != b.ledgerIndex {
      Int.toFloat(a.ledgerIndex - b.ledgerIndex)
    } else {
      Int.toFloat(b.entryIndex - a.entryIndex)
    }
  )
  entries
}

@react.component
let make = (~person: State.person, ~tolerance: int) => {
  let ledgers = person->State.allLedgers
  let recent = person->recentEntries->Array.slice(~start=0, ~end=6)
  <section className="person-overview" ariaLabel="Person overview">
    <div className="history-heading"><div><h2>{React.string("Person overview")}</h2><p>{React.string("This is context, not a combined CURE score.")}</p></div></div>
    <div className="person-overview-table-wrap"><table>
      <thead><tr><th scope="col">{React.string("Ledger")}</th><th scope="col">{React.string("Confirmed interactions")}</th><th scope="col">{React.string("Defection balance")}</th><th scope="col">{React.string("Active tolerance")}</th></tr></thead>
      <tbody>{ledgers->Array.map(ledger => {
        let decision = State.next(ledger.entries, ~tolerance=State.effectiveTolerance(tolerance, person.cureDeltaOverride, ledger.cureDeltaOverride))
        <tr key={ledger.id}><th scope="row">{React.string(ledger.name)}</th><td>{React.string(Int.toString(Array.length(ledger.entries)))}</td><td>{React.string(Int.toString(decision.difference))}</td><td>{React.string(State.toleranceLabel(State.effectiveTolerance(tolerance, person.cureDeltaOverride, ledger.cureDeltaOverride)))}</td></tr>
      })->React.array}</tbody>
    </table></div>
    <p className="person-overview-balance-help">{React.string("A positive balance means more of their defections; a negative balance means more of yours. Balances stay separate by ledger.")}</p>
    <div className="history-heading person-overview-history-heading"><div><h3>{React.string("Recent confirmed interactions")}</h3><p>{React.string("Latest six by completion date. Same-day interactions are grouped by ledger.")}</p></div></div>
    {recent->Array.length == 0
      ? <p className="history-empty">{React.string("No confirmed interactions yet.")}</p>
      : <ol className="history-list person-overview-history">{recent->Array.map(item => {
          let entry = item.entry
          <li key={item.ledgerName ++ item.entry.date ++ Int.toString(item.ledgerIndex) ++ ":" ++ Int.toString(item.entryIndex)}>
            <span className="history-symbol">{React.string("•")}</span>
            <div><strong>{React.string(item.ledgerName ++ " · You: " ++ State.actionLabel(entry.myMove) ++ " · Them: " ++ State.actionLabel(entry.move))}</strong>{entry.category != "" ? <span className="history-category">{React.string(entry.category)}</span> : React.null}{entry.note != "" ? <p>{React.string(entry.note)}</p> : React.null}</div>
            <time>{React.string(displayDate(entry.date))}</time>
          </li>
        })->React.array}</ol>}
  </section>
}
