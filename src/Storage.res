@val external stringify: 'a => string = "JSON.stringify"
@scope("crypto") @val external randomUUID: unit => string = "randomUUID"
@scope("localStorage") @val external getItem: string => Nullable.t<string> = "getItem"
@scope("localStorage") @val external setItem: (string, string) => unit = "setItem"
@module("./InteractionDate.js") external normalizeDate: string => Nullable.t<string> = "normalize"

let key = "good-faith.people.v2"

let field = (obj, name) => Dict.get(obj, name)
let stringField = (obj, name) => field(obj, name)->Option.flatMap(JSON.Decode.string)
let optionalDateField = (obj, name) => switch field(obj, name) {
| None => Some("")
| Some(value) => switch JSON.Decode.string(value) {
  | None => None
  | Some("") => Some("")
  | Some(value) => value->normalizeDate->Nullable.toOption
  }
}
let moveField = (obj, name) => switch stringField(obj, name) {
| Some("Cooperate") => Some(State.Cooperate)
| Some("Defect") => Some(State.Defect)
| _ => None
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
    switch (moveField(obj, "move"), moveField(obj, "myMove"), stringField(obj, "note"), date, category, myActionDate, theirActionDate) {
  | (Some(move), Some(myMove), Some(note), Some(date), Some(category), Some(myActionDate), Some(theirActionDate)) => {
      if (myActionDate != "" && myActionDate > date) || (theirActionDate != "" && theirActionDate > date) {
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

let decodePerson = json => switch JSON.Decode.object(json) {
| None => None
| Some(obj) => switch (stringField(obj, "id"), stringField(obj, "name"), field(obj, "entries")->Option.flatMap(JSON.Decode.array)) {
  | (Some(id), Some(name), Some(entries)) => {
      let decoded = entries->Array.filterMap(decodeEntry)
      if id->String.trim != "" && name->String.trim != "" && Array.length(decoded) == Array.length(entries) {
        let person: State.person = {id, name, entries: decoded}
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

let load = (): array<State.person> => switch getItem(key)->Nullable.toOption {
| None => []
| Some(raw) => decodePeople(raw)
}

let encodePeople = (people: array<State.person>) =>
  people->Array.map(person => {
    "id": person.id,
    "name": person.name,
    "entries": person.entries->Array.map(entry => {
      "move": switch entry.move { | State.Cooperate => "Cooperate" | State.Defect => "Defect" },
      "myMove": switch entry.myMove { | State.Cooperate => "Cooperate" | State.Defect => "Defect" },
      "note": entry.note,
      "date": entry.date,
      "category": entry.category,
      "myActionDate": entry.myActionDate,
      "theirActionDate": entry.theirActionDate,
    }),
  })

let serialize = (people: array<State.person>) => stringify(encodePeople(people))
let save = (people: array<State.person>) => setItem(key, serialize(people))
