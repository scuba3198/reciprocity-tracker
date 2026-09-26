@scope("Math") @val external round: float => int = "round"
@send external toFixed: (float, int) => string = "toFixed"

let percent = probability => Int.toString(round(probability *. 100.)) ++ "%"
let score = value => (value >= 0. ? "+" : "") ++ toFixed(value, 1)
let interactionCount = count => Int.toString(count) ++ (count == 1 ? " relevant interaction" : " relevant interactions")
let label = move => switch move { | State.Cooperate => "Cooperate" | State.Defect => "Withhold cooperation" }
let rating = (title, id, value, setValue) =>
  <label className="analysis-rating" htmlFor={id}>
    <span>{React.string(title)}</span>
    <select id value={Int.toString(value)} onChange={event => {
      switch Int.fromString(JsxEvent.Form.target(event)["value"]) {
      | Some(next) if next >= 1 && next <= 5 => setValue(_ => next)
      | _ => ()
      }
    }}>
      {[1, 2, 3, 4, 5]->Array.map(number => <option key={Int.toString(number)} value={Int.toString(number)}>{React.string(Int.toString(number))}</option>)->React.array}
    </select>
  </label>

@react.component
let make = (~entries: array<State.entry>, ~cure: State.move) => {
  let (category, setCategory) = React.useState(_ => "")
  let (analysisOpen, setOpen) = React.useState(_ => false)
  let (cost, setCost) = React.useState(_ => 3)
  let (value, setValue) = React.useState(_ => 3)
  let (exploitation, setExploitation) = React.useState(_ => 3)
  let (relationship, setRelationship) = React.useState(_ => 3)
  let categories = entries->Array.reduce([], (names, entry) =>
    entry.category != "" && !(names->Array.some(name => name == entry.category))
      ? Array.concat(names, [entry.category])
      : names
  )
  let selectedCategory = categories->Array.some(name => name == category) ? category : ""
  let scope = selectedCategory == "" ? None : Some(selectedCategory)
  let cooperate = Bayesian.estimate(entries, State.Cooperate, scope)
  let defect = Bayesian.estimate(entries, State.Defect, scope)
  let params: DecisionAnalysis.params = {cost: Float.fromInt(cost), value: Float.fromInt(value), exploitation: Float.fromInt(exploitation), relationship: Float.fromInt(relationship)}
  let result = DecisionAnalysis.decide(params, cooperate.probability, defect.probability)
  <section className="person-analysis" ariaLabel="Optional behavior and decision analysis">
    <details className="learned-behavior">
      <summary>{React.string("Learned behavior")}</summary>
      <p>{React.string("Based on the interactions you've logged. Estimates may change as you record more.")}</p>
      {Array.length(categories) > 0
        ? <label className="analysis-category" htmlFor="analysis-category"><span>{React.string("Category")}</span><select id="analysis-category" value={selectedCategory} onChange={event => setCategory(_ => JsxEvent.Form.target(event)["value"])}><option value="">{React.string("All categories")}</option>{categories->Array.map(name => <option key={name} value={name}>{React.string(name)}</option>)->React.array}</select></label>
        : React.null}
      <div className="behavior-estimates">
        <div><span>{React.string("When you cooperate")}</span><strong>{React.string(percent(cooperate.probability) ++ " estimated cooperation")}</strong><small>{React.string(interactionCount(cooperate.observed) ++ " · " ++ cooperate.evidence ++ " history")}</small></div>
        <div><span>{React.string("When you withhold cooperation")}</span><strong>{React.string(percent(defect.probability) ++ " estimated cooperation")}</strong><small>{React.string(interactionCount(defect.observed) ++ " · " ++ defect.evidence ++ " history")}</small></div>
      </div>
      {selectedCategory != "" ? <p>{React.string("Category estimates use this person's overall history when category history is sparse.")}</p> : React.null}
      <p>{React.string("Estimated from your history using Bayesian updating. Evidence labels describe sample size, not statistical confidence.")}</p>
    </details>
    <button className="analysis-toggle" type_="button" ariaExpanded={analysisOpen} ariaControls="decision-analysis" onClick={_ => setOpen(previous => !previous)}>{React.string(analysisOpen ? "Close decision analysis" : "Help me decide")}</button>
    {analysisOpen
      ? <section id="decision-analysis" className="analysis-panel" ariaLabel="Decision analysis">
          <h2>{React.string("Decision analysis")}</h2>
          <p>{React.string("Choose the stakes for this decision. All ratings start at 3; 1 is very low and 5 is very high.")}</p>
          {Array.length(categories) > 0
            ? <label className="analysis-category" htmlFor="decision-category"><span>{React.string("Category")}</span><select id="decision-category" value={selectedCategory} onChange={event => setCategory(_ => JsxEvent.Form.target(event)["value"])}><option value="">{React.string("All categories")}</option>{categories->Array.map(name => <option key={name} value={name}>{React.string(name)}</option>)->React.array}</select></label>
            : React.null}
          <div className="analysis-ratings">
            {rating("Cost of cooperating", "analysis-cost", cost, setCost)}
            {rating("Value of successful reciprocity", "analysis-value", value, setValue)}
            {rating("Cost of being exploited", "analysis-exploitation", exploitation, setExploitation)}
            {rating("Importance of the long-term relationship", "analysis-relationship", relationship, setRelationship)}
          </div>
          <div className="analysis-results">
            <p><strong>{React.string("CURE recommendation: " ++ label(cure))}</strong></p>
            <p><strong>{React.string("Decision-model recommendation: " ++ switch result.move { | Some(move) => label(move) | None => "No clear advantage" })}</strong></p>
            <p>{React.string("Estimated response if you cooperate: " ++ percent(cooperate.probability) ++ " cooperate (" ++ interactionCount(cooperate.observed) ++ ").")}</p>
            <p>{React.string("Estimated response if you withhold cooperation: " ++ percent(defect.probability) ++ " cooperate (" ++ interactionCount(defect.observed) ++ ").")}</p>
            <p>{React.string("Expected utility · Cooperate: " ++ score(result.cooperateUtility) ++ " · Withhold: " ++ score(result.defectUtility))}</p>
            <p>{React.string(result.explanation)}</p>
            {cooperate.observed < 6 || defect.observed < 6
              ? <p className="analysis-caution">{React.string("Confidence: Low — " ++ (defect.observed < 6 ? "limited history of how this person responds when you withhold cooperation." : "limited history of how this person responds when you cooperate.") ++ " This describes evidence volume, not a statistical confidence interval.")}</p>
              : React.null}
            {switch result.move {
            | Some(move) if move != cure => <p className="analysis-disagreement">{React.string("These recommendations disagree. CURE responds to cumulative reciprocity; decision analysis responds to estimated behavior and the stakes you entered.")}</p>
            | _ => React.null
            }}
          </div>
          <p className="analysis-footnote">{React.string("This is a decision aid. CURE remains the reciprocity strategy; you make the final decision.")}</p>
        </section>
      : React.null}
  </section>
}

