@val external stringify: 'a => string = "JSON.stringify"
@scope("crypto") @val external randomUUID: unit => string = "randomUUID"
@scope("localStorage") @val external getItem: string => Nullable.t<string> = "getItem"
@scope("localStorage") @val external setItem: (string, string) => unit = "setItem"
@module("./InteractionDate.js") external normalizeDate: string => Nullable.t<string> = "normalize"

let key = "good-faith.people.v2"

let field = (obj, name) => Dict.get(obj, name)
let stringField = (obj, name) => field(obj, name)->Option.flatMap(JSON.Decode.string)
let numberField = (obj, name) => field(obj, name)->Option.flatMap(JSON.Decode.float)
let moveField = (obj, name) => switch stringField(obj, name) {
| Some("Cooperate") => Some(State.Cooperate)
| Some("Defect") => Some(State.Defect)
| _ => None
}

let decodeEntry = json => switch JSON.Decode.object(json) {
| None => None
| Some(obj) => {
    let date = stringField(obj, "date")->Option.flatMap(value => value->normalizeDate->Nullable.toOption)
    switch (moveField(obj, "move"), moveField(obj, "myMove"), stringField(obj, "note"), date) {
  | (Some(move), Some(myMove), Some(note), Some(date)) => {
      let entry: State.entry = {move, myMove, note, date}
      Some(entry)
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

let load = (): array<State.person> => switch getItem(key)->Nullable.toOption {
| None => []
| Some(raw) => {
    try {
      switch raw->JSON.parseOrThrow->JSON.Decode.array {
      | Some(people) => people->Array.filterMap(decodePerson)
      | None => []
      }
    } catch {
    | _ => []
    }
  }
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
    }),
  })

let save = (people: array<State.person>) => setItem(key, stringify(encodePeople(people)))

let backup = (people: array<State.person>) => stringify({
  "format": "good-faith-backup",
  "version": 4,
  "people": encodePeople(people),
})

let parseBackup = (raw: string): result<array<State.person>, string> => {
  try {
    switch raw->JSON.parseOrThrow->JSON.Decode.object {
    | None => Error("That file is not a Good Faith backup.")
    | Some(obj) => switch (stringField(obj, "format"), numberField(obj, "version"), field(obj, "people")->Option.flatMap(JSON.Decode.array)) {
      | (Some("good-faith-backup"), Some(4.0), Some(items)) => {
          let people = items->Array.filterMap(decodePerson)
          // ponytail: quadratic duplicate check is fine for a personal ledger; use a set if backups become huge.
          let unique = people->Array.every(person => people->Array.filter(other => other.id == person.id)->Array.length == 1)
          if Array.length(people) == Array.length(items) && unique {
            Ok(people)
          } else {
            Error("This backup has invalid or duplicate people or interactions.")
          }
        }
      | _ => Error("Choose a Good Faith backup made by this app.")
      }
    }
  } catch {
  | _ => Error("That file is not valid JSON.")
  }
}
