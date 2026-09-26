@scope("Math") @val external round: float => int = "round"
@send external toFixed: (float, int) => string = "toFixed"

let percent = probability => Int.toString(round(probability *. 100.)) ++ "%"
let score = value => (value >= 0. ? "+" : "") ++ toFixed(value, 1)
let interactionCount = count => Int.toString(count) ++ (count == 1 ? " relevant interaction" : " relevant interactions")
let label = move => switch move { | State.Cooperate => "Cooperate" | State.Defect => "Withhold cooperation" }
type ratingHelp = {meaning: string, levels: array<string>}
let rating = (title, id, value, setValue, openHelp, setOpenHelp, help: ratingHelp) =>
  <div className="analysis-rating">
    <div className="analysis-rating-main">
      <div className="analysis-rating-name">
        <label htmlFor={id}>{React.string(title)}</label>
        <button className="rating-info" type_="button" ariaLabel={"About " ++ title} ariaExpanded={openHelp == id} ariaControls={id ++ "-help"} onClick={_ => setOpenHelp(previous => previous == id ? "" : id)}>{React.string("i")}</button>
      </div>
      <select id value={Int.toString(value)} onChange={event => {
        switch Int.fromString(JsxEvent.Form.target(event)["value"]) {
        | Some(next) if next >= 1 && next <= 5 => setValue(_ => next)
        | _ => ()
        }
      }}>
        {[1, 2, 3, 4, 5]->Array.map(number => <option key={Int.toString(number)} value={Int.toString(number)}>{React.string(Int.toString(number))}</option>)->React.array}
      </select>
    </div>
    <div id={id ++ "-help"} className="rating-help" hidden={openHelp != id}>
      <p>{React.string(help.meaning)}</p>
      <ol>{help.levels->Array.mapWithIndex((text, index) => <li key={Int.toString(index)}><strong>{React.string(Int.toString(index + 1))}</strong><span>{React.string(text)}</span></li>)->React.array}</ol>
    </div>
  </div>

@react.component
let make = (~entries: array<State.entry>, ~cure: State.move) => {
  let (category, setCategory) = React.useState(_ => "")
  let (analysisOpen, setOpen) = React.useState(_ => false)
  let (cost, setCost) = React.useState(_ => 3)
  let (value, setValue) = React.useState(_ => 3)
  let (exploitation, setExploitation) = React.useState(_ => 3)
  let (relationship, setRelationship) = React.useState(_ => 3)
  let (openHelp, setOpenHelp) = React.useState(_ => "")
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
          <p>{React.string("Choose the stakes for your next choice with this person: cooperate or withhold cooperation. These ratings change only this optional comparison, not CURE or any interaction you log. All start at 3.")}</p>
          {Array.length(categories) > 0
            ? <label className="analysis-category" htmlFor="decision-category"><span>{React.string("Category")}</span><select id="decision-category" value={selectedCategory} onChange={event => setCategory(_ => JsxEvent.Form.target(event)["value"])}><option value="">{React.string("All categories")}</option>{categories->Array.map(name => <option key={name} value={name}>{React.string(name)}</option>)->React.array}</select></label>
            : React.null}
          <div className="analysis-ratings">
            {rating("Cost of cooperating", "analysis-cost", cost, setCost, openHelp, setOpenHelp, {meaning: "What you would give up by doing your part next time: time, effort, money, or another opportunity. Rate the cost of your own cooperation, whether or not they cooperate.", levels: ["Very low: almost no sacrifice, such as a quick, easy favor.", "Low: a small amount of time or effort you can spare.", "Moderate: a noticeable commitment, but manageable.", "High: a substantial cost or competing priority.", "Very high: a major sacrifice you may not be able to afford."]})}
            {rating("Value of successful reciprocity", "analysis-value", value, setValue, openHelp, setOpenHelp, {meaning: "How valuable it would be if you both cooperate in the next interaction. Think about the shared result, not whether you expect them to follow through; the estimate handles that separately.", levels: ["Very low: the shared result would matter little.", "Low: helpful, but easy to do without.", "Moderate: a worthwhile benefit to you or a shared goal.", "High: an important result that would make a real difference.", "Very high: an especially valuable result for this situation."]})}
            {rating("Cost of being exploited", "analysis-exploitation", exploitation, setExploitation, openHelp, setOpenHelp, {meaning: "The extra loss if you cooperate and they do not, beyond the ordinary cost of your effort. Think about the practical setback or broken expectation, without guessing their motives.", levels: ["Very low: little extra harm beyond your own effort.", "Low: a small setback or disappointment.", "Moderate: a meaningful loss you could recover from.", "High: a serious setback, expense, or broken commitment.", "Very high: a severe loss. If safety or essential needs are involved, use judgment outside this model."]})}
            {rating("Importance of the long-term relationship", "analysis-relationship", relationship, setRelationship, openHelp, setOpenHelp, {meaning: "How much it matters to preserve a cooperative pattern with this person over future interactions. This measures the value of that ongoing connection; it never means tolerating harm or ignoring boundaries.", levels: ["Very low: little or no future interaction is expected.", "Low: future cooperation would be nice but not important.", "Moderate: an ongoing connection worth maintaining.", "High: a close or important continuing relationship.", "Very high: preserving healthy cooperation here is central to your future plans."]})}
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

