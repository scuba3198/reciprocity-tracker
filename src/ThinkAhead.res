type consequence = {id: string, description: string, likelihood: string, utility: int, dependsOnPerson: bool, credibility: string}
type choice = {label: string, immediateUtility: int, consequences: array<consequence>}
type scenario = {id: string, title: string, personId: string, createdAt: string, updatedAt: string, choiceA: choice, choiceB: choice}

let canSave = scenario => String.trim(scenario.title) != "" && String.trim(scenario.choiceA.label) != "" && String.trim(scenario.choiceB.label) != "" && Array.concat(scenario.choiceA.consequences, scenario.choiceB.consequences)->Array.every(item => String.trim(item.description) != "")
let likelihoodValue = value => switch value { | "Very unlikely" => 0.1 | "Unlikely" => 0.25 | "Likely" => 0.75 | "Very likely" => 0.9 | _ => 0.5 }
let credibilityValue = value => switch value { | "Probably not" => 0.25 | "Probably yes" => 1. | _ => 0.6 }
@send external fixed: (float, int) => string = "toFixed"
let abs = value => value < 0. ? -.value : value
let score = choice => choice.consequences->Array.reduce(Float.fromInt(choice.immediateUtility), (total, item) => total +. Float.fromInt(item.utility) *. likelihoodValue(item.likelihood) *. (item.dependsOnPerson ? credibilityValue(item.credibility) : 1.))
let result = (choiceA, choiceB) => {
  let scoreA = score(choiceA)
  let scoreB = score(choiceB)
  (scoreA, scoreB, scoreA > scoreB ? choiceA.label : scoreB > scoreA ? choiceB.label : "Neither option")
}
let closeCall = (choiceA, choiceB) => abs(score(choiceA) -. score(choiceB)) <= 0.5
let formatScore = value => fixed(value, 1)
let now = () => Date.make()->Date.toISOString
let blankChoice = label => {label, immediateUtility: 0, consequences: []}
let blankScenario = () => {id: Storage.randomUUID(), title: "", personId: "", createdAt: now(), updatedAt: now(), choiceA: blankChoice("Option A"), choiceB: blankChoice("Option B")}
let likelihoods = [("Very unlikely", "Very unlikely (~10%)"), ("Unlikely", "Unlikely (~25%)"), ("Possible", "Possible (~50%)"), ("Likely", "Likely (~75%)"), ("Very likely", "Very likely (~90%)")]
let credibilities = [("Probably not", "Probably not (~25%)"), ("Maybe", "Maybe (~60%)"), ("Probably yes", "Probably yes (~100%)")]
let options = (values, selected, onSelect) => <select value={selected} onChange={event => onSelect(JsxEvent.Form.target(event)["value"])}>{values->Array.map(((value, label)) => <option key={value} value={value}>{React.string(label)}</option>)->React.array}</select>
let utilityOptions = (selected, onSelect) => <select value={Int.toString(selected)} onChange={event => onSelect(JsxEvent.Form.target(event)["value"]->Int.fromString->Option.getOr(0))}>{[(-2, "Very bad"), (-1, "Bad"), (0, "Neutral"), (1, "Good"), (2, "Very good")]->Array.map(((value, label)) => <option key={Int.toString(value)} value={Int.toString(value)}>{React.string(label)}</option>)->React.array}</select>
let inputValue = event => JsxEvent.Form.target(event)["value"]
let updateChoice = (scenario, isA, choice) => isA ? {...scenario, choiceA: choice} : {...scenario, choiceB: choice}
let changeConsequences = (choice, consequences) => {...choice, consequences}
let replaceAt = (items, index, replacement) => items->Array.mapWithIndex((item, i) => i == index ? replacement : item)
let calculationLines = choice => Array.concat([choice.label ++ " immediate effect: " ++ Int.toString(choice.immediateUtility)], Array.concat(choice.consequences->Array.map(item => item.description ++ ": " ++ Int.toString(item.utility) ++ " × " ++ item.likelihood ++ (item.dependsOnPerson ? " × " ++ item.credibility ++ " confidence" : " (person confidence not applied)") ++ " = " ++ fixed(Float.fromInt(item.utility) *. likelihoodValue(item.likelihood) *. (item.dependsOnPerson ? credibilityValue(item.credibility) : 1.), 2)), ["Expected total: " ++ fixed(score(choice), 2)]))
let resultPanel = (title, choiceA, choiceB) => {
  let (scoreA, scoreB, winner) = result(choiceA, choiceB)
  let gap = abs(scoreA -. scoreB)
  let contributions = Array.concat(choiceA.consequences->Array.map(item => (item.description, abs(Float.fromInt(item.utility) *. likelihoodValue(item.likelihood) *. (item.dependsOnPerson ? credibilityValue(item.credibility) : 1.)))), choiceB.consequences->Array.map(item => (item.description, abs(Float.fromInt(item.utility) *. likelihoodValue(item.likelihood) *. (item.dependsOnPerson ? credibilityValue(item.credibility) : 1.)))))
  let dominant = contributions->Array.reduce(("", 0.), ((name, amount), (candidate, value)) => value > amount ? (candidate, value) : (name, amount))
  <section className="ta-panel ta-live-result"><p className="ta-eyebrow">{React.string("Scenario results")}</p><h2>{React.string(title)}</h2><h3>{React.string(closeCall(choiceA, choiceB) ? "Close call: estimates are within 0.5 points" : "Current estimate favors " ++ winner)}</h3><div className="ta-score-grid"><div><span>{React.string(choiceA.label)}</span><strong>{React.string(formatScore(scoreA))}</strong></div><div><span>{React.string(choiceB.label)}</span><strong>{React.string(formatScore(scoreB))}</strong></div></div><p>{React.string("Approximate score = immediate effect + each outcome’s utility × likelihood × confidence when tied to a person. Scores are estimates, not probabilities or advice.")}</p><details><summary>{React.string("How these scores were calculated")}</summary><ul>{Array.concat(calculationLines(choiceA), calculationLines(choiceB))->Array.mapWithIndex((line, index) => <li key={Int.toString(index)}>{React.string(line)}</li>)->React.array}</ul></details>{closeCall(choiceA, choiceB) ? <p className="ta-warning" role="status">{React.string("Close call: small changes to an assumption could change which option scores higher.")}</p> : React.null}{dominant->((name, amount)) => name != "" && amount >= gap *. 0.75 && amount > 0. ? <p className="ta-warning" role="status">{React.string("This comparison relies heavily on the assumption about “" ++ name ++ "”. Consider how certain that estimate is.")}</p> : React.null}</section>
}

@react.component
let make = (~scenarios: array<scenario>, ~people: array<State.person>, ~onChange: array<scenario> => promise<bool>) => {
  let (draft, setDraft) = React.useState(_ => blankScenario())
  let (editing, setEditing) = React.useState(_ => false)
  let (step, setStep) = React.useState(_ => 0)
  let (selectedId, setSelectedId) = React.useState(_ => "")
  let (saveError, setSaveError) = React.useState(_ => "")
  let active = scenarios->Array.find(item => item.id == selectedId)
  let start = (item, isNew) => {setDraft(_ => item); setEditing(_ => true); setStep(_ => 0); setSaveError(_ => ""); if isNew {setSelectedId(_ => item.id)}}
  let persist = next => onChange(next)->Promise.then(saved => {
    setSaveError(_ => saved ? "" : "Could not save this scenario. Your draft is still here; try again.")
    Promise.resolve(saved)
  })
  let commit = () => {
    if canSave(draft) {
      let updated = {...draft, title: String.trim(draft.title), updatedAt: now(), choiceA: {...draft.choiceA, label: String.trim(draft.choiceA.label), consequences: draft.choiceA.consequences->Array.map(item => {...item, description: String.trim(item.description)})}, choiceB: {...draft.choiceB, label: String.trim(draft.choiceB.label), consequences: draft.choiceB.consequences->Array.map(item => {...item, description: String.trim(item.description)})}}
      persist(scenarios->Array.filter(item => item.id != updated.id)->Array.concat([updated]))
      ->Promise.then(saved => {if saved {setSelectedId(_ => updated.id); setEditing(_ => false)}; Promise.resolve(())})
      ->ignore
    }
  }
  let choiceCard = (isA, choice) => {
    let update = next => setDraft(current => updateChoice(current, isA, next))
    let consequences = choice.consequences
    <section className="ta-choice" ariaLabel={choice.label}>
      <h3>{React.string(choice.label)}</h3>
      <h4>{React.string("What could happen later?")}</h4><p className="ta-field-help">{React.string("Add distinct consequences. Avoid entering the same effect twice.")}</p>
      {consequences->Array.mapWithIndex((item, index) => <fieldset className="ta-consequence" key={item.id}>
        <legend>{React.string("Possible outcome " ++ Int.toString(index + 1))}</legend>
        <label>{React.string("Outcome")}<input value={item.description} maxLength=120 onChange={event => update({...choice, consequences: replaceAt(consequences, index, {...item, description: inputValue(event)})})} /></label>
        <div className="ta-assumptions"><label>{React.string("Likelihood")}{options(likelihoods, item.likelihood, value => update({...choice, consequences: replaceAt(consequences, index, {...item, likelihood: value})}))}</label><label>{React.string("How much would it matter?")}{utilityOptions(item.utility, value => update({...choice, consequences: replaceAt(consequences, index, {...item, utility: value})}))}</label></div>
        <label className="ta-check"><input type_="checkbox" checked={item.dependsOnPerson} onChange={event => update({...choice, consequences: replaceAt(consequences, index, {...item, dependsOnPerson: JsxEvent.Form.target(event)["checked"]})})} />{React.string(switch people->Array.find(person => person.id == draft.personId) { | Some(person) => "Does this outcome depend on what " ++ person.name ++ " does?" | None => "Does this outcome depend on another person's future choice?" })}</label>
        {item.dependsOnPerson ? <label>{React.string("If the moment actually came, would they have a real reason to do this?")}{options(credibilities, item.credibility, value => update({...choice, consequences: replaceAt(consequences, index, {...item, credibility: value})}))}</label> : React.null}
        <button type_="button" className="ta-text-button" onClick={_ => update({...choice, consequences: consequences->Array.filterWithIndex((_, i) => i != index)})}>{React.string("Remove outcome")}</button>
      </fieldset>)->React.array}
      <button type_="button" className="ta-secondary" onClick={_ => {let item = {id: Storage.randomUUID(), description: "", likelihood: "Possible", utility: 0, dependsOnPerson: false, credibility: "Probably yes"}; update({...choice, consequences: Array.concat(consequences, [item])})}}>{React.string("+ Add possible outcome")}</button>
    </section>
  }
  let (_, _, top) = result(draft.choiceA, draft.choiceB)
  <section className="think-ahead">
    <header className="ta-header"><p className="ta-eyebrow">{React.string("Think Ahead")}</p><h1>{React.string("Make room for what might happen.")}</h1><p>{React.string("Compare the immediate trade-offs and possible outcomes. Scores organize your assumptions; they do not decide for you.")}</p></header>
    {saveError != "" ? <p className="ta-warning" role="alert">{React.string(saveError)}</p> : React.null}
    {!editing ? <>
      <div className="ta-list-heading"><h2>{React.string("Your scenarios")}</h2><button type_="button" className="ta-primary" onClick={_ => start(blankScenario(), true)}>{React.string("+ New scenario")}</button></div>
      {Array.length(scenarios) == 0 ? <p className="ta-empty">{React.string("No scenarios yet. Start with a decision you are weighing.")}</p> : <ul className="ta-scenarios">{scenarios->Array.map(item => <li key={item.id}>
        <button type_="button" className="ta-open" onClick={_ => {setSelectedId(_ => item.id); setDraft(_ => item); setEditing(_ => false)}}><strong>{React.string(item.title == "" ? "Untitled scenario" : item.title)}</strong><span>{React.string(item.choiceA.label ++ " vs. " ++ item.choiceB.label)}</span></button>
        <button type_="button" ariaLabel={"Edit " ++ item.title} onClick={_ => start(item, false)}>{React.string("Edit")}</button>
        <button type_="button" ariaLabel={"Duplicate " ++ item.title} onClick={_ => {let copy = {...item, id: Storage.randomUUID(), title: item.title ++ " (copy)", createdAt: now(), updatedAt: now()}; persist(Array.concat(scenarios, [copy]))->ignore}}>{React.string("Duplicate")}</button>
        <button type_="button" ariaLabel={"Delete " ++ item.title} onClick={_ => {persist(scenarios->Array.filter(value => value.id != item.id))->Promise.then(saved => {if saved && selectedId == item.id {setSelectedId(_ => "")}; Promise.resolve(())})->ignore}}>{React.string("Delete")}</button>
      </li>)->React.array}</ul>}
      {switch active { | None => React.null | Some(item) => resultPanel(item.title, item.choiceA, item.choiceB)}}
    </> : <>
      <div className="ta-stepper" ariaLabel="Scenario steps">{["Choices", "Possible outcomes", "Compare" ]->Array.mapWithIndex((label, index) => step == index ? <button key={Int.toString(index)} type_="button" className="active" ariaCurrent=#step onClick={_ => setStep(_ => index)}>{React.string(Int.toString(index + 1) ++ ". " ++ label)}</button> : <button key={Int.toString(index)} type_="button" onClick={_ => setStep(_ => index)}>{React.string(Int.toString(index + 1) ++ ". " ++ label)}</button>)->React.array}</div>
      {step == 0 ? <section className="ta-panel"><label>{React.string("What decision are you considering?")}<input autoFocus=true value={draft.title} maxLength=100 placeholder="e.g. Take the new role" onChange={event => setDraft(current => {...current, title: inputValue(event)})} /></label><label>{React.string("Related person (optional)")}<select value={draft.personId} onChange={event => setDraft(current => {...current, personId: inputValue(event)})}><option value="">{React.string("No person selected")}</option>{people->Array.map(person => <option key={person.id} value={person.id}>{React.string(person.name)}</option>)->React.array}</select></label><div className="ta-choice-grid">{[true, false]->Array.map(isA => {let choice = isA ? draft.choiceA : draft.choiceB; <div key={isA ? "a" : "b"} className="ta-inline-choice"><label>{React.string(isA ? "Option A name" : "Option B name")}<input value={choice.label} maxLength=70 placeholder={isA ? "e.g. Stay in current role" : "e.g. Take the new role"} onChange={event => setDraft(current => updateChoice(current, isA, {...choice, label: inputValue(event)}))} /></label><label>{React.string("Immediate effect")}<span className="ta-field-help">{React.string("How good or bad is this right away?")}</span>{utilityOptions(choice.immediateUtility, value => setDraft(current => updateChoice(current, isA, {...choice, immediateUtility: value})))}</label></div>})->React.array}</div></section> : step == 1 ? <><div className="ta-choice-grid">{choiceCard(true, draft.choiceA)}{choiceCard(false, draft.choiceB)}</div><div className="ta-live-strip" ariaLive=#polite><strong>{React.string("Live scores")}</strong><span>{React.string(draft.choiceA.label ++ " " ++ formatScore(score(draft.choiceA)) ++ " · " ++ draft.choiceB.label ++ " " ++ formatScore(score(draft.choiceB)) ++ (closeCall(draft.choiceA, draft.choiceB) ? " · Close call" : " · Favors " ++ top))}</span></div></> : <><p className="ta-decision-note">{React.string("Scores organize your assumptions; they do not decide for you.")}</p>{resultPanel("Live comparison", draft.choiceA, draft.choiceB)}</>}
      <div className="ta-actions"><button type_="button" className="ta-secondary" onClick={_ => {setEditing(_ => false); setStep(_ => 0)}}>{React.string("Cancel")}</button>{step > 0 ? <button type_="button" className="ta-secondary" onClick={_ => setStep(current => current - 1)}>{React.string("Back")}</button> : React.null}{step < 2 ? <button type_="button" className="ta-primary" onClick={_ => setStep(current => current + 1)}>{React.string("Continue")}</button> : <button type_="button" className="ta-primary" disabled={!canSave(draft)} onClick={_ => commit()}>{React.string("Save scenario")}</button>}</div>
    </>}
  </section>
}
