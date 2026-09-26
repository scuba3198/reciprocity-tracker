let initials = (name: string) => {
  let parts = name->String.trim->String.split(" ")->Array.filter(part => part != "")
  switch (Belt.Array.get(parts, 0), Belt.Array.get(parts, Array.length(parts) - 1)) {
  | (None, _) => "?"
  | (Some(first), Some(last)) => first->String.slice(~start=0, ~end=1)->String.toUpperCase ++ (first == last ? "" : last->String.slice(~start=0, ~end=1)->String.toUpperCase)
  | _ => "?"
  }
}

let countLabel = (count, singular, plural) => Int.toString(count) ++ " " ++ (count == 1 ? singular : plural)
type recentItem = {person: State.person, entry: State.entry}
@send external sortRecent: (array<recentItem>, (recentItem, recentItem) => float) => array<recentItem> = "sort"

let trendPoints = (entries: array<State.entry>) =>
  Array.concat([0], entries->State.history->Array.map(item =>
    item.differenceBefore + (item.entry.move == State.Defect ? 1 : 0) - (item.entry.myMove == State.Defect ? 1 : 0)
  ))

let trendPath = (points: array<int>) => {
  let length = Array.length(points)
  let first = points->Array.get(0)->Option.getOr(0)
  let lower = points->Array.reduce(first, (a, b) => a < b ? a : b)
  let upper = points->Array.reduce(first, (a, b) => a > b ? a : b)
  let span = upper - lower > 1 ? upper - lower : 1
  points->Array.mapWithIndex((point, index) => {
    let x = length == 1 ? 30 : index * 60 / (length - 1)
    let y = 20 - (point - lower) * 16 / span
    Int.toString(x) ++ "," ++ Int.toString(y)
  })->Array.join(" ")
}

@react.component
let make = (~people: array<State.person>, ~onSelect: State.person => unit, ~onAdd: unit => unit, ~onLearn: unit => unit) => {
  let recent: array<recentItem> = people->Array.reduce([], (items, person) => {
    let history = person.entries->State.history->Belt.Array.reverse
    Array.concat(items, history->Array.map(item => {person, entry: item.entry}))
  })
  let recent = sortRecent(recent, (a, b) => String.compare(b.entry.date, a.entry.date))->Array.filterWithIndex((_, index) => index < 6)
  <div className="dashboard">
    <section className="dashboard-hero" ariaLabelledby="dashboard-title">
      <div className="dashboard-hero-copy">
    <h1 id="dashboard-title">{React.string("A more thoughtful you, one conversation at a time.")}</h1>
    <p className="dashboard-intro">{React.string("Track your interactions, see the bigger picture, and get suggested next moves with ")}<button className="dashboard-cure-link" type_="button" onClick={_ => onLearn()}>{React.string("CURE")}</button>{React.string(".")}</p>
        <button className="dashboard-cta" type_="button" onClick={_ => onAdd()}><span>{React.string("+")}</span>{React.string("Add someone")}</button>
      </div>
      <ul className="dashboard-hero-points">
        <li>{React.string("Log what you and they do")}</li>
        <li>{React.string("See the cumulative difference")}</li>
        <li>{React.string("Consider CURE’s suggested next move")}</li>
      </ul>
    </section>

    <section className="dashboard-section" ariaLabelledby="people-title">
      <div className="dashboard-section-heading"><h2 id="people-title">{React.string("People")}</h2><span>{React.string(countLabel(Array.length(people), "person", "people"))}</span></div>
      {Array.length(people) == 0
        ? <div className="dashboard-empty"><p>{React.string("Your people will find a home here.")}</p><button type_="button" onClick={_ => onAdd()}>{React.string("Add your first person →")}</button></div>
        : <div className="dashboard-people-rail">{people->Array.map(person => {
            let decision = State.next(person.entries)
            let count = Array.length(person.entries)
            let points = trendPoints(person.entries)
            let trendColor = decision.difference <= State.tolerance ? "#3e9366" : "#c76e55"
            <button key={person.id} type_="button" className="dashboard-person-card" onClick={_ => onSelect(person)} ariaLabel={"Open " ++ person.name}>
              <span className="dashboard-avatar" ariaHidden=true>{React.string(initials(person.name))}</span>
              <span className="dashboard-person-info"><strong>{React.string(person.name)}</strong><small>{React.string(countLabel(count, "interaction", "interactions"))}</small></span>
              {count == 0 ? React.null : <svg className="dashboard-trend" viewBox="0 0 60 24" role="img" ariaLabel={"Cumulative difference over " ++ Int.toString(count) ++ " recorded interactions"}><polyline points={trendPath(points)} fill="none" stroke={trendColor} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" /></svg>}
              <span className={decision.difference > State.tolerance ? "dashboard-difference caution" : "dashboard-difference"}><small>{React.string("difference")}</small><strong>{React.string(Int.toString(decision.difference))}</strong></span>
            </button>
          })->React.array}</div>}
    </section>

    <section className="dashboard-section dashboard-activity" ariaLabelledby="activity-title">
      <div className="dashboard-section-heading"><h2 id="activity-title">{React.string("Recent activity")}</h2>{recent->Array.length > 0 ? <span>{React.string(countLabel(Array.length(recent), "entry", "entries"))}</span> : React.null}</div>
      {recent->Array.length == 0
        ? <p className="dashboard-activity-empty">{React.string("Interactions you record will appear here.")}</p>
        : <ol className="dashboard-activity-list">{recent->Array.mapWithIndex((item, index) => <li key={item.person.id ++ item.entry.date ++ Int.toString(index)}>
              <span className={item.entry.move == State.Cooperate ? "dashboard-activity-mark cooperate" : "dashboard-activity-mark defect"}>{React.string(item.entry.move == State.Cooperate ? "C" : "D")}</span>
              <span className="dashboard-activity-copy"><strong>{React.string(item.person.name)}</strong><small>{React.string("They " ++ State.label(item.entry.move)->String.toLowerCase ++ (item.entry.category == "" ? "" : " · " ++ item.entry.category) ++ (item.entry.note == "" ? "" : " · " ++ item.entry.note))}</small></span>
              <time>{React.string(item.entry.date)}</time>
            </li>)->React.array}</ol>}
    </section>
  </div>
}




