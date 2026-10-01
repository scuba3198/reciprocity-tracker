type calendarDay = {date: string, label: string, accessible: string, disabled: bool}
type calendarView = {title: string, days: array<calendarDay>, previous: string, next: string, previousDisabled: bool, nextDisabled: bool}
type destination = Home | Ledger | Insights | Think | Settings | Info | Add | CreatePerson(string) | Person(string)
@module("./Supabase.js") external auth: (string, string, string) => promise<string> = "auth"
@module("./Supabase.js") external subscribeAuth: ((string, string, string) => unit) => (unit => unit) = "subscribe"
type cloudLedger = {people: string, scenarios: string, scenariosReady: bool, tolerance: int}
@module("./Supabase.js") external loadOrMigrate: (string, string, int, string) => promise<cloudLedger> = "loadOrMigrate"
@module("./Supabase.js") external saveCloud: (string, string) => promise<string> = "save"
@module("./Supabase.js") external saveCloudScenarios: (string, string) => promise<string> = "saveScenarios"
@module("./Supabase.js") external saveCloudTolerance: (string, int) => promise<unit> = "saveTolerance"
@module("./LocalBackup.js") external downloadBackup: (string, int, string) => unit = "download"
@module("./ThinkAheadStorage.js") external loadScenarios: unit => array<ThinkAhead.scenario> = "load"
@module("./ThinkAheadStorage.js") external saveScenariosLocal: array<ThinkAhead.scenario> => unit = "save"
@module("./ThinkAheadStorage.js") external decodeScenarios: string => array<ThinkAhead.scenario> = "decode"
@module("./ThinkAheadStorage.js") external serializeScenarios: array<ThinkAhead.scenario> => string = "serialize"
@module("./LocalBackup.js") external readBackupFile: 'a => promise<string> = "readFile"
@module("./InteractionDate.js") external today: unit => string = "today"
@module("./InteractionDate.js") external yesterday: unit => string = "yesterday"
@module("./InteractionDate.js") external normalizeDate: string => Nullable.t<string> = "normalize"
@module("./InteractionDate.js") external displayDate: string => string = "displayDate"
@module("./InteractionDate.js") external getCalendarMonth: string => calendarView = "calendarMonth"
@module("./Theme.js") external loadTheme: unit => string = "load"
@module("./Theme.js") external applyTheme: string => unit = "apply"
@scope("window") @val external scrollTo: (int, int) => unit = "scrollTo"
@send external sortPeople: (array<State.person>, (State.person, State.person) => float) => array<State.person> = "sort"

let moveClass = move => switch move { | State.Cooperate => "cooperate" | State.Defect => "defect" }
let nextLabel = move => switch move { | State.Cooperate => "Cooperate" | State.Defect => "Withhold cooperation" }
let decisionClass = (decision: State.decision) => moveClass(decision.move)
let decisionLabel = (decision: State.decision) => nextLabel(decision.move)
let navIcon = kind => {
  let shape = switch kind {
  | "people" => "M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8a4 4 0 0 0 0 8M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"
  | "ledger" => "M5 3h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2ZM7 8h10M7 12h10M7 16h7"
  | "insights" => "M4 20V11M10 20V5M16 20v-8M22 20V8M2 20h20"
  | "think" => "M12 3a7 7 0 0 0-4 12v3h8v-3a7 7 0 0 0-4-12ZM9 21h6M9 15h6"
  | _ => "M10 2h4l.6 2.2 1.5.9 2.2-.6 2 3.5-1.6 1.6v1.8l1.6 1.6-2 3.5-2.2-.6-1.5.9L14 20h-4l-.6-2.2-1.5-.9-2.2.6-2-3.5 1.6-1.6v-1.8L3.7 9l2-3.5 2.2.6 1.5-.9L10 2zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6"
  }
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" ariaHidden=true><path d={shape} /></svg>
}

@react.component
let make = () => {
  let (people, setPeople) = React.useState(_ => [])
  let (selectedId, setSelectedId) = React.useState(_ => "")
  let (selectedLedgerId, setSelectedLedgerId) = React.useState(_ => "")
  let (ledgerDeleteOpen, setLedgerDeleteOpen) = React.useState(_ => false)
  let (newLedgerName, setNewLedgerName) = React.useState(_ => "")
  let (newLedgerTolerance, setNewLedgerTolerance) = React.useState(_ => "")
  let (newName, setNewName) = React.useState(_ => "")
  let (note, setNote) = React.useState(_ => "")
  let (category, setCategory) = React.useState(_ => "")
  let (categoryOpen, setCategoryOpen) = React.useState(_ => false)
  let (myMove, setMyMove) = React.useState(_ => "")
  let (theirMove, setTheirMove) = React.useState(_ => "")
  let (currentDraftId, setCurrentDraftId) = React.useState(_ => Storage.randomUUID())
  let (interactionDate, setInteractionDate) = React.useState(_ => "")
  let (myActionDate, setMyActionDate) = React.useState(_ => "")
  let (theirActionDate, setTheirActionDate) = React.useState(_ => "")
  let (actionDatesOpen, setActionDatesOpen) = React.useState(_ => false)
  let (actionDateError, setActionDateError) = React.useState(_ => "")
  let (calendarTarget, setCalendarTarget) = React.useState(_ => "")
  let (monthKey, setMonthKey) = React.useState(_ => today()->String.slice(~start=0, ~end=7))
  let (dateError, setDateError) = React.useState(_ => "")
  let (deleteTargetId, setDeleteTargetId) = React.useState(_ => "")
  let (editTargetId, setEditTargetId) = React.useState(_ => "")
  let (editName, setEditName) = React.useState(_ => "")
  let (editingEntryIndex, setEditingEntryIndex) = React.useState(_ => -1)
  let (editMyMove, setEditMyMove) = React.useState(_ => "")
  let (editTheirMove, setEditTheirMove) = React.useState(_ => "")
  let (editDate, setEditDate) = React.useState(_ => "")
  let (editMyActionDate, setEditMyActionDate) = React.useState(_ => "")
  let (editTheirActionDate, setEditTheirActionDate) = React.useState(_ => "")
  let (editNote, setEditNote) = React.useState(_ => "")
  let (editCategory, setEditCategory) = React.useState(_ => "")
  let (entryEditError, setEntryEditError) = React.useState(_ => "")
  let (userId, setUserId) = React.useState(_ => "")
  let (email, setEmail) = React.useState(_ => "")
  let (password, setPassword) = React.useState(_ => "")
  let (authReady, setAuthReady) = React.useState(_ => false)
  let (cloudReady, setCloudReady) = React.useState(_ => false)
  let (authBusy, setAuthBusy) = React.useState(_ => false)
  let (authError, setAuthError) = React.useState(_ => "")
  let (authMessage, setAuthMessage) = React.useState(_ => "")
  let (passwordRecovery, setPasswordRecovery) = React.useState(_ => false)
  let (syncError, setSyncError) = React.useState(_ => "")
  let (syncing, setSyncing) = React.useState(_ => false)
  let (showInfo, setShowInfo) = React.useState(_ => false)
  let (returnView, setReturnView) = React.useState(_ => "home")
  let (showDashboard, setShowDashboard) = React.useState(_ => true)
  let (showInsights, setShowInsights) = React.useState(_ => false)
  let (showThinkAhead, setShowThinkAhead) = React.useState(_ => false)
  let (thinkAheadDraft, setThinkAheadDraft) = React.useState(_ => None)
  let (thinkAheadSession, setThinkAheadSession) = React.useState(_ => 0)
  let (thinkAheadDirty, setThinkAheadDirty) = React.useState(_ => false)
  let (pendingDestination, setPendingDestination) = React.useState(_ => None)
  let (showSettings, setShowSettings) = React.useState(_ => false)
  let (addOpen, setAddOpen) = React.useState(_ => false)
  let (sidebarCollapsed, setSidebarCollapsed) = React.useState(_ => false)
  let (searchQuery, setSearchQuery) = React.useState(_ => "")
  let (theme, setTheme) = React.useState(loadTheme)
  let (tolerance, setTolerance) = React.useState(Storage.loadTolerance)
  let (scenarios, setScenarios) = React.useState(loadScenarios)
  let (scenariosReady, setScenariosReady) = React.useState(_ => true)
  let (toleranceBusy, setToleranceBusy) = React.useState(_ => false)
  let (toleranceError, setToleranceError) = React.useState(_ => "")
  let (backupPeople, setBackupPeople) = React.useState(_ => [])
  let (backupTolerance, setBackupTolerance) = React.useState(_ => 2)
  let (backupScenarios, setBackupScenarios) = React.useState(_ => [])
  let (backupPreview, setBackupPreview) = React.useState(_ => false)
  let (backupError, setBackupError) = React.useState(_ => "")
  let (backupMessage, setBackupMessage) = React.useState(_ => "")
  let (backupSaving, setBackupSaving) = React.useState(_ => false)
  let currentAccount = React.useRef("")
  let accountGeneration = React.useRef(0)
  let backupReadToken = React.useRef(0)

  React.useEffect0(() => {
    let unsubscribe = subscribeAuth((id, accountEmail, event) => {
      if currentAccount.current != id {
        accountGeneration.current = accountGeneration.current + 1
        backupReadToken.current = backupReadToken.current + 1
        setBackupPeople(_ => [])
        setBackupScenarios(_ => [])
        setBackupPreview(_ => false)
        setBackupError(_ => "")
        setBackupMessage(_ => "")
        setBackupSaving(_ => false)
      }
      currentAccount.current = id
      if event == "PASSWORD_RECOVERY" {setPasswordRecovery(_ => true); setPassword(_ => "")}
      if event == "SIGNED_OUT" {setPasswordRecovery(_ => false)}
      setAuthReady(_ => true)
      setUserId(_ => id)
      setEmail(_ => accountEmail)
      setAuthError(_ => "")
      setPeople(_ => [])
      setScenarios(_ => [])
      setSelectedId(_ => "")
      setLedgerDeleteOpen(_ => false)
      setEditingEntryIndex(_ => -1)
      setEntryEditError(_ => "")
      setToleranceBusy(_ => false)
      setToleranceError(_ => "")
      if id == "" {
        setPeople(_ => Storage.load())
        setScenarios(_ => loadScenarios())
        setScenariosReady(_ => true)
        setTolerance(_ => Storage.loadTolerance())
        setCloudReady(_ => true)
        setSyncError(_ => "")
      } else {
        setCloudReady(_ => false)
        loadOrMigrate(id, Storage.serialize(Storage.load()), Storage.loadTolerance(), serializeScenarios(loadScenarios()))
        ->Promise.then(ledger => {
          if currentAccount.current == id {
            setPeople(_ => Storage.decodePeople(ledger.people))
            setScenarios(_ => decodeScenarios(ledger.scenarios))
            setScenariosReady(_ => ledger.scenariosReady)
            setTolerance(_ => ledger.tolerance)
            setCloudReady(_ => true)
          }
          Promise.resolve(())
        })
        ->Promise.catch(_error => {
          if currentAccount.current == id {setSyncError(_ => "Could not load your account settings or cloud ledger. Retry to continue.")}
          Promise.resolve(())
        })
        ->ignore
      }
    })
    Some(() => unsubscribe())
  })

  let commit = next => {
    if !cloudReady {
      Promise.resolve(false)
    } else {
      let accountId = userId
      if userId == "" {
        try {
          Storage.save(next)
          setPeople(_ => next)
          Promise.resolve(true)
        } catch {
        | _ => Promise.resolve(false)
        }
      } else {
        setSyncing(_ => true)
        setPeople(_ => next)
        saveCloud(userId, Storage.serialize(next))
        ->Promise.then(result => {
          if currentAccount.current == accountId {
            setSyncing(_ => false)
            setSyncError(_ => result == "saved" ? "" : "Cloud sync failed. Your changes remain on this screen; retry when online.")
          }
          Promise.resolve(result == "saved")
        })
        ->Promise.catch(_ => {
          if currentAccount.current == accountId {setSyncing(_ => false); setSyncError(_ => "Cloud sync failed. Your changes remain on this screen; retry when online.")}
          Promise.resolve(false)
        })
      }
    }
  }

  let commitScenarios = next => {
    if !cloudReady || !scenariosReady {
      Promise.resolve(false)
    } else {
      let accountId = userId
      if userId == "" {
        try {saveScenariosLocal(next); setScenarios(_ => next); Promise.resolve(true)} catch { | _ => setSyncError(_ => "Could not save Think Ahead in this browser."); Promise.resolve(false) }
      } else {
        setSyncing(_ => true)
        saveCloudScenarios(userId, serializeScenarios(next))
        ->Promise.then(result => {
          if currentAccount.current == accountId {
            if result == "saved" {setScenarios(_ => next)}
            setSyncing(_ => false)
            setSyncError(_ => result == "saved" ? "" : "Think Ahead could not sync. Retry when online.")
          }
          Promise.resolve(result == "saved")
        })
      }
    }
  }

  let retrySync = () => {
    if userId == "" || !cloudReady {
      setCloudReady(_ => false)
      loadOrMigrate(userId, Storage.serialize(Storage.load()), Storage.loadTolerance(), serializeScenarios(loadScenarios()))
      ->Promise.then(ledger => {if currentAccount.current == userId {setPeople(_ => Storage.decodePeople(ledger.people)); setScenarios(_ => decodeScenarios(ledger.scenarios)); setScenariosReady(_ => ledger.scenariosReady); setTolerance(_ => ledger.tolerance); setCloudReady(_ => true); setSyncError(_ => "")}; Promise.resolve(())})
      ->Promise.catch(_error => {if currentAccount.current == userId {setSyncError(_ => "Could not load your account settings or cloud ledger. Retry to continue.")}; Promise.resolve(())})
      ->ignore
    } else {
      setSyncing(_ => true)
      saveCloud(userId, Storage.serialize(people))
      ->Promise.then(ledgerResult => (scenariosReady ? saveCloudScenarios(userId, serializeScenarios(scenarios)) : Promise.resolve("saved"))->Promise.then(scenarioResult => {
        if currentAccount.current == userId {
          setSyncing(_ => false)
          setSyncError(_ => ledgerResult == "saved" && scenarioResult == "saved" ? "" : "Cloud sync failed. Your changes remain on this screen; retry when online.")
        }
        Promise.resolve(())
      }))
      ->ignore
    }
  }

  let runAuth = (action: string) => {
    if (action == "signup" || action == "update-password") && String.length(password) < 8 {
      setAuthError(_ => "Enter a password with at least 8 characters.")
    } else if (action == "signup" || action == "signin" || action == "reset") && email->String.trim == "" {
      setAuthError(_ => "Enter your email address first.")
    } else {
      setAuthBusy(_ => true)
      setAuthError(_ => "")
      setAuthMessage(_ => "")
      auth(action, email->String.trim, password)
      ->Promise.then(message => {
        setAuthMessage(_ => message)
        setPassword(_ => "")
        if action == "update-password" {setPasswordRecovery(_ => false)}
        setAuthBusy(_ => false)
        Promise.resolve(())
      })
      ->Promise.catch(error => {
        let message = switch error->JsExn.fromException->Option.flatMap(JsExn.message) {
        | Some(message) => message
        | None => "Account request failed. Please try again."
        }
        setAuthError(_ => message == "User already registered"
          ? "This email already has an account. Sign in with its password."
          : message)
        setAuthBusy(_ => false)
        Promise.resolve(())
      })
      ->ignore
    }
  }

  let selected = Belt.Array.getBy(people, person => person.id == selectedId)
  let commitLedger = (person: State.person, change) => commit(people->Array.map(item => item.id == person.id ? State.updateLedger(item, selectedLedgerId, change) : item))
  let saveOverride = next => {
    setToleranceError(_ => "")
    commit(next)->Promise.then(saved => {if !saved {setToleranceError(_ => "Could not save CURE tolerance. Retry when ready.")}; Promise.resolve(())})->ignore
  }
  let toleranceOptions = () => [1, 2, 3]->Array.map(choice => <option key={Int.toString(choice)} value={Int.toString(choice)}>{React.string(State.toleranceLabel(choice))}</option>)->React.array
  let calendar = getCalendarMonth(monthKey)

  let openCalendar = (target, value) => {
    let date = switch value->normalizeDate->Nullable.toOption {
    | Some(date) => date
    | None => switch interactionDate->normalizeDate->Nullable.toOption {
      | Some(date) => date
      | None => today()
      }
    }
    setMonthKey(_ => date->String.slice(~start=0, ~end=7))
    setCalendarTarget(_ => target)
  }
  let calendarPanel = (target, selectedDate, label) => {
    if calendarTarget == target {
      <section className="calendar-panel" ariaLabel={label}>
        <div className="calendar-head">
          <button type_="button" ariaLabel="Previous month" disabled={calendar.previousDisabled} onClick={_ => setMonthKey(_ => calendar.previous)}>{React.string("‹")}</button>
          <strong>{React.string(calendar.title)}</strong>
          <button type_="button" ariaLabel="Next month" disabled={calendar.nextDisabled} onClick={_ => setMonthKey(_ => calendar.next)}>{React.string("›")}</button>
        </div>
        <div className="calendar-grid">
          {["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]->Array.map(day => <span key={day} className="calendar-weekday">{React.string(day)}</span>)->React.array}
          {calendar.days->Array.mapWithIndex((day, index) => day.date == ""
            ? <span key={Int.toString(index)} ariaHidden=true></span>
            : <button key={day.date} type_="button" className={selectedDate == day.date ? "calendar-day selected" : "calendar-day"} ariaLabel={day.accessible} ariaPressed={selectedDate == day.date ? #"true" : #"false"} disabled={day.disabled} onClick={_ => {
                switch target {
                | "my" => setMyActionDate(_ => day.date)
                | "their" => setTheirActionDate(_ => day.date)
                | _ => setInteractionDate(_ => day.date)
                }
                setCalendarTarget(_ => "")
                setDateError(_ => "")
                setActionDateError(_ => "")
              }}>{React.string(day.label)}</button>)->React.array}
        </div>
      </section>
    } else {
      React.null
    }
  }
  let chooseTheme = choice => {
    applyTheme(choice)
    setTheme(_ => choice)
  }
  let chooseTolerance = choice => {
    setToleranceError(_ => "")
    if userId == "" {
      let saved = Storage.saveTolerance(choice)
      if saved {setTolerance(_ => choice)}
      else {setToleranceError(_ => "Could not save tolerance on this device. Try again.")}
      Promise.resolve(saved)
    } else {
      let accountId = userId
      setToleranceBusy(_ => true)
      saveCloudTolerance(userId, choice)
      ->Promise.then(_ => {if currentAccount.current == accountId {setTolerance(_ => choice); setToleranceBusy(_ => false)}; Promise.resolve(true)})
      ->Promise.catch(_ => {if currentAccount.current == accountId {setToleranceError(_ => "Could not save tolerance to your account. Try again."); setToleranceBusy(_ => false)}; Promise.resolve(false)})
    }
  }

  let readBackup = event => {
    backupReadToken.current = backupReadToken.current + 1
    let requestToken = backupReadToken.current
    let accountToken = accountGeneration.current
    setBackupPreview(_ => false)
    setBackupError(_ => "")
    setBackupMessage(_ => "")
    readBackupFile(JsxEvent.Form.target(event))
    ->Promise.then(raw => {
      if backupReadToken.current == requestToken && accountGeneration.current == accountToken && raw != "" {
        switch Storage.decodeBackup(raw) {
        | Some((restoredPeople, restoredTolerance, restoredScenarios)) => {
            setBackupPeople(_ => restoredPeople)
            setBackupTolerance(_ => restoredTolerance)
            setBackupScenarios(_ => decodeScenarios(restoredScenarios))
            setBackupPreview(_ => true)
          }
        | None => setBackupError(_ => "That file is not a complete, valid Reciprocity Tracker backup.")
        }
      }
      Promise.resolve(())
    })
    ->Promise.catch(_ => {
      if backupReadToken.current == requestToken && accountGeneration.current == accountToken {setBackupError(_ => "Could not read that backup file.")}
      Promise.resolve(())
    })
    ->ignore
  }

  let restoreBackup = () => {
    setBackupError(_ => "")
    setBackupMessage(_ => "")
    setBackupSaving(_ => true)
    let accountId = userId
    let generation = accountGeneration.current
    commit(backupPeople)
    ->Promise.then(peopleSaved => {
      if !peopleSaved {
        if currentAccount.current == accountId && accountGeneration.current == generation {setBackupError(_ => "Could not save the restored ledger. Retry when ready."); setBackupSaving(_ => false)}
        Promise.resolve(())
      } else if currentAccount.current != accountId || accountGeneration.current != generation {
        Promise.resolve(())
      } else {
        chooseTolerance(backupTolerance)
        ->Promise.then(toleranceSaved => (scenariosReady ? commitScenarios(backupScenarios) : Promise.resolve(Array.length(backupScenarios) == 0))->Promise.then(scenariosSaved => {
          if currentAccount.current == accountId && accountGeneration.current == generation {
            setBackupSaving(_ => false)
            if toleranceSaved && scenariosSaved {setBackupPreview(_ => false); setBackupMessage(_ => "Backup restored.")}
            else {setBackupError(_ => "Could not finish restoring all backup data. Retry when ready.")}
          }
          Promise.resolve(())
        }))
      }
    })
    ->ignore
  }

  let openHome = () => {
    setShowDashboard(_ => true)
    setShowInsights(_ => false)
    setShowThinkAhead(_ => false)
    setShowSettings(_ => false)
    setShowInfo(_ => false)
    scrollTo(0, 0)
  }
  let showLedger = () => {
    setShowDashboard(_ => false)
    setShowInsights(_ => false)
    setShowThinkAhead(_ => false)
    setShowSettings(_ => false)
    setShowInfo(_ => false)
    scrollTo(0, 0)
  }
  let openLedger = () => {
    setSelectedId(_ => "")
    showLedger()
  }
  let openInsights = () => {
    setShowDashboard(_ => false)
    setShowInsights(_ => true)
    setShowThinkAhead(_ => false)
    setShowSettings(_ => false)
    setShowInfo(_ => false)
    scrollTo(0, 0)
  }
  let openThinkAhead = () => {
    setThinkAheadDraft(_ => None)
    setThinkAheadSession(current => current + 1)
    setThinkAheadDirty(_ => false)
    setShowDashboard(_ => false)
    setShowInsights(_ => false)
    setShowThinkAhead(_ => true)
    setShowSettings(_ => false)
    setShowInfo(_ => false)
    setAddOpen(_ => false)
    scrollTo(0, 0)
  }
  let thinkThrough = (person: State.person, move: State.move) => {
    setThinkAheadDraft(_ => Some(ThinkAhead.prefillScenario(person, move)))
    setThinkAheadSession(current => current + 1)
    setThinkAheadDirty(_ => false)
    setShowDashboard(_ => false)
    setShowInsights(_ => false)
    setShowThinkAhead(_ => true)
    setShowSettings(_ => false)
    setShowInfo(_ => false)
    setAddOpen(_ => false)
    scrollTo(0, 0)
  }
  let openSettings = () => {
    setShowDashboard(_ => false)
    setShowInsights(_ => false)
    setShowThinkAhead(_ => false)
    setShowSettings(_ => true)
    setShowInfo(_ => false)
    setAddOpen(_ => false)
    scrollTo(0, 0)
  }
  let openInfo = () => {
    setReturnView(_ => showSettings ? "settings" : showDashboard ? "home" : showInsights ? "insights" : showThinkAhead ? "think-ahead" : "ledger")
    setShowInfo(_ => true)
    setShowDashboard(_ => false)
    setShowInsights(_ => false)
    setShowThinkAhead(_ => false)
    setShowSettings(_ => false)
    setCalendarTarget(_ => "")
    scrollTo(0, 0)
  }
  let leaveInfo = () => switch returnView {
  | "ledger" => showLedger()
  | "insights" => openInsights()
  | "think-ahead" => openThinkAhead()
  | "settings" => openSettings()
  | _ => openHome()
  }
  let startNewDraft = () => {
    setCurrentDraftId(_ => Storage.randomUUID())
    setInteractionDate(_ => "")
    setMyMove(_ => "")
    setTheirMove(_ => "")
    setNote(_ => "")
    setCategory(_ => "")
    setMyActionDate(_ => "")
    setTheirActionDate(_ => "")
    setActionDatesOpen(_ => false)
    setDateError(_ => "")
    setActionDateError(_ => "")
  }

  let loadDraft = (draft: State.draft) => {
    setCurrentDraftId(_ => draft.id)
    setInteractionDate(_ => draft.date)
    setMyMove(_ => draft.myMove)
    setTheirMove(_ => draft.move)
    setNote(_ => draft.note)
    setCategory(_ => draft.category)
    setMyActionDate(_ => draft.myActionDate)
    setTheirActionDate(_ => draft.theirActionDate)
    setActionDatesOpen(_ => draft.myActionDate != "" || draft.theirActionDate != "")
    setDateError(_ => "")
    setActionDateError(_ => "")
  }

  let openPerson = (person: State.person) => {
    setSelectedLedgerId(_ => "")
    setLedgerDeleteOpen(_ => false)
    setEditingEntryIndex(_ => -1)
    setEntryEditError(_ => "")
    setSelectedId(_ => person.id)
    setDeleteTargetId(_ => "")
    setEditTargetId(_ => "")
    switch person.drafts->Array.get(0) {
    | Some(draft) => loadDraft(draft)
    | None => startNewDraft()
    }
    setActionDateError(_ => "")
    setCategoryOpen(_ => false)
    setCalendarTarget(_ => "")
    setDateError(_ => "")
    showLedger()
  }

  let createPerson = name => {
    setSelectedLedgerId(_ => "")
    setLedgerDeleteOpen(_ => false)
    let person: State.person = {id: Storage.randomUUID(), name, entries: [], drafts: []}
    commit(Array.concat(people, [person]))->ignore
    setSelectedId(_ => person.id)
    setShowInfo(_ => false)
    setShowDashboard(_ => false)
    setShowInsights(_ => false)
    setShowThinkAhead(_ => false)
    setShowSettings(_ => false)
    setAddOpen(_ => false)
    setNewName(_ => "")
    setCurrentDraftId(_ => Storage.randomUUID())
    setEditingEntryIndex(_ => -1)
    setEntryEditError(_ => "")
    setInteractionDate(_ => "")
    setMyMove(_ => "")
    setTheirMove(_ => "")
    setNote(_ => "")
    setMyActionDate(_ => "")
    setTheirActionDate(_ => "")
    setActionDatesOpen(_ => false)
    setActionDateError(_ => "")
    setCategory(_ => "")
    setCategoryOpen(_ => false)
  }
  let goTo = destination => switch destination {
  | Home => openHome()
  | Ledger => openLedger()
  | Insights => openInsights()
  | Think => openThinkAhead()
  | Settings => openSettings()
  | Info => openInfo()
  | Add => {
      setAddOpen(_ => true)
      setShowSettings(_ => false)
      setShowInfo(_ => false)
      setShowDashboard(_ => false)
      setShowInsights(_ => false)
      setShowThinkAhead(_ => false)
      scrollTo(0, 0)
    }
  | CreatePerson(name) => createPerson(name)
  | Person(id) => switch people->Array.find(person => person.id == id) { | Some(person) => openPerson(person) | None => () }
  }
  let navigate = destination => {
    if showThinkAhead && thinkAheadDirty {
      setPendingDestination(_ => Some(destination))
    } else {
      goTo(destination)
    }
  }

  let addPerson = event => {
    ReactEvent.Form.preventDefault(event)
    let name = newName->String.trim
    if name != "" {
      navigate(CreatePerson(name))
    }
  }

  let saveDraft = (person: State.person) => {
    let draft: State.draft = {
      id: currentDraftId,
      move: theirMove,
      myMove,
      note, date: interactionDate, category, myActionDate, theirActionDate,
    }
    commitLedger(person, item => {
        let exists = item.drafts->Array.some(existing => existing.id == draft.id)
        let drafts = item.drafts->Array.map(existing => existing.id == draft.id ? draft : existing)
        {...item, drafts: exists ? drafts : Array.concat(drafts, [draft])}
    })->ignore
    setDateError(_ => "")
    setActionDateError(_ => "")
  }

  let discardDraft = (person: State.person) => {
    commitLedger(person, item => {...item, drafts: item.drafts->Array.filter(draft => draft.id != currentDraftId)})->ignore
    startNewDraft()
  }

  let confirmRound = (person: State.person) => {
    if !State.validChoices(myMove, theirMove) {
      setDateError(_ => "Choose a role for each person. Record at least one Cooperated or Defected action, or a Requested/Unable pair.")
    } else {switch (State.actionFromChoice(myMove), State.actionFromChoice(theirMove), interactionDate->normalizeDate->Nullable.toOption) {
    | (_, _, None) => setDateError(_ => "Enter a real date as YYYY-MM-DD or eight digits.")
    | (Some(mine), Some(theirs), Some(date)) => {
        let myInput = myActionDate->String.trim
        let theirInput = theirActionDate->String.trim
        let mineDate = myInput == "" ? Some("") : myInput->normalizeDate->Nullable.toOption
        let theirsDate = theirInput == "" ? Some("") : theirInput->normalizeDate->Nullable.toOption
        switch (mineDate, theirsDate) {
        | (Some(myActionDate), Some(theirActionDate)) if (myActionDate == "" || myActionDate <= date) && (theirActionDate == "" || theirActionDate <= date) => {
            let entry: State.entry = {move: theirs, myMove: mine, note: note->String.trim, category, date, myActionDate, theirActionDate}
            commitLedger(person, item => {...item, entries: Array.concat(item.entries, [entry]), drafts: item.drafts->Array.filter(draft => draft.id != currentDraftId)})->ignore
            startNewDraft()
            setCategoryOpen(_ => false)
            setActionDateError(_ => "")
            setCalendarTarget(_ => "")
            setDateError(_ => "")
          }
        | _ => {
            setActionDatesOpen(_ => true)
            setActionDateError(_ => "Enter real action dates no later than the round completion date.")
          }
        }
      }
    | _ => setDateError(_ => "Choose an action for each person.")
    }}
  }

  let startEditEntry = (index, entry: State.entry) => {
    setEditingEntryIndex(_ => index)
    setEditMyMove(_ => State.choiceFromAction(entry.myMove))
    setEditTheirMove(_ => State.choiceFromAction(entry.move))
    setEditDate(_ => entry.date)
    setEditMyActionDate(_ => entry.myActionDate)
    setEditTheirActionDate(_ => entry.theirActionDate)
    setEditNote(_ => entry.note)
    setEditCategory(_ => entry.category)
    setEntryEditError(_ => "")
  }

  let saveEntryEdit = (person: State.person) => {
    if !State.validChoices(editMyMove, editTheirMove) {
      setEntryEditError(_ => "Choose a role for each person. Record at least one Cooperated or Defected action, or a Requested/Unable pair.")
    } else {switch (State.actionFromChoice(editMyMove), State.actionFromChoice(editTheirMove), editDate->normalizeDate->Nullable.toOption) {
    | (Some(myMove), Some(move), Some(date)) => {
        let myInput = editMyActionDate->String.trim
        let theirInput = editTheirActionDate->String.trim
        let mineDate = myInput == "" ? Some("") : myInput->normalizeDate->Nullable.toOption
        let theirsDate = theirInput == "" ? Some("") : theirInput->normalizeDate->Nullable.toOption
        switch (mineDate, theirsDate) {
        | (Some(myActionDate), Some(theirActionDate)) if (myActionDate == "" || myActionDate <= date) && (theirActionDate == "" || theirActionDate <= date) => {
            let replacement: State.entry = {move, myMove, date, myActionDate, theirActionDate, note: editNote->String.trim, category: editCategory}
            commitLedger(person, item => {...item, entries: State.replaceEntry(item.entries, editingEntryIndex, replacement)})->ignore
            setEditingEntryIndex(_ => -1)
            setEntryEditError(_ => "")
          }
        | _ => setEntryEditError(_ => "Action dates must be real dates no later than the round completion date.")
        }
      }
    | (_, _, None) => setEntryEditError(_ => "Enter a valid completion date.")
    | _ => setEntryEditError(_ => "Choose an action for each person.")
    }}
  }

  let remove = (person: State.person) => {
    commit(people->Array.filter(item => item.id != person.id))->ignore
    setSelectedId(_ => "")
    setDeleteTargetId(_ => "")
    setEditTargetId(_ => "")
    setEditingEntryIndex(_ => -1)
    setEntryEditError(_ => "")
  }

  let undo = (person: State.person) => {
    let length = Array.length(person.entries)
    if length > 0 {
      setEditingEntryIndex(_ => -1)
      commitLedger(person, item => {...item, entries: item.entries->Array.filterWithIndex((_, index) => index < length - 1)})->ignore
    }
  }

  let startEdit = (person: State.person) => {
    setSelectedId(_ => person.id)
    setShowInfo(_ => false)
    setShowDashboard(_ => false)
    setShowInsights(_ => false)
    setShowThinkAhead(_ => false)
    setShowSettings(_ => false)
    setDeleteTargetId(_ => "")
    setEditingEntryIndex(_ => -1)
    setEditName(_ => person.name)
    setEditTargetId(_ => person.id)
    scrollTo(0, 0)
  }

  let startDelete = (person: State.person) => {
    setSelectedId(_ => person.id)
    setShowInfo(_ => false)
    setShowDashboard(_ => false)
    setShowInsights(_ => false)
    setShowThinkAhead(_ => false)
    setShowSettings(_ => false)
    setEditTargetId(_ => "")
    setEditingEntryIndex(_ => -1)
    setDeleteTargetId(_ => person.id)
    scrollTo(0, 0)
  }

  let rename = event => {
    ReactEvent.Form.preventDefault(event)
    let name = editName->String.trim
    if name != "" {
      commit(people->Array.map(person => person.id == editTargetId ? {...person, name} : person))->ignore
      setEditTargetId(_ => "")
    }
  }

  let sortedPeople = people->Array.map(person => person)->sortPeople((a, b) => String.compare(a.name->String.toLowerCase, b.name->String.toLowerCase))

  <div className={sidebarCollapsed ? "app-shell sidebar-collapsed" : "app-shell"}>
    <aside className="sidebar">
      <div className="brand">
        <button type_="button" onClick={_ => navigate(Home)}>{React.string("good faith")}</button>
        <button className="sidebar-collapse" type_="button" ariaLabel={sidebarCollapsed ? "Expand sidebar" : "Collapse sidebar"} ariaExpanded={!sidebarCollapsed} onClick={_ => setSidebarCollapsed(previous => !previous)}>{React.string(sidebarCollapsed ? "›" : "‹")}</button>
      </div>

      <div className="sidebar-main">
        <div className="sidebar-search">
          <label htmlFor="person-search">{React.string("Search people")}</label>
          <div className="sidebar-search-field"><span ariaHidden=true>{React.string("⌕")}</span><input id="person-search" type_="search" placeholder="Search people..." value={searchQuery} onChange={event => setSearchQuery(_ => JsxEvent.Form.target(event)["value"])} /></div>
          {searchQuery->String.trim != ""
            ? <div className="sidebar-search-results" ariaLabel="Search results">
                {sortedPeople->Array.filter(person => person.name->String.toLowerCase->String.includes(searchQuery->String.trim->String.toLowerCase))->Array.map(person =>
                  <button key={person.id} type_="button" onClick={_ => {setSearchQuery(_ => ""); navigate(Person(person.id))}}>{React.string(person.name)}</button>
                )->React.array}
              </div>
            : React.null}
        </div>
        <nav className="primary-nav" ariaLabel="Main navigation">
          <button type_="button" title="People" className={showDashboard && !showInfo ? "active" : ""} onClick={_ => navigate(Home)}><span className="sidebar-nav-icon" ariaHidden=true>{navIcon("people")}</span><span className="sidebar-nav-label">{React.string("People")}</span></button>
          <button type_="button" title="Ledger" className={!showDashboard && !showInsights && !showThinkAhead && !showSettings && !showInfo ? "active" : ""} onClick={_ => navigate(Ledger)}><span className="sidebar-nav-icon" ariaHidden=true>{navIcon("ledger")}</span><span className="sidebar-nav-label">{React.string("Ledger")}</span></button>
          <button type_="button" title="Insights" className={showInsights ? "active" : ""} onClick={_ => navigate(Insights)}><span className="sidebar-nav-icon" ariaHidden=true>{navIcon("insights")}</span><span className="sidebar-nav-label">{React.string("Insights")}</span></button>
          <button type_="button" title="Think Ahead" className={showThinkAhead ? "active" : ""} onClick={_ => navigate(Think)}><span className="sidebar-nav-icon" ariaHidden=true>{navIcon("think")}</span><span className="sidebar-nav-label">{React.string("Think Ahead")}</span></button>
        </nav>

        <button className={showSettings ? "sidebar-settings-toggle active" : "sidebar-settings-toggle"} title="Settings" type_="button" onClick={_ => navigate(Settings)}><span className="sidebar-nav-icon" ariaHidden=true>{navIcon("settings")}</span><span className="sidebar-nav-label">{React.string("Settings")}</span></button>

        <form className="add-form" onSubmit={addPerson}>
          <label htmlFor="new-person">{React.string("Quick add")}</label>
          <div className="add-row">
            <input id="new-person" type_="text" placeholder="Their name" value={newName} maxLength=60 disabled={!cloudReady} onChange={event => setNewName(_ => JsxEvent.Form.target(event)["value"])} />
            <button type_="submit" ariaLabel="Add person" disabled={!cloudReady || newName->String.trim == ""}>{React.string("+")}</button>
          </div>
        </form>

        <div className="sidebar-quote"><p>{React.string("Patterns are worth noticing. People are more than patterns.")}</p></div>
      </div>
      <p className="sidebar-foot">{React.string("Your ledger is stored on this device until you sign in.")}</p>
    </aside>

    <main className={(authReady && cloudReady) || showSettings ? "main-content" : "main-content cloud-locked"}>
      {!authReady || !cloudReady ? <section className="cloud-loading" role="status">{React.string(syncError != "" ? "Cloud ledger unavailable. Use Retry loading in Cloud sync." : "Loading your ledger…")}</section> : React.null}
      {addOpen
        ? <form className="quick-add-panel" onSubmit={addPerson} ariaLabel="Add a person">
            <label htmlFor="quick-add-name">{React.string("Add a person")}</label>
            <div><input id="quick-add-name" type_="text" placeholder="Their name" value={newName} maxLength=60 onChange={event => setNewName(_ => JsxEvent.Form.target(event)["value"])} />
              <button type_="submit" disabled={newName->String.trim == ""}>{React.string("Add person")}</button>
              <button type_="button" onClick={_ => setAddOpen(_ => false)}>{React.string("Cancel")}</button></div>
          </form>
        : React.null}
      {if showSettings && !showInfo {
        <section className="settings-page">
          <header className="settings-header"><h1>{React.string("Settings")}</h1><p>{React.string("Manage your account, CURE, and appearance.")}</p></header>
          <section className="settings-section account-tools" ariaLabel="Cloud account">
            <h2>{React.string("Cloud sync")}</h2>
            {passwordRecovery
              ? <form className="account-body" onSubmit={event => {ReactEvent.Form.preventDefault(event); runAuth("update-password")}}>
                  <label htmlFor="new-account-password">{React.string("New password (at least 8 characters)")}</label>
                  <input id="new-account-password" type_="password" autoComplete="new-password" minLength=8 required=true value={password} onChange={event => setPassword(_ => JsxEvent.Form.target(event)["value"])} />
                  <button type_="submit" disabled={authBusy}>{React.string(authBusy ? "Updating…" : "Update password")}</button>
                </form>
              : userId != ""
              ? <div className="account-body">
                  <p>{React.string(email)}</p>
                  <p>{React.string(syncing ? "Saving changes…" : cloudReady ? "Ledger synced to your account." : "Loading your ledger…")}</p>
                  <button type_="button" onClick={_ => runAuth("signout")} disabled={authBusy}>{React.string("Sign out")}</button>
                </div>
              : <form className="account-body" onSubmit={event => {ReactEvent.Form.preventDefault(event); runAuth("signin")}}>
                  <label htmlFor="account-email">{React.string("Email")}</label>
                  <input id="account-email" type_="email" autoComplete="email" required=true value={email} onChange={event => setEmail(_ => JsxEvent.Form.target(event)["value"])} />
                  <label htmlFor="account-password">{React.string("Password (at least 8 characters)")}</label>
                  <input id="account-password" type_="password" autoComplete="current-password" minLength=8 required=true value={password} onChange={event => setPassword(_ => JsxEvent.Form.target(event)["value"])} />
                  <button type_="submit" disabled={authBusy}>{React.string("Sign in")}</button>
                  <button type_="button" disabled={authBusy} onClick={_ => runAuth("signup")}>{React.string("Create account")}</button>
                  <button type_="button" disabled={authBusy} onClick={_ => runAuth("reset")}>{React.string("Forgot password?")}</button>
                </form>}
            {authError != "" ? <p role="alert" className="account-error">{React.string(authError)}</p> : React.null}
            {authMessage != "" ? <p role="status" className="account-message">{React.string(authMessage)}</p> : React.null}
            {syncError != "" ? <div className="account-error" role="alert"><p>{React.string(syncError)}</p><button type_="button" disabled={userId == "" || syncing} onClick={_ => retrySync()}>{React.string(cloudReady ? "Retry sync" : "Retry loading")}</button></div> : React.null}
          </section>
          <section className="settings-section" ariaLabel="CURE tolerance">
            <h2>{React.string("CURE Strategy")}</h2>
            <p>{React.string("Default tolerance: " ++ State.toleranceLabel(tolerance))}</p>
            <p>{React.string("CURE tolerance controls how much cumulative unilateral defection is tolerated before retaliation. Δ1 is more guarded. Δ2 balances protection and forgiveness. Δ3 is more forgiving. Different environments favor different tolerance levels, so individual people and ledgers can override this default.")}</p>
            <p>{React.string("Balanced tolerates up to two outstanding unilateral defections before retaliation. It is the default for general repeated interactions.")}</p>
            <div className="theme-options tolerance-options" role="group" ariaLabel="CURE tolerance">
              {[1, 2, 3]->Array.map(choice => <button key={Int.toString(choice)} type_="button" disabled={toleranceBusy || !cloudReady} ariaPressed={tolerance == choice ? #"true" : #"false"} className={tolerance == choice ? "selected" : ""} onClick={_ => chooseTolerance(choice)->ignore}>{React.string(State.toleranceLabel(choice))}</button>)->React.array}
            </div>
            {[1, 2, 3]->Array.map(choice => <p key={Int.toString(choice)}>{React.string(State.toleranceLabel(choice) ++ ": " ++ State.toleranceHelp(choice))}</p>)->React.array}
            {toleranceBusy ? <p role="status">{React.string("Saving tolerance…")}</p> : React.null}
            {toleranceError != "" ? <p role="alert">{React.string(toleranceError)}</p> : React.null}
          </section>
          <section className="settings-section" ariaLabel="Local backup">
            <h2>{React.string("Local backup")}</h2>
            <p>{React.string("Download your people, interaction history, drafts, CURE tolerance, and Think Ahead scenarios as a JSON file.")}</p>
            <div className="account-body">
              <button type_="button" disabled={!cloudReady} onClick={_ => downloadBackup(Storage.serialize(people), tolerance, serializeScenarios(scenarios))}>{React.string("Download backup")}</button>
              <input id="backup-file" className="backup-file-input" type_="file" accept="application/json,.json" disabled={!cloudReady} onChange={readBackup} />
              <label className="backup-file-button" htmlFor="backup-file">{React.string("Choose backup file to restore")}</label>
            </div>
            {backupError != "" ? <p role="alert">{React.string(backupError)}</p> : React.null}
            {backupMessage != "" ? <p role="status">{React.string(backupMessage)}</p> : React.null}
            {backupPreview ? <div className="account-body">
              <p role="status">{React.string("This will replace the current ledger with " ++ Int.toString(Array.length(backupPeople)) ++ " people, set CURE tolerance to " ++ Int.toString(backupTolerance) ++ ", and replace Think Ahead with " ++ Int.toString(Array.length(backupScenarios)) ++ " scenarios.")}</p>
              <button type_="button" disabled={!cloudReady || backupSaving || syncing || toleranceBusy || (!scenariosReady && Array.length(backupScenarios) > 0)} onClick={_ => restoreBackup()}>{React.string(backupSaving ? "Restoring…" : "Replace current ledger")}</button>
              <button type_="button" onClick={_ => setBackupPreview(_ => false)}>{React.string("Cancel")}</button>
            </div> : React.null}
          </section>
          <section className="settings-section" ariaLabel="Appearance">
            <h2>{React.string("Appearance")}</h2><p>{React.string("Choose the color theme for this device.")}</p>
            <div className="theme-options" role="group" ariaLabel="Color theme">
              {["auto", "light", "dark"]->Array.map(choice => <button key={choice} type_="button" ariaPressed={theme == choice ? #"true" : #"false"} className={theme == choice ? "selected" : ""} onClick={_ => chooseTheme(choice)}>{React.string(choice->String.capitalize)}</button>)->React.array}
            </div>
          </section>
          <button className="settings-info-link" type_="button" onClick={_ => openInfo()}>{React.string("How the method works →")}</button>
        </section>
      } else if showInfo {
        <div className="info-view"><button className="info-back" type_="button" onClick={_ => leaveInfo()}>{React.string(returnView == "settings" ? "Back to settings" : "Back to tracker")}</button><Info /></div>
      } else if showThinkAhead {
        {scenariosReady ? <ThinkAhead key={userId ++ ":" ++ Int.toString(thinkAheadSession)} scenarios people onChange={commitScenarios} initialDraft={thinkAheadDraft} onDirtyChange={dirty => setThinkAheadDirty(_ => dirty)} /> : <section className="think-ahead"><h1>{React.string("Think Ahead")}</h1><p>{React.string("Cloud sync setup is pending. Your CURE ledger remains available. Your signed-out Think Ahead scenarios remain in this browser.")}</p></section>}
      } else if showInsights {
        <section className="insights-page">
          <h1>{React.string("Insights")}</h1>
          <p>{React.string("A compact view of what you recorded. The difference is their cumulative defections minus yours, not a relationship score.")}</p>
          <div className="insights-table-wrap"><table><thead><tr><th scope="col">{React.string("Person / Ledger")}</th><th scope="col">{React.string("Interactions")}</th><th scope="col">{React.string("Difference")}</th><th scope="col">{React.string("Tolerance")}</th><th scope="col">{React.string("CURE suggests")}</th></tr></thead><tbody>{sortedPeople->Array.flatMap(person => person->State.allLedgers->Array.map(ledger => {
            let effective = State.effectiveTolerance(tolerance, person.cureDeltaOverride, ledger.cureDeltaOverride)
            let decision = State.next(ledger.entries, ~tolerance=effective)
            <tr key={person.id ++ ":" ++ ledger.id}><th scope="row"><button type_="button" onClick={_ => {openPerson(person); setSelectedLedgerId(_ => ledger.id); switch ledger.drafts->Array.get(0) { | Some(draft) => loadDraft(draft) | None => startNewDraft() }}}>{React.string(person.name ++ " / " ++ ledger.name)}</button></th><td>{React.string(Int.toString(Array.length(ledger.entries)))}</td><td>{React.string(Int.toString(decision.difference))}</td><td>{React.string(State.toleranceLabel(effective))}</td><td>{React.string(nextLabel(decision.move))}</td></tr>
          }))->React.array}</tbody></table></div>
          {Array.length(people) == 0 ? <p>{React.string("Add a person to start seeing your record here.")}</p> : React.null}
        </section>
      } else if showDashboard {
        <Dashboard people={sortedPeople} tolerance onSelect={openPerson} onSeeAll={openLedger} onAdd={() => {setAddOpen(_ => true); scrollTo(0, 0)}} onLearn={openInfo} />
      } else {
      switch selected {
      | None =>
        Array.length(people) == 0
          ? <section className="empty-state">
              <h1>{React.string("Start with good faith.")}</h1>
              <p>{React.string("Add a person, then log what both of you did in each interaction. CURE compares your cumulative defections with theirs to suggest your next move.")}</p>
              <button type_="button" onClick={_ => {setAddOpen(_ => true); scrollTo(0, 0)}}>{React.string("Add your first person")}</button>
            </section>
          : <section className="ledger-index">
              <h1>{React.string("Ledgers")}</h1>
              <p>{React.string("Choose a person to see their interaction history or log what happened next.")}</p>
              <div className="ledger-person-list">{sortedPeople->Array.map(person => {
                let count = Array.length(person.entries)
                <button key={person.id} type_="button" onClick={_ => openPerson(person)} ariaLabel={"Open " ++ person.name ++ "'s ledger"}>
                  <span><strong>{React.string(person.name)}</strong><small>{React.string(Int.toString(count) ++ (count == 1 ? " General interaction" : " General interactions"))}</small></span>
                  <span>{React.string("General CURE: " ++ nextLabel(State.next(person.entries, ~tolerance=State.effectiveTolerance(tolerance, person.cureDeltaOverride, person.generalCureDeltaOverride)).move))}</span>
                  <span ariaHidden=true>{React.string("›")}</span>
                </button>
              })->React.array}</div>
            </section>
      | Some(owner) => {
          let appTolerance = tolerance
          let ledgers = owner.ledgers->Option.getOr([])
          let activeLedger = ledgers->Array.find(ledger => ledger.id == selectedLedgerId)
          let person = State.ledgerView(owner, selectedLedgerId)
          let inherited = State.effectiveTolerance(appTolerance, owner.cureDeltaOverride, None)
          let ledgerOverride = switch activeLedger { | Some(ledger) => ledger.cureDeltaOverride | None => owner.generalCureDeltaOverride }
          let tolerance = State.effectiveTolerance(appTolerance, owner.cureDeltaOverride, ledgerOverride)
          let ledgerName = switch activeLedger { | Some(ledger) => ledger.name | None => "General" }
          let inheritanceLabel = owner.cureDeltaOverride == None ? "Inherit from app default: " : "Inherit from " ++ owner.name ++ ": "
          let switchLedger = id => {
            setLedgerDeleteOpen(_ => false)
            setSelectedLedgerId(_ => id)
            setEditingEntryIndex(_ => -1)
            setEntryEditError(_ => "")
            let view = State.ledgerView(owner, id)
            switch view.drafts->Array.get(0) { | Some(draft) => loadDraft(draft) | None => startNewDraft() }
          }
          let decision = State.next(person.entries, ~tolerance)
          let count = Array.length(person.entries)
          let history = State.history(person.entries, ~tolerance)->Belt.Array.reverse
          let isSavedDraft = person.drafts->Array.some(draft => draft.id == currentDraftId)
          let editCategoryKnown = switch editCategory { | "" | "Work" | "Favor" | "Commitment" | "Money" | "Social" | "Support" | "Other" => true | _ => false }
          <div className="detail">
            <button className="text-button ledger-back" type_="button" onClick={_ => openLedger()}>{React.string("‹ All ledgers")}</button>
            <div className="detail-heading">
              <div><h1>{React.string(person.name)}</h1><p className="detail-subtitle">{React.string(count == 0 ? "No interactions logged yet" : Int.toString(count) ++ (count == 1 ? " interaction recorded" : " interactions recorded"))}</p></div>
              <div className="detail-actions">
                <button className="text-button" type_="button" ariaExpanded={editTargetId == person.id} onClick={_ => editTargetId == person.id ? setEditTargetId(_ => "") : startEdit(person)}>{React.string("Edit name")}</button>
                <button className="text-button delete-button" type_="button" ariaExpanded={deleteTargetId == person.id} onClick={_ => deleteTargetId == person.id ? setDeleteTargetId(_ => "") : startDelete(person)}>{React.string("Delete person")}</button>
              </div>
            </div>

            {editTargetId == person.id
              ? <form className="rename-form" onSubmit={rename} ariaLabel="Edit person name">
                  <label htmlFor="edit-person-name">{React.string("Name")}</label>
                  <div><input id="edit-person-name" type_="text" value={editName} maxLength=60 onChange={event => setEditName(_ => JsxEvent.Form.target(event)["value"])} />
                    <button type_="submit" disabled={editName->String.trim == ""}>{React.string("Save")}</button>
                    <button type_="button" onClick={_ => setEditTargetId(_ => "")}>{React.string("Cancel")}</button></div>
                </form>
              : React.null}

            {deleteTargetId == person.id
              ? <section className="delete-confirmation" ariaLabel="Confirm deletion">
                  <div><strong>{React.string("Delete " ++ person.name ++ "?")}</strong><p>{React.string("Their interaction history will be removed from your ledger permanently.")}</p></div>
                  <div className="delete-actions"><button type_="button" className="cancel-delete" onClick={_ => setDeleteTargetId(_ => "")}>{React.string("Keep person")}</button><button type_="button" className="confirm-delete" onClick={_ => remove(person)}>{React.string("Delete permanently")}</button></div>
                </section>
              : React.null}

            <section className="cure-settings" ariaLabel="Person and ledger settings">
              <label htmlFor="person-tolerance">{React.string("Person CURE tolerance")}</label>
              <select id="person-tolerance" disabled={!cloudReady || syncing} value={switch owner.cureDeltaOverride { | Some(value) => Int.toString(value) | None => "" }} onChange={event => {
                let choice = State.toleranceFromChoice(JsxEvent.Form.target(event)["value"])
                saveOverride(people->Array.map(item => item.id == owner.id ? {...item, cureDeltaOverride: ?choice} : item))
              }}><option value="">{React.string("Use app default: " ++ State.toleranceLabel(appTolerance))}</option>{toleranceOptions()}</select>
              <p>{React.string(State.toleranceLabel(inherited) ++ (owner.cureDeltaOverride == None ? " · Inherited from app default" : " · Custom for this person"))}</p>
              <label htmlFor="active-ledger">{React.string("Ledger")}</label>
              <select id="active-ledger" value={selectedLedgerId} onChange={event => switchLedger(JsxEvent.Form.target(event)["value"])}>
                <option value="">{React.string("General · " ++ State.toleranceLabel(State.effectiveTolerance(appTolerance, owner.cureDeltaOverride, owner.generalCureDeltaOverride)))}</option>
                {ledgers->Array.map(ledger => <option key={ledger.id} value={ledger.id}>{React.string(ledger.name ++ " · " ++ State.toleranceLabel(State.effectiveTolerance(appTolerance, owner.cureDeltaOverride, ledger.cureDeltaOverride)))}</option>)->React.array}
              </select>
              {activeLedger != None ? <button className="text-button delete-button" type_="button" disabled={!cloudReady || syncing} onClick={_ => setLedgerDeleteOpen(_ => true)}>{React.string("Delete ledger")}</button> : React.null}
              {ledgerDeleteOpen && activeLedger != None ? <ConfirmDialog title={"Delete " ++ ledgerName ++ " ledger?"} message="This permanently removes this ledger's interaction history, saved drafts, and tolerance override. The person and their other ledgers will be kept." keepLabel="Keep ledger" confirmLabel="Delete ledger permanently" onKeep={() => setLedgerDeleteOpen(_ => false)} onConfirm={() => {
                setToleranceError(_ => "")
                commit(people->Array.map(item => item.id == owner.id ? State.removeLedger(item, selectedLedgerId) : item))
                ->Promise.then(saved => {if !saved {setToleranceError(_ => "Could not save ledger deletion. Retry sync or try again.")}; Promise.resolve(())})->ignore
                switchLedger("")
              }} /> : React.null}
              <details><summary>{React.string("Create another ledger")}</summary>
                <form className="new-ledger-form" ariaLabel="Create ledger" onSubmit={event => {
                  ReactEvent.Form.preventDefault(event)
                  if newLedgerName->String.trim != "" {
                    setToleranceError(_ => "")
                    let id = Storage.randomUUID()
                    let ledger: State.ledger = {id, name: newLedgerName->String.trim, entries: [], drafts: [], cureDeltaOverride: ?State.toleranceFromChoice(newLedgerTolerance)}
                    commit(people->Array.map(item => item.id == owner.id ? {...item, ledgers: Array.concat(ledgers, [ledger])} : item))
                    ->Promise.then(saved => {if saved {setSelectedLedgerId(_ => id); setNewLedgerName(_ => ""); setNewLedgerTolerance(_ => ""); setEditingEntryIndex(_ => -1); startNewDraft()} else {setToleranceError(_ => "Could not save the new ledger. Retry when ready.")}; Promise.resolve(())})->ignore
                  }
                }}>
                  <label htmlFor="new-ledger-name">{React.string("New ledger name")}</label>
                  <input id="new-ledger-name" value={newLedgerName} maxLength=60 placeholder="Dishes, Money, Favors…" onChange={event => setNewLedgerName(_ => JsxEvent.Form.target(event)["value"])} />
                  <label htmlFor="new-ledger-tolerance">{React.string("CURE tolerance")}</label>
                  <select id="new-ledger-tolerance" value={newLedgerTolerance} onChange={event => setNewLedgerTolerance(_ => JsxEvent.Form.target(event)["value"])}><option value="">{React.string("Use inherited setting: " ++ State.toleranceLabel(inherited))}</option>{toleranceOptions()}</select>
                  <button type_="submit" disabled={!cloudReady || syncing || newLedgerName->String.trim == ""}>{React.string("Create ledger")}</button>
                </form>
              </details>
            </section>

            <section className={"decision-panel " ++ decisionClass(decision)} ariaLabel="Suggested next move">
              <div className="decision-copy">
                <h2>{React.string("CURE suggests")}</h2>
                <p className="decision-action">{React.string(decisionLabel(decision))}</p>
                <p>{React.string(decision.explanation)}</p>
              </div>
              <p className="decision-rule">{React.string(ledgerName ++ " · Balance: " ++ Int.toString(decision.difference))}</p>
              <label htmlFor="ledger-tolerance">{React.string("CURE tolerance: " ++ State.toleranceLabel(tolerance))}</label>
              <select id="ledger-tolerance" disabled={!cloudReady || syncing} value={switch ledgerOverride { | Some(value) => Int.toString(value) | None => "" }} onChange={event => {
                let choice = State.toleranceFromChoice(JsxEvent.Form.target(event)["value"])
                saveOverride(people->Array.map(item => item.id != owner.id ? item : selectedLedgerId == "" ? {...item, generalCureDeltaOverride: ?choice} : {...item, ledgers: ledgers->Array.map(ledger => ledger.id == selectedLedgerId ? {...ledger, cureDeltaOverride: ?choice} : ledger)}))
              }}><option value="">{React.string(inheritanceLabel ++ State.toleranceLabel(inherited))}</option>{toleranceOptions()}</select>
              <p>{React.string(ledgerOverride == None ? inheritanceLabel ++ State.toleranceLabel(inherited) : "Custom for this ledger")}</p>
              <details><summary>{React.string("About CURE tolerance")}</summary><p>{React.string("Δ is the amount of outstanding defection imbalance CURE tolerates before responding with defection. Guarded Δ1: faster response to imbalance. Balanced Δ2: middle-ground default. Forgiving Δ3: more tolerance for mistakes and temporary imbalance. Changing tolerance keeps all history intact. You control this setting; it never changes automatically.")}</p></details>
              {toleranceError != "" ? <p role="alert">{React.string(toleranceError)}</p> : React.null}
              <button type_="button" className="decision-think-ahead" onClick={_ => thinkThrough(person, decision.move)}>{React.string("Think this decision through")}</button>
            </section>

            <section className="record-section">
              <div className="record-intro"><h2>{React.string("What happened?")}</h2><p>{React.string("Record what each person did. Choose No action when one person had no role in the interaction.")}</p></div>
              <div className="pending-drafts" ariaLabel="Pending drafts">
                <h3>{React.string("Pending rounds")}</h3>
                {person.drafts->Array.mapWithIndex((draft, index) => {
                  let summary = draft.note != "" ? draft.note : draft.category != "" ? draft.category : "Incomplete round"
                  <button key={draft.id} type_="button" className={draft.id == currentDraftId ? "draft-choice selected" : "draft-choice"} ariaPressed={draft.id == currentDraftId ? #"true" : #"false"} onClick={_ => loadDraft(draft)}>{React.string("Draft " ++ Int.toString(index + 1) ++ " · " ++ summary)}</button>
                })->React.array}
                <button type_="button" className="text-button new-draft-button" onClick={_ => startNewDraft()}>{React.string("+ New round")}</button>
              </div>
              <label className="note-label" htmlFor="interaction-date">{React.string("When was this round completed?")}</label>
              <p id="completion-date-help" className="date-help">{React.string("Use the date when this interaction was completed or resolved. Recheck this date when confirming; the draft's creation date is not used.")}</p>
              <div className="date-row">
                <div className="date-input-wrap">
                  <input id="interaction-date" className="date-input" type_="text" inputMode="numeric" placeholder="YYYY-MM-DD or YYYYMMDD" value={interactionDate} maxLength=10 ariaDescribedby="completion-date-help" onClick={_ => openCalendar("round", interactionDate)} onChange={event => {setInteractionDate(_ => JsxEvent.Form.target(event)["value"]); setCalendarTarget(_ => ""); setDateError(_ => ""); setActionDateError(_ => "")}} />
                  <button className="calendar-toggle" type_="button" ariaLabel={calendarTarget == "round" ? "Close completion calendar" : "Open completion calendar"} ariaExpanded={calendarTarget == "round"} onClick={_ => calendarTarget == "round" ? setCalendarTarget(_ => "") : openCalendar("round", interactionDate)}><span className="calendar-glyph" ariaHidden=true></span></button>
                </div>
                <button type_="button" onClick={_ => {setInteractionDate(_ => today()); setCalendarTarget(_ => ""); setDateError(_ => ""); setActionDateError(_ => "")}}>{React.string("Today")}</button>
                <button type_="button" onClick={_ => {setInteractionDate(_ => yesterday()); setCalendarTarget(_ => ""); setDateError(_ => ""); setActionDateError(_ => "")}}>{React.string("Yesterday")}</button>
              </div>
              {calendarPanel("round", interactionDate, "Choose round completion date")}
              {dateError != "" ? <p className="date-error" role="alert">{React.string(dateError)}</p> : React.null}
              <label className="note-label" htmlFor="entry-note">{React.string("What is this about? (optional)")}</label>
              <input id="entry-note" className="note-input" type_="text" placeholder="What was this interaction about?" value={note} maxLength=180 onChange={event => setNote(_ => JsxEvent.Form.target(event)["value"])} />
              <div className="action-dates-field">
                <button type_="button" className="action-dates-toggle" ariaExpanded={actionDatesOpen} ariaControls="action-dates" onClick={_ => {setActionDatesOpen(previous => !previous); setCalendarTarget(_ => "")}}>{React.string("Different action dates? Add them")}<span ariaHidden=true>{React.string(actionDatesOpen ? "−" : "+")}</span></button>
                {actionDatesOpen
                  ? <div id="action-dates" className="action-dates-inputs">
                      <div><label className="note-label" htmlFor="my-action-date">{React.string("Your action date (optional)")}</label><div className="date-input-wrap"><input id="my-action-date" className="date-input" type_="text" inputMode="numeric" placeholder="YYYY-MM-DD" value={myActionDate} maxLength=10 onClick={_ => openCalendar("my", myActionDate)} onChange={event => {setMyActionDate(_ => JsxEvent.Form.target(event)["value"]); setCalendarTarget(_ => ""); setActionDateError(_ => "")}} /><button className="calendar-toggle" type_="button" ariaLabel={calendarTarget == "my" ? "Close your action calendar" : "Open your action calendar"} ariaExpanded={calendarTarget == "my"} onClick={_ => calendarTarget == "my" ? setCalendarTarget(_ => "") : openCalendar("my", myActionDate)}><span className="calendar-glyph" ariaHidden=true></span></button></div>{calendarPanel("my", myActionDate, "Choose your action date")}</div>
                      <div><label className="note-label" htmlFor="their-action-date">{React.string("Their action date (optional)")}</label><div className="date-input-wrap"><input id="their-action-date" className="date-input" type_="text" inputMode="numeric" placeholder="YYYY-MM-DD" value={theirActionDate} maxLength=10 onClick={_ => openCalendar("their", theirActionDate)} onChange={event => {setTheirActionDate(_ => JsxEvent.Form.target(event)["value"]); setCalendarTarget(_ => ""); setActionDateError(_ => "")}} /><button className="calendar-toggle" type_="button" ariaLabel={calendarTarget == "their" ? "Close their action calendar" : "Open their action calendar"} ariaExpanded={calendarTarget == "their"} onClick={_ => calendarTarget == "their" ? setCalendarTarget(_ => "") : openCalendar("their", theirActionDate)}><span className="calendar-glyph" ariaHidden=true></span></button></div>{calendarPanel("their", theirActionDate, "Choose their action date")}</div>
                    </div>
                  : React.null}
                {actionDateError != "" ? <p className="date-error" role="alert">{React.string(actionDateError)}</p> : React.null}
              </div>
              <div className="category-field">
                <button className="category-toggle" type_="button" ariaExpanded={categoryOpen} ariaControls="category-options" onClick={_ => setCategoryOpen(previous => !previous)}>{React.string("Category (optional): " ++ (category == "" ? "None" : category))}<span ariaHidden=true>{React.string(categoryOpen ? "−" : "+")}</span></button>
                {categoryOpen
                  ? <div id="category-options" className="category-options" role="group" ariaLabel="Interaction category">
                      {["", "Work", "Favor", "Commitment", "Money", "Social", "Support", "Other"]->Array.map(choice => <button key={choice} type_="button" ariaPressed={category == choice ? #"true" : #"false"} className={category == choice ? "selected" : ""} onClick={_ => {setCategory(_ => choice); setCategoryOpen(_ => false)}}>{React.string(choice == "" ? "None" : choice)}</button>)->React.array}
                    </div>
                  : React.null}
              </div>
              <div className="own-move-field">
                <p className="note-label">{React.string("What did you do?")}</p>
                <div className="own-move-options" role="group" ariaLabel="Your move in this interaction">
                  <button type_="button" ariaPressed={myMove == "Cooperate" ? #"true" : #"false"} className={"action-cooperate" ++ (myMove == "Cooperate" ? " selected" : "")} onClick={_ => setMyMove(previous => previous == "Cooperate" ? "" : "Cooperate")}>{React.string("Cooperated")}</button>
                  <button type_="button" ariaPressed={myMove == "Defect" ? #"true" : #"false"} className={"action-defect" ++ (myMove == "Defect" ? " selected" : "")} onClick={_ => setMyMove(previous => previous == "Defect" ? "" : "Defect")}>{React.string("Defected")}</button>
                  <button type_="button" ariaPressed={myMove == "Request" ? #"true" : #"false"} className={"action-request" ++ (myMove == "Request" ? " selected" : "")} onClick={_ => setMyMove(previous => previous == "Request" ? "" : "Request")}>{React.string("Requested")}</button>
                  <button type_="button" ariaPressed={myMove == "Unable" ? #"true" : #"false"} className={"action-request" ++ (myMove == "Unable" ? " selected" : "")} onClick={_ => setMyMove(previous => previous == "Unable" ? "" : "Unable")}>{React.string("Unable")}</button>
                  <button type_="button" ariaPressed={myMove == "NoAction" ? #"true" : #"false"} className={"action-request" ++ (myMove == "NoAction" ? " selected" : "")} onClick={_ => setMyMove(previous => previous == "NoAction" ? "" : "NoAction")}>{React.string("No action")}</button>
                </div>
                {myMove == "" ? <p className="own-move-hint">{React.string("Choose a role for each person before confirming. Use No action when nothing was required or done.")}</p> : React.null}
                <p className="own-move-hint">{React.string("Cooperate (C): Helped, contributed, kept promise, or otherwise acted cooperatively.")}</p>
                <p className="own-move-hint">{React.string("Defect (D): Refused, withheld help, broke an agreement, exploited the other person, or otherwise acted uncooperatively.")}</p>
                <p className="own-move-hint">{React.string("Request (R): Asked for help, a favor, or cooperation. A request is neutral and does not count as cooperation or defection.")}</p>
                <p className="own-move-hint">{React.string("Unable (U): You/They were genuinely unable to help because of circumstances outside your reasonable control. This does not count as cooperation or defection. Examples include being sick, unavailable, lacking the needed resources, or having a genuine conflicting obligation.")}</p>
                <p className="own-move-hint">{React.string("No action (Ø): Nothing was required or done by this person. Neutral and does not affect CURE.")}</p>
              </div>
              <div className="own-move-field">
                <p className="note-label">{React.string("What did they do?")}</p>
                <div className="own-move-options" role="group" ariaLabel="Their move in this interaction">
                  <button type_="button" ariaPressed={theirMove == "Cooperate" ? #"true" : #"false"} className={"action-cooperate" ++ (theirMove == "Cooperate" ? " selected" : "")} onClick={_ => setTheirMove(previous => previous == "Cooperate" ? "" : "Cooperate")}>{React.string("Cooperated")}</button>
                  <button type_="button" ariaPressed={theirMove == "Defect" ? #"true" : #"false"} className={"action-defect" ++ (theirMove == "Defect" ? " selected" : "")} onClick={_ => setTheirMove(previous => previous == "Defect" ? "" : "Defect")}>{React.string("Defected")}</button>
                  <button type_="button" ariaPressed={theirMove == "Request" ? #"true" : #"false"} className={"action-request" ++ (theirMove == "Request" ? " selected" : "")} onClick={_ => setTheirMove(previous => previous == "Request" ? "" : "Request")}>{React.string("Requested")}</button>
                  <button type_="button" ariaPressed={theirMove == "Unable" ? #"true" : #"false"} className={"action-request" ++ (theirMove == "Unable" ? " selected" : "")} onClick={_ => setTheirMove(previous => previous == "Unable" ? "" : "Unable")}>{React.string("Unable")}</button>
                  <button type_="button" ariaPressed={theirMove == "NoAction" ? #"true" : #"false"} className={"action-request" ++ (theirMove == "NoAction" ? " selected" : "")} onClick={_ => setTheirMove(previous => previous == "NoAction" ? "" : "NoAction")}>{React.string("No action")}</button>
                </div>
              </div>
              <p className="own-move-hint">{React.string("Use the same meanings for what they did. Confirm a Cooperated or Defected action, or a Requested/Unable pair. No action on both sides is not a round.")}</p>
              {isSavedDraft ? <p className="own-move-hint">{React.string("Edit this saved draft, then save, confirm, or discard it.")}</p> : React.null}
              <div className="draft-actions">
                <button type_="button" className="move-button" onClick={_ => saveDraft(person)}>{React.string(isSavedDraft ? "Save draft changes" : "Save draft")}</button>
                <button type_="button" className="move-button cooperate" disabled={!State.validChoices(myMove, theirMove)} onClick={_ => confirmRound(person)}>{React.string("Confirm round")}</button>
                {isSavedDraft ? <button type_="button" className="move-button defect" onClick={_ => discardDraft(person)}>{React.string("Discard draft")}</button> : React.null}
              </div>
            </section>

            <section className="history-section">
              <div className="history-heading"><div><h2>{React.string("The pattern")}</h2><p>{React.string("Most recent first")}</p></div><button className="text-button" type_="button" disabled={count == 0} onClick={_ => undo(person)}>{React.string("Undo last entry")}</button></div>
              {count == 0
                ? <p className="history-empty">{React.string("No interactions yet.")}</p>
                : <ol className="history-list">{history->Array.map(item => {
                    let entry = item.entry
                    let different = State.differentFromRecommendation(entry.myMove, item.recommended)
                    let hasActionDates = entry.myActionDate != "" || entry.theirActionDate != ""
                    <li key={Int.toString(item.sourceIndex)} className={switch entry.move { | State.Cooperated => "cooperate" | State.Defected => "defect" | _ => "" }}>
                      <span className="history-symbol">{React.string(switch entry.move { | State.Cooperated => "C" | State.Defected => "D" | State.Requested => "R" | State.Unable => "U" | State.NoAction => "Ø" })}</span>
                      <div>
                        <strong>{React.string("Them: " ++ State.actionLabel(entry.move))}</strong>{entry.category != "" ? <span className="history-category">{React.string(entry.category)}</span> : React.null}
                        <p className="history-moves">{React.string("CURE before: " ++ nextLabel(item.recommended) ++ " (difference " ++ Int.toString(item.differenceBefore) ++ ")")}{!hasActionDates ? <span className={different ? "actual-move diverged" : "actual-move"}>{React.string(" · You: " ++ State.actionLabel(entry.myMove) ++ (different ? " (different)" : ""))}</span> : React.null}</p>
                        {hasActionDates
                          ? <div className="history-action-dates">
                              <p>{React.string("You: " ++ State.actionLabel(entry.myMove) ++ (entry.myActionDate == "" ? "" : " · " ++ displayDate(entry.myActionDate)) ++ (different ? " (different from suggestion)" : ""))}</p>
                              <p>{React.string("Them: " ++ State.actionLabel(entry.move) ++ (entry.theirActionDate == "" ? "" : " · " ++ displayDate(entry.theirActionDate)))}</p>
                              <p>{React.string("Round completed: " ++ displayDate(entry.date))}</p>
                            </div>
                          : React.null}
                        {entry.note != "" ? <p>{React.string(entry.note)}</p> : React.null}
                        <button className="text-button entry-edit-toggle" type_="button" ariaExpanded={editingEntryIndex == item.sourceIndex} onClick={_ => editingEntryIndex == item.sourceIndex ? setEditingEntryIndex(_ => -1) : startEditEntry(item.sourceIndex, entry)}>{React.string("Edit entry")}</button>
                        {editingEntryIndex == item.sourceIndex
                          ? <form className="entry-edit-form" ariaLabel="Edit confirmed entry" onSubmit={event => {ReactEvent.Form.preventDefault(event); saveEntryEdit(person)}}>
                              <label htmlFor="edit-my-move">{React.string("Your move")}</label>
                              <select id="edit-my-move" value={editMyMove} onChange={event => setEditMyMove(_ => JsxEvent.Form.target(event)["value"])}>
                                <option value="">{React.string("Choose an action")}</option><option value="Cooperate">{React.string("Cooperated")}</option><option value="Defect">{React.string("Defected")}</option><option value="Request">{React.string("Requested")}</option><option value="Unable">{React.string("Unable")}</option><option value="NoAction">{React.string("No action")}</option>
                              </select>
                              <label htmlFor="edit-their-move">{React.string("Their move")}</label>
                              <select id="edit-their-move" value={editTheirMove} onChange={event => setEditTheirMove(_ => JsxEvent.Form.target(event)["value"])}>
                                <option value="">{React.string("Choose an action")}</option><option value="Cooperate">{React.string("Cooperated")}</option><option value="Defect">{React.string("Defected")}</option><option value="Request">{React.string("Requested")}</option><option value="Unable">{React.string("Unable")}</option><option value="NoAction">{React.string("No action")}</option>
                              </select>
                              <label htmlFor="edit-round-date">{React.string("Completion date")}</label><input id="edit-round-date" type_="date" required=true value={editDate} onChange={event => setEditDate(_ => JsxEvent.Form.target(event)["value"])} />
                              <label htmlFor="edit-my-action-date">{React.string("Your action date (optional)")}</label><input id="edit-my-action-date" type_="date" value={editMyActionDate} onChange={event => setEditMyActionDate(_ => JsxEvent.Form.target(event)["value"])} />
                              <label htmlFor="edit-their-action-date">{React.string("Their action date (optional)")}</label><input id="edit-their-action-date" type_="date" value={editTheirActionDate} onChange={event => setEditTheirActionDate(_ => JsxEvent.Form.target(event)["value"])} />
                              <label htmlFor="edit-entry-note">{React.string("Note (optional)")}</label><input id="edit-entry-note" type_="text" maxLength=180 value={editNote} onChange={event => setEditNote(_ => JsxEvent.Form.target(event)["value"])} />
                              <label htmlFor="edit-entry-category">{React.string("Category (optional)")}</label><select id="edit-entry-category" value={editCategory} onChange={event => setEditCategory(_ => JsxEvent.Form.target(event)["value"])}>
                                {!editCategoryKnown ? <option value={editCategory}>{React.string(editCategory)}</option> : React.null}
                                <option value="">{React.string("None")}</option><option value="Work">{React.string("Work")}</option><option value="Favor">{React.string("Favor")}</option><option value="Commitment">{React.string("Commitment")}</option><option value="Money">{React.string("Money")}</option><option value="Social">{React.string("Social")}</option><option value="Support">{React.string("Support")}</option><option value="Other">{React.string("Other")}</option>
                              </select>
                              {entryEditError != "" ? <p className="date-error" role="alert">{React.string(entryEditError)}</p> : React.null}
                              <div className="entry-edit-actions"><button type_="submit">{React.string("Save changes")}</button><button type_="button" onClick={_ => {setEditingEntryIndex(_ => -1); setEntryEditError(_ => "")}}>{React.string("Cancel")}</button></div>
                            </form>
                          : React.null}
                      </div>
                      {!hasActionDates ? <time>{React.string(entry.date)}</time> : React.null}
                    </li>
                  })->React.array}</ol>}
            </section>
          </div>
        }
      }
      }}
    </main>
    {switch pendingDestination {
    | None => React.null
    | Some(destination) => <ConfirmDialog title="Discard unsaved changes?" message="" keepLabel="Keep editing" confirmLabel="Discard changes" onKeep={() => setPendingDestination(_ => None)} onConfirm={() => {setPendingDestination(_ => None); setThinkAheadDirty(_ => false); goTo(destination)}} />
    }}
    <nav className="mobile-bottom-nav" ariaLabel="Mobile navigation">
      <button type_="button" className={showDashboard && !showInfo ? "active" : ""} onClick={_ => navigate(Home)}>{React.string("Home")}</button>
      <button type_="button" className={!showDashboard && !showInsights && !showThinkAhead && !showSettings && !showInfo ? "active" : ""} onClick={_ => navigate(Ledger)}>{React.string("Ledger")}</button>
      <button type_="button" className="mobile-add" ariaLabel="Add a person" onClick={_ => navigate(Add)}>{React.string("+")}</button>
      <button type_="button" className={showInsights ? "active" : ""} onClick={_ => navigate(Insights)}>{React.string("Insights")}</button>
      <button type_="button" className={showThinkAhead ? "active" : ""} onClick={_ => navigate(Think)}>{React.string("Think Ahead")}</button>
      <button type_="button" className={showSettings ? "active" : ""} onClick={_ => navigate(Settings)}>{React.string("Settings")}</button>
    </nav>
  </div>
}
