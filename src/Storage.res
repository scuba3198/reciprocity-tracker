@val external stringify: 'a => string = "JSON.stringify"
@scope("crypto") @val external randomUUID: unit => string = "randomUUID"
@scope("localStorage") @val external getItem: string => Nullable.t<string> = "getItem"
@scope("localStorage") @val external setItem: (string, string) => unit = "setItem"
@module("./InteractionDate.js") external normalizeDate: string => Nullable.t<string> = "normalize"
@module("./LocalBackup.js") external decodeBackupJSON: string => option<(string, int, string)> = "decode"

let key = "good-faith.people.v2"
let toleranceKey = "good-faith.cure-tolerance"
let loadTolerance = () => try {
  switch getItem(toleranceKey)->Nullable.toOption {
  | Some("1") => 1
  | Some("3") => 3
  | _ => 2
  }
} catch {
| _ => 2
}
let saveTolerance = tolerance => try {
  setItem(toleranceKey, Int.toString(tolerance))
  true
} catch {
| _ => false
}

let field = (obj, name) => Dict.get(obj, name)
let stringField = (obj, name) => field(obj, name)->Option.flatMap(JSON.Decode.string)
let toleranceField = (obj, name) => switch field(obj, name) {
| Some(value) => switch JSON.Decode.float(value) { | Some(value) when value == 1.0 || value == 2.0 || value == 3.0 => Some(Int.fromFloat(value)) | _ => None }
| None => None
}
let unique = values => {
  let seen = ref([])
  let valid = ref(true)
  values->Array.forEach(value => {
    if seen.contents->Array.some(existing => existing == value) { valid.contents = false }
    seen.contents = [value, ...seen.contents]
  })
  valid.contents
}
let optionalDateField = (obj, name) => switch field(obj, name) {
| None => Some("")
| Some(value) => switch JSON.Decode.string(value) {
  | None => None
  | Some("") => Some("")
  | Some(value) => value->normalizeDate->Nullable.toOption
  }
}
let actionField = (obj, name) => switch stringField(obj, name) {
| Some("Cooperate") => Some(State.Cooperated)
| Some("Defect") => Some(State.Defected)
| Some("Request") => Some(State.Requested)
| Some("Unable") => Some(State.Unable)
| Some("NoAction") => Some(State.NoAction)
| _ => None
}
let decodeDraft = (json, id) => switch JSON.Decode.object(json) {
| None => None
| Some(obj) => switch (stringField(obj, "move"), stringField(obj, "myMove"), stringField(obj, "note"), stringField(obj, "date"), stringField(obj, "category"), stringField(obj, "myActionDate"), stringField(obj, "theirActionDate")) {
  | (Some(move), Some(myMove), Some(note), Some(date), Some(category), Some(myActionDate), Some(theirActionDate)) =>
          Some({id, move, myMove, note, date, category, myActionDate, theirActionDate}: State.draft)
  | _ => None
  }
}
let decodeIdentifiedDraft = json => switch JSON.Decode.object(json) {
| None => None
| Some(obj) => switch stringField(obj, "id") {
  | Some(id) if id->String.trim != "" => decodeDraft(json, id)
  | _ => None
  }
}

let decodeEntry = json => switch JSON.Decode.object(json) {
| None => None
| Some(obj) => {
    let date = stringField(obj, "date")->Option.flatMap(value => value->normalizeDate->Nullable.toOption)
    let myActionDate = optionalDateField(obj, "myActionDate")
    let theirActionDate = optionalDateField(obj, "theirActionDate")
    let category = switch field(obj, "category") {
    | None => Some("")
    | Some(value) => JSON.Decode.string(value)
    }
    switch (actionField(obj, "move"), actionField(obj, "myMove"), stringField(obj, "note"), date, category, myActionDate, theirActionDate) {
  | (Some(move), Some(myMove), Some(note), Some(date), Some(category), Some(myActionDate), Some(theirActionDate)) => {
      if !State.validChoices(State.choiceFromAction(myMove), State.choiceFromAction(move)) || (myActionDate != "" && myActionDate > date) || (theirActionDate != "" && theirActionDate > date) {
        None
      } else {
        let entry: State.entry = {move, myMove, note, date, category, myActionDate, theirActionDate}
        Some(entry)
      }
    }
  | _ => None
  }
  }
}

let decodeLedger = json => switch JSON.Decode.object(json) {
| None => None
| Some(obj) => switch (stringField(obj, "id"), stringField(obj, "name"), field(obj, "entries")->Option.flatMap(JSON.Decode.array)) {
  | (Some(id), Some(name), Some(entries)) => {
      let decoded = entries->Array.filterMap(decodeEntry)
      let rawDrafts = field(obj, "drafts")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let drafts = rawDrafts->Array.filterMap(decodeIdentifiedDraft)
      let validDrafts = switch field(obj, "drafts") {
      | None => true
      | Some(value) => JSON.Decode.array(value) != None
      }
      if id->String.trim == "" || name->String.trim == "" || Array.length(decoded) != Array.length(entries) ||
        !validDrafts || Array.length(drafts) != Array.length(rawDrafts) || !unique(drafts->Array.map(draft => draft.id)) { None }
      else { Some({id, name, entries: decoded, drafts, cureDeltaOverride: ?toleranceField(obj, "cureDeltaOverride")}: State.ledger) }
    }
  | _ => None
  }
}

let decodePerson = json => switch JSON.Decode.object(json) {
| None => None
| Some(obj) => switch (stringField(obj, "id"), stringField(obj, "name"), field(obj, "entries")->Option.flatMap(JSON.Decode.array)) {
  | (Some(id), Some(name), Some(entries)) => {
      let decoded = entries->Array.filterMap(decodeEntry)
      let drafts = switch field(obj, "drafts") {
      | Some(value) => value->JSON.Decode.array->Option.getOr([])->Array.filterMap(decodeIdentifiedDraft)
      | None => switch field(obj, "draft") {
        | None => []
        | Some(value) => switch JSON.Decode.object(value) {
          | Some(draftObj) if field(draftObj, "saved")->Option.flatMap(JSON.Decode.bool) == Some(false) => []
          | _ => switch decodeDraft(value, "legacy-" ++ id) { | Some(draft) => [draft] | None => [] }
          }
        }
      }
      let generalCureDeltaOverride = toleranceField(obj, "generalCureDeltaOverride")
      let cureDeltaOverride = toleranceField(obj, "cureDeltaOverride")
      let rawLedgers = field(obj, "ledgers")
      let ledgers = rawLedgers->Option.flatMap(JSON.Decode.array)->Option.map(values => values->Array.filterMap(decodeLedger))
      let validLedgers = switch rawLedgers {
      | None => true
      | Some(value) => switch (JSON.Decode.array(value), ledgers) {
        | (Some(raw), Some(decodedLedgers)) => Array.length(raw) == Array.length(decodedLedgers) && unique(decodedLedgers->Array.map(ledger => ledger.id))
        | _ => false
        }
      }
      if id->String.trim != "" && name->String.trim != "" && Array.length(decoded) == Array.length(entries) &&
        unique(drafts->Array.map(draft => draft.id)) && validLedgers {
        let person: State.person = {id, name, entries: decoded, drafts, cureDeltaOverride: ?cureDeltaOverride, generalCureDeltaOverride: ?generalCureDeltaOverride, ledgers: ?ledgers}
        Some(person)
      } else {
        None
      }
    }
  | _ => None
  }
}

let decodePeople = (raw: string): array<State.person> => {
  try {
    switch raw->JSON.parseOrThrow->JSON.Decode.array {
    | Some(people) => people->Array.filterMap(decodePerson)
    | None => []
    }
  } catch {
  | _ => []
  }
}

let decodeBackup = (raw: string) => switch decodeBackupJSON(raw) {
| Some((people, tolerance, scenarios)) => Some((decodePeople(people), tolerance, scenarios))
| None => None
}

let load = (): array<State.person> => switch getItem(key)->Nullable.toOption {
| None => []
| Some(raw) => decodePeople(raw)
}

let encodeEntry = (entry: State.entry) => {
  "move": State.choiceFromAction(entry.move), "myMove": State.choiceFromAction(entry.myMove), "note": entry.note,
  "date": entry.date, "category": entry.category, "myActionDate": entry.myActionDate, "theirActionDate": entry.theirActionDate,
}
let encodeDraft = (draft: State.draft) => {
  "id": draft.id, "move": draft.move, "myMove": draft.myMove, "note": draft.note, "date": draft.date,
  "category": draft.category, "myActionDate": draft.myActionDate, "theirActionDate": draft.theirActionDate,
}
let encodeLedger = (ledger: State.ledger) => {
  "id": ledger.id, "name": ledger.name, "entries": ledger.entries->Array.map(encodeEntry),
  "drafts": ledger.drafts->Array.map(encodeDraft), "cureDeltaOverride": ledger.cureDeltaOverride,
}

let encodePeople = (people: array<State.person>) =>
  people->Array.map(person => {
    "id": person.id,
    "name": person.name,
    "entries": person.entries->Array.map(encodeEntry),
    "drafts": person.drafts->Array.map(encodeDraft),
    "generalCureDeltaOverride": person.generalCureDeltaOverride,
    "cureDeltaOverride": person.cureDeltaOverride,
    "ledgers": person.ledgers->Option.map(ledgers => ledgers->Array.map(encodeLedger)),
  })

let serialize = (people: array<State.person>) => stringify(encodePeople(people))
let save = (people: array<State.person>) => setItem(key, serialize(people))
