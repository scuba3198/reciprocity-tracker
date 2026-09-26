type params = {value: float, cost: float, exploitation: float, relationship: float}
type decision = {move: option<State.move>, cooperateUtility: float, defectUtility: float, explanation: string}
@scope("Math") @val external round: float => int = "round"
@send external toFixed: (float, int) => string = "toFixed"

let defaults: params = {value: 3., cost: 3., exploitation: 3., relationship: 3.}
let percent = probability => Int.toString(round(probability *. 100.)) ++ "%"
let score = value => toFixed(value, 1)

// Illustrative subjective mapping only: CC rewards successful reciprocity by value and relationship, less cost.
// CD charges the cooperation cost and exploitation loss; DC gets half value for an unreciprocated outcome, less relationship cost.
// DD charges relationship cost. The half-value assumption is a simple heuristic, not an empirical estimate.
let utility = (parameters: params, mine: State.move, theirs: State.move) => switch (mine, theirs) {
| (State.Cooperate, State.Cooperate) => parameters.value +. parameters.relationship -. parameters.cost
| (State.Cooperate, State.Defect) => -. parameters.cost -. parameters.exploitation
| (State.Defect, State.Cooperate) => parameters.value /. 2. -. parameters.relationship
| (State.Defect, State.Defect) => -. parameters.relationship
}

let expectedUtility = (parameters, probabilityTheyCooperate, mine) =>
  probabilityTheyCooperate *. utility(parameters, mine, State.Cooperate) +. (1. -. probabilityTheyCooperate) *. utility(parameters, mine, State.Defect)

let decide = (parameters, pTheyCooperateGivenMyCooperate, pTheyCooperateGivenMyDefect): decision => {
  let cooperateUtility = expectedUtility(parameters, pTheyCooperateGivenMyCooperate, State.Cooperate)
  let defectUtility = expectedUtility(parameters, pTheyCooperateGivenMyDefect, State.Defect)
  let details = "With value " ++ score(parameters.value) ++ ", cooperation cost " ++ score(parameters.cost) ++ ", exploitation cost " ++ score(parameters.exploitation) ++ ", and relationship importance " ++ score(parameters.relationship) ++ ", they are estimated to cooperate " ++ percent(pTheyCooperateGivenMyCooperate) ++ " if you cooperate and " ++ percent(pTheyCooperateGivenMyDefect) ++ " if you withhold. Expected utilities are " ++ score(cooperateUtility) ++ " for Cooperate and " ++ score(defectUtility) ++ " for Withhold. "
  if cooperateUtility == defectUtility {
    {move: None, cooperateUtility, defectUtility, explanation: details ++ "They tie, so neither move has a clear advantage."}
  } else if cooperateUtility > defectUtility {
    {move: Some(State.Cooperate), cooperateUtility, defectUtility, explanation: details ++ "Cooperate has higher expected utility."}
  } else {
    {move: Some(State.Defect), cooperateUtility, defectUtility, explanation: details ++ "Withhold has higher expected utility."}
  }
}
