type backupFile
type calendarDay = {date: string, label: string, accessible: string, disabled: bool}
type calendarView = {title: string, days: array<calendarDay>, previous: string, next: string, previousDisabled: bool, nextDisabled: bool}
@send external readFile: backupFile => promise<string> = "text"
@module("./BackupDownload.js") external download: string => unit = "download"
@module("./InteractionDate.js") external today: unit => string = "today"
@module("./InteractionDate.js") external yesterday: unit => string = "yesterday"
@module("./InteractionDate.js") external normalizeDate: string => Nullable.t<string> = "normalize"
@module("./InteractionDate.js") external displayDate: string => string = "displayDate"
@module("./InteractionDate.js") external getCalendarMonth: string => calendarView = "calendarMonth"
@module("./Theme.js") external loadTheme: unit => string = "load"
@module("./Theme.js") external applyTheme: string => unit = "apply"
@scope("window") @val external scrollTo: (int, int) => unit = "scrollTo"

let moveClass = move => switch move { | State.Cooperate => "cooperate" | State.Defect => "defect" }
let nextLabel = move => switch move { | State.Cooperate => "Cooperate" | State.Defect => "Withhold cooperation" }
let decisionClass = (decision: State.decision) => moveClass(decision.move)
let decisionLabel = (decision: State.decision) => nextLabel(decision.move)
let countLabel = (count, singular, plural) => Int.toString(count) ++ " " ++ (count == 1 ? singular : plural)
let navIcon = kind => {
  let shape = switch kind {
  | "people" => "M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8a4 4 0 0 0 0 8M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"
  | "ledger" => "M5 3h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2ZM7 8h10M7 12h10M7 16h7"
  | "insights" => "M4 20V11M10 20V5M16 20v-8M22 20V8M2 20h20"
  | "backup" => "M12 3v12m-4-4 4 4 4-4M5 17v3h14v-3"
  | _ => "M10 2h4l.6 2.2 1.5.9 2.2-.6 2 3.5-1.6 1.6v1.8l1.6 1.6-2 3.5-2.2-.6-1.5.9L14 20h-4l-.6-2.2-1.5-.9-2.2.6-2-3.5 1.6-1.6v-1.8L3.7 9l2-3.5 2.2.6 1.5-.9L10 2zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6"
  }
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" ariaHidden=true><path d={shape} /></svg>
}

@react.component
let make = () => {
  let (people, setPeople) = React.useState(Storage.load)
  let (selectedId, setSelectedId) = React.useState(_ => "")
  let (newName, setNewName) = React.useState(_ => "")
  let (note, setNote) = React.useState(_ => "")
  let (category, setCategory) = React.useState(_ => "")
  let (categoryOpen, setCategoryOpen) = React.useState(_ => false)
  let (myMove, setMyMove) = React.useState(_ => None)
  let (interactionDate, setInteractionDate) = React.useState(today)
  let (myActionDate, setMyActionDate) = React.useState(_ => "")
  let (theirActionDate, setTheirActionDate) = React.useState(_ => "")
  let (actionDatesOpen, setActionDatesOpen) = React.useState(_ => false)
  let (actionDateError, setActionDateError) = React.useState(_ => "")
  let (calendarOpen, setCalendarOpen) = React.useState(_ => false)
  let (monthKey, setMonthKey) = React.useState(_ => today()->String.slice(~start=0, ~end=7))
  let (dateError, setDateError) = React.useState(_ => "")
  let (deleteTargetId, setDeleteTargetId) = React.useState(_ => "")
  let (editTargetId, setEditTargetId) = React.useState(_ => "")
  let (editName, setEditName) = React.useState(_ => "")
  let (backupOpen, setBackupOpen) = React.useState(_ => false)
  let (restorePreview, setRestorePreview) = React.useState(_ => None)
  let (restoreError, setRestoreError) = React.useState(_ => "")
  let (fileInputKey, setFileInputKey) = React.useState(_ => 0)
  let (showInfo, setShowInfo) = React.useState(_ => false)
  let (returnView, setReturnView) = React.useState(_ => "home")
  let (showDashboard, setShowDashboard) = React.useState(_ => true)
  let (showInsights, setShowInsights) = React.useState(_ => false)
  let (addOpen, setAddOpen) = React.useState(_ => false)
  let (mobileMenuOpen, setMobileMenuOpen) = React.useState(_ => false)
  let (sidebarCollapsed, setSidebarCollapsed) = React.useState(_ => false)
  let (sidebarSettingsOpen, setSidebarSettingsOpen) = React.useState(_ => false)
  let (searchQuery, setSearchQuery) = React.useState(_ => "")
  let (theme, setTheme) = React.useState(loadTheme)

  let commit = next => {
    Storage.save(next)
    setPeople(_ => next)
  }

  let selected = switch Belt.Array.getBy(people, person => person.id == selectedId) {
  | Some(person) => Some(person)
  | None => Belt.Array.get(people, 0)
  }
  let calendar = getCalendarMonth(monthKey)

  let openCalendar = () => {
    let date = switch interactionDate->normalizeDate->Nullable.toOption {
    | Some(date) => date
    | None => today()
    }
    setMonthKey(_ => date->String.slice(~start=0, ~end=7))
    setCalendarOpen(_ => true)
  }
  let chooseTheme = choice => {
    applyTheme(choice)
    setTheme(_ => choice)
  }

  let openHome = () => {
    setShowDashboard(_ => true)
    setShowInsights(_ => false)
    setShowInfo(_ => false)
    setMobileMenuOpen(_ => false)
    scrollTo(0, 0)
  }
  let openLedger = () => {
    setShowDashboard(_ => false)
    setShowInsights(_ => false)
    setShowInfo(_ => false)
    setMobileMenuOpen(_ => false)
    scrollTo(0, 0)
  }
  let openInsights = () => {
    setShowDashboard(_ => false)
    setShowInsights(_ => true)
    setShowInfo(_ => false)
    setMobileMenuOpen(_ => false)
    scrollTo(0, 0)
  }
  let leaveInfo = () => switch returnView {
  | "ledger" => openLedger()
  | "insights" => openInsights()
  | _ => openHome()
  }
  let openPerson = (person: State.person) => {
    setSelectedId(_ => person.id)
    setDeleteTargetId(_ => "")
    setEditTargetId(_ => "")
    setInteractionDate(_ => today())
    setMyActionDate(_ => "")
    setTheirActionDate(_ => "")
    setActionDatesOpen(_ => false)
    setActionDateError(_ => "")
    setMyMove(_ => None)
    setCategory(_ => "")
    setCategoryOpen(_ => false)
    setCalendarOpen(_ => false)
    setDateError(_ => "")
    openLedger()
  }

  let addPerson = event => {
    ReactEvent.Form.preventDefault(event)
    let name = newName->String.trim
    if name != "" {
      let person: State.person = {id: Storage.randomUUID(), name, entries: []}
      commit(Array.concat(people, [person]))
      setSelectedId(_ => person.id)
      setShowInfo(_ => false)
      setShowDashboard(_ => false)
      setShowInsights(_ => false)
      setAddOpen(_ => false)
      setNewName(_ => "")
      setMyActionDate(_ => "")
      setTheirActionDate(_ => "")
      setActionDatesOpen(_ => false)
      setActionDateError(_ => "")
      setCategory(_ => "")
      setCategoryOpen(_ => false)
    }
  }

  let log = (person: State.person, move) => {
    switch (myMove, interactionDate->normalizeDate->Nullable.toOption) {
    | (None, _) => ()
    | (_, None) => setDateError(_ => "Enter a real date as YYYY-MM-DD or eight digits, no later than today.")
    | (Some(mine), Some(date)) => {
        let myInput = myActionDate->String.trim
        let theirInput = theirActionDate->String.trim
        let mineDate = myInput == "" ? Some("") : myInput->normalizeDate->Nullable.toOption
        let theirsDate = theirInput == "" ? Some("") : theirInput->normalizeDate->Nullable.toOption
        switch (mineDate, theirsDate) {
        | (Some(myActionDate), Some(theirActionDate)) if (myActionDate == "" || myActionDate <= date) && (theirActionDate == "" || theirActionDate <= date) => {
            let entry: State.entry = {move, myMove: mine, note: note->String.trim, category, date, myActionDate, theirActionDate}
            commit(people->Array.map(item => item.id == person.id
              ? {...item, entries: Array.concat(item.entries, [entry])}
              : item))
            setNote(_ => "")
            setCategory(_ => "")
            setCategoryOpen(_ => false)
            setMyMove(_ => None)
            setInteractionDate(_ => today())
            setMyActionDate(_ => "")
            setTheirActionDate(_ => "")
            setActionDatesOpen(_ => false)
            setActionDateError(_ => "")
            setCalendarOpen(_ => false)
            setDateError(_ => "")
          }
        | _ => {
            setActionDatesOpen(_ => true)
            setActionDateError(_ => "Enter real action dates no later than the round completion date.")
          }
        }
      }
    }
  }

  let undo = (person: State.person) => {
    let length = Array.length(person.entries)
    if length > 0 {
      commit(people->Array.map(item => item.id == person.id
        ? {...item, entries: item.entries->Array.filterWithIndex((_, index) => index < length - 1)}
        : item))
    }
  }

  let remove = (person: State.person) => {
    commit(people->Array.filter(item => item.id != person.id))
    setSelectedId(_ => "")
    setDeleteTargetId(_ => "")
    setEditTargetId(_ => "")
  }

  let startEdit = (person: State.person) => {
    setSelectedId(_ => person.id)
    setShowInfo(_ => false)
    setShowDashboard(_ => false)
    setShowInsights(_ => false)
    setMobileMenuOpen(_ => false)
    setDeleteTargetId(_ => "")
    setEditName(_ => person.name)
    setEditTargetId(_ => person.id)
    scrollTo(0, 0)
  }

  let startDelete = (person: State.person) => {
    setSelectedId(_ => person.id)
    setShowInfo(_ => false)
    setShowDashboard(_ => false)
    setShowInsights(_ => false)
    setMobileMenuOpen(_ => false)
    setEditTargetId(_ => "")
    setDeleteTargetId(_ => person.id)
    scrollTo(0, 0)
  }

  let rename = event => {
    ReactEvent.Form.preventDefault(event)
    let name = editName->String.trim
    if name != "" {
      commit(people->Array.map(person => person.id == editTargetId ? {...person, name} : person))
      setEditTargetId(_ => "")
    }
  }

  let chooseBackup = event => {
    let files: array<backupFile> = JsxEvent.Form.target(event)["files"]
    setFileInputKey(previous => previous + 1)
    switch Belt.Array.get(files, 0) {
    | None => ()
    | Some(file) => {
        setRestoreError(_ => "")
        setRestorePreview(_ => None)
        file->readFile
        ->Promise.then(raw => {
          switch Storage.parseBackup(raw) {
          | Ok(restored) => setRestorePreview(_ => Some(restored))
          | Error(message) => setRestoreError(_ => message)
          }
          Promise.resolve(())
        })
        ->Promise.catch(_ => {
          setRestoreError(_ => "Could not read that file. Choose it again.")
          Promise.resolve(())
        })
        ->ignore
      }
    }
  }

  let restore = restored => {
    commit(restored)
    setSelectedId(_ => "")
    setDeleteTargetId(_ => "")
    setEditTargetId(_ => "")
    setNote(_ => "")
    setMyMove(_ => None)
    setCategory(_ => "")
    setCategoryOpen(_ => false)
    setInteractionDate(_ => today())
    setMyActionDate(_ => "")
    setTheirActionDate(_ => "")
    setActionDatesOpen(_ => false)
    setActionDateError(_ => "")
    setCalendarOpen(_ => false)
    setDateError(_ => "")
    setRestorePreview(_ => None)
    setBackupOpen(_ => false)
  }

  <div className={sidebarCollapsed ? "app-shell sidebar-collapsed" : "app-shell"}>
    <aside className={mobileMenuOpen ? "sidebar extras-open" : "sidebar"}>
      <div className="brand">
        <button type_="button" onClick={_ => openHome()}>{React.string("good faith")}</button>
        <button className="sidebar-collapse" type_="button" ariaLabel={sidebarCollapsed ? "Expand sidebar" : "Collapse sidebar"} ariaExpanded={!sidebarCollapsed} onClick={_ => setSidebarCollapsed(previous => !previous)}>{React.string(sidebarCollapsed ? "›" : "‹")}</button>
      </div>

      <div id="mobile-settings-panel" className="sidebar-main">
        <div className="mobile-settings-header"><h2>{React.string("Settings")}</h2><button type_="button" onClick={_ => setMobileMenuOpen(_ => false)}>{React.string("Close")}</button></div>
        <div className="sidebar-search">
          <label htmlFor="person-search">{React.string("Search people")}</label>
          <div className="sidebar-search-field"><span ariaHidden=true>{React.string("⌕")}</span><input id="person-search" type_="search" placeholder="Search people..." value={searchQuery} onChange={event => setSearchQuery(_ => JsxEvent.Form.target(event)["value"])} /></div>
          {searchQuery->String.trim != ""
            ? <div className="sidebar-search-results" ariaLabel="Search results">
                {people->Array.filter(person => person.name->String.toLowerCase->String.includes(searchQuery->String.trim->String.toLowerCase))->Array.map(person =>
                  <button key={person.id} type_="button" onClick={_ => {setSearchQuery(_ => ""); openPerson(person)}}>{React.string(person.name)}</button>
                )->React.array}
              </div>
            : React.null}
        </div>
        <nav className="primary-nav" ariaLabel="Main navigation">
          <button type_="button" title="People" className={showDashboard && !showInfo ? "active" : ""} onClick={_ => openHome()}><span className="sidebar-nav-icon" ariaHidden=true>{navIcon("people")}</span><span className="sidebar-nav-label">{React.string("People")}</span></button>
          <button type_="button" title="Ledger" className={!showDashboard && !showInsights && !showInfo ? "active" : ""} onClick={_ => openLedger()}><span className="sidebar-nav-icon" ariaHidden=true>{navIcon("ledger")}</span><span className="sidebar-nav-label">{React.string("Ledger")}</span></button>
          <button type_="button" title="Insights" className={showInsights ? "active" : ""} onClick={_ => openInsights()}><span className="sidebar-nav-icon" ariaHidden=true>{navIcon("insights")}</span><span className="sidebar-nav-label">{React.string("Insights")}</span></button>
        </nav>

        <section className="backup-tools" ariaLabel="Backup and restore">
          <button className="backup-toggle" title="Backup & restore" type_="button" ariaExpanded={backupOpen} onClick={_ => {setSidebarCollapsed(_ => false); setBackupOpen(previous => !previous)}}><span className="sidebar-nav-icon" ariaHidden=true>{navIcon("backup")}</span><span className="sidebar-nav-label">{React.string("Backup & restore")}</span></button>
          {backupOpen
            ? <div className="backup-body">
                <p>{React.string("Save a copy of your ledger, or restore one from a JSON file.")}</p>
                <button className="backup-download" type_="button" onClick={_ => download(Storage.backup(people))}>{React.string("Download backup")}</button>
                <label className="backup-file-label" htmlFor="backup-file">{React.string("Restore from file")}</label>
                <input key={Int.toString(fileInputKey)} id="backup-file" className="backup-file" type_="file" accept=".json,application/json" onChange={chooseBackup} />
                {restoreError != "" ? <p className="restore-error" role="alert">{React.string(restoreError)}</p> : React.null}
                {switch restorePreview {
                | None => React.null
                | Some(restored) => {
                    let interactions = restored->Array.reduce(0, (total, person) => total + Array.length(person.entries))
                    <div className="restore-preview">
                      <strong>{React.string(countLabel(Array.length(restored), "person", "people") ++ " · " ++ countLabel(interactions, "interaction", "interactions"))}</strong>
                      <p>{React.string("Restore this backup? It will replace your current ledger (" ++ countLabel(Array.length(people), "person", "people") ++ ").")}</p>
                      <div><button type_="button" onClick={_ => setRestorePreview(_ => None)}>{React.string("Keep current")}</button><button type_="button" className="restore-confirm" onClick={_ => restore(restored)}>{React.string("Replace ledger")}</button></div>
                    </div>
                  }
                }}
              </div>
            : React.null}
        </section>
        <button className="sidebar-settings-toggle" title="Settings" type_="button" ariaExpanded={sidebarSettingsOpen} onClick={_ => {setSidebarCollapsed(_ => false); setSidebarSettingsOpen(previous => !previous)}}><span className="sidebar-nav-icon" ariaHidden=true>{navIcon("settings")}</span><span className="sidebar-nav-label">{React.string("Settings")}</span></button>

        <form className="add-form" onSubmit={addPerson}>
          <label htmlFor="new-person">{React.string("Quick add")}</label>
          <div className="add-row">
            <input id="new-person" type_="text" placeholder="Their name" value={newName} maxLength=60 onChange={event => setNewName(_ => JsxEvent.Form.target(event)["value"])} />
            <button type_="submit" ariaLabel="Add person" disabled={newName->String.trim == ""}>{React.string("+")}</button>
          </div>
        </form>

        <button className="mobile-menu-toggle" type_="button" ariaExpanded={mobileMenuOpen} onClick={_ => setMobileMenuOpen(previous => !previous)}>{React.string("Settings & info")}</button>

        <div className={sidebarSettingsOpen ? "sidebar-settings-panel open" : "sidebar-settings-panel"}>
        <button className={showInfo ? "info-nav active" : "info-nav"} type_="button" onClick={_ => {if showInfo {leaveInfo()} else {setReturnView(_ => showDashboard ? "home" : showInsights ? "insights" : "ledger"); setShowInfo(_ => true); setShowDashboard(_ => false); setShowInsights(_ => false); setMobileMenuOpen(_ => false); setCalendarOpen(_ => false); scrollTo(0, 0)}}}>{React.string(showInfo ? "Back to tracker" : "How the method works")}</button>
        <section className="theme-tools" ariaLabel="Appearance">
          <p>{React.string("Appearance")}</p>
          <div className="theme-options" role="group" ariaLabel="Color theme">
            {["auto", "light", "dark"]->Array.map(choice => <button key={choice} type_="button" ariaPressed={theme == choice ? #"true" : #"false"} className={theme == choice ? "selected" : ""} onClick={_ => chooseTheme(choice)}>{React.string(choice->String.capitalize)}</button>)->React.array}
          </div>
        </section>
        </div>
        <div className="sidebar-quote"><p>{React.string("Patterns are worth noticing. People are more than patterns.")}</p></div>
      </div>
      <p className="sidebar-foot">{React.string("Private to this browser · No account needed")}</p>
    </aside>

    <main className="main-content">
      {addOpen
        ? <form className="quick-add-panel" onSubmit={addPerson} ariaLabel="Add a person">
            <label htmlFor="quick-add-name">{React.string("Add a person")}</label>
            <div><input id="quick-add-name" type_="text" placeholder="Their name" value={newName} maxLength=60 onChange={event => setNewName(_ => JsxEvent.Form.target(event)["value"])} />
              <button type_="submit" disabled={newName->String.trim == ""}>{React.string("Add person")}</button>
              <button type_="button" onClick={_ => setAddOpen(_ => false)}>{React.string("Cancel")}</button></div>
          </form>
        : React.null}
      {if showInfo {
        <div className="info-view"><button className="info-back" type_="button" onClick={_ => leaveInfo()}>{React.string("Back to tracker")}</button><Info /></div>
      } else if showInsights {
        <section className="insights-page">
          <h1>{React.string("Insights")}</h1>
          <p>{React.string("A compact view of what you recorded. The difference is their cumulative defections minus yours, not a relationship score.")}</p>
          <div className="insights-table-wrap"><table><thead><tr><th scope="col">{React.string("Person")}</th><th scope="col">{React.string("Interactions")}</th><th scope="col">{React.string("Difference")}</th><th scope="col">{React.string("CURE suggests")}</th></tr></thead><tbody>{people->Array.map(person => {
            let decision = State.next(person.entries)
            <tr key={person.id}><th scope="row"><button type_="button" onClick={_ => openPerson(person)}>{React.string(person.name)}</button></th><td>{React.string(Int.toString(Array.length(person.entries)))}</td><td>{React.string(Int.toString(decision.difference))}</td><td>{React.string(nextLabel(decision.move))}</td></tr>
          })->React.array}</tbody></table></div>
          {Array.length(people) == 0 ? <p>{React.string("Add a person to start seeing your record here.")}</p> : React.null}
        </section>
      } else if showDashboard {
        <Dashboard people onSelect={openPerson} onAdd={() => {setAddOpen(_ => true); scrollTo(0, 0)}} />
      } else {
      switch selected {
      | None =>
        <section className="empty-state">
          <h1>{React.string("Start with good faith.")}</h1>
          <p>{React.string("Add a person, then log what both of you did in each interaction. CURE compares your cumulative defections with theirs to suggest your next move.")}</p>
          <button type_="button" onClick={_ => {setAddOpen(_ => true); scrollTo(0, 0)}}>{React.string("Add your first person")}</button>
        </section>
      | Some(person) => {
          let decision = State.next(person.entries)
          let count = Array.length(person.entries)
          let history = person.entries->State.history->Belt.Array.reverse
          <div className="detail">
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
                  <div><strong>{React.string("Delete " ++ person.name ++ "?")}</strong><p>{React.string("Their interaction history will be removed from this browser permanently.")}</p></div>
                  <div className="delete-actions"><button type_="button" className="cancel-delete" onClick={_ => setDeleteTargetId(_ => "")}>{React.string("Keep person")}</button><button type_="button" className="confirm-delete" onClick={_ => remove(person)}>{React.string("Delete permanently")}</button></div>
                </section>
              : React.null}

            <section className={"decision-panel " ++ decisionClass(decision)} ariaLabel="Suggested next move">
              <div className="decision-copy">
                <h2>{React.string("CURE suggests")}</h2>
                <p className="decision-action">{React.string(decisionLabel(decision))}</p>
                <p>{React.string(decision.explanation)}</p>
              </div>
              <p className="decision-rule">{React.string(decision.rule)}</p>
            </section>

            <section className="record-section">
              <div className="record-intro"><h2>{React.string("What happened?")}</h2><p>{React.string("Only log an interaction when both people had a meaningful opportunity to cooperate or withhold cooperation.")}</p></div>
              <label className="note-label" htmlFor="interaction-date">{React.string("When was this round completed?")}</label>
              <p id="completion-date-help" className="date-help">{React.string("Use the date when both people had completed, missed, or otherwise resolved their part of this reciprocal round.")}</p>
              <div className="date-row">
                <div className="date-input-wrap">
                  <input id="interaction-date" className="date-input" type_="text" inputMode="numeric" placeholder="YYYY-MM-DD or YYYYMMDD" value={interactionDate} maxLength=10 ariaDescribedby="completion-date-help" onClick={_ => openCalendar()} onChange={event => {setInteractionDate(_ => JsxEvent.Form.target(event)["value"]); setCalendarOpen(_ => false); setDateError(_ => ""); setActionDateError(_ => "")}} />
                  <button className="calendar-toggle" type_="button" ariaLabel={calendarOpen ? "Close calendar" : "Open calendar"} ariaExpanded={calendarOpen} onClick={_ => calendarOpen ? setCalendarOpen(_ => false) : openCalendar()}><span className="calendar-glyph" ariaHidden=true></span></button>
                </div>
                <button type_="button" onClick={_ => {setInteractionDate(_ => today()); setCalendarOpen(_ => false); setDateError(_ => ""); setActionDateError(_ => "")}}>{React.string("Today")}</button>
                <button type_="button" onClick={_ => {setInteractionDate(_ => yesterday()); setCalendarOpen(_ => false); setDateError(_ => ""); setActionDateError(_ => "")}}>{React.string("Yesterday")}</button>
              </div>
              {calendarOpen
                ? <section className="calendar-panel" ariaLabel="Choose round completion date">
                    <div className="calendar-head">
                      <button type_="button" ariaLabel="Previous month" disabled={calendar.previousDisabled} onClick={_ => setMonthKey(_ => calendar.previous)}>{React.string("‹")}</button>
                      <strong>{React.string(calendar.title)}</strong>
                      <button type_="button" ariaLabel="Next month" disabled={calendar.nextDisabled} onClick={_ => setMonthKey(_ => calendar.next)}>{React.string("›")}</button>
                    </div>
                    <div className="calendar-grid">
                      {["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]->Array.map(day => <span key={day} className="calendar-weekday">{React.string(day)}</span>)->React.array}
                      {calendar.days->Array.mapWithIndex((day, index) => day.date == ""
                        ? <span key={Int.toString(index)} ariaHidden=true></span>
                        : <button key={day.date} type_="button" className={interactionDate == day.date ? "calendar-day selected" : "calendar-day"} ariaLabel={day.accessible} ariaPressed={interactionDate == day.date ? #"true" : #"false"} disabled={day.disabled} onClick={_ => {setInteractionDate(_ => day.date); setCalendarOpen(_ => false); setDateError(_ => ""); setActionDateError(_ => "")}}>{React.string(day.label)}</button>)->React.array}
                    </div>
                  </section>
                : React.null}
              {dateError != "" ? <p className="date-error" role="alert">{React.string(dateError)}</p> : React.null}
              <label className="note-label" htmlFor="entry-note">{React.string("A little context (optional)")}</label>
              <input id="entry-note" className="note-input" type_="text" placeholder="What was this interaction about?" value={note} maxLength=180 onChange={event => setNote(_ => JsxEvent.Form.target(event)["value"])} />
              <div className="action-dates-field">
                <button type_="button" className="action-dates-toggle" ariaExpanded={actionDatesOpen} ariaControls="action-dates" onClick={_ => setActionDatesOpen(previous => !previous)}>{React.string("Different action dates? Add them")}<span ariaHidden=true>{React.string(actionDatesOpen ? "−" : "+")}</span></button>
                {actionDatesOpen
                  ? <div id="action-dates" className="action-dates-inputs">
                      <div><label className="note-label" htmlFor="my-action-date">{React.string("Your action date (optional)")}</label><input id="my-action-date" className="date-input" type_="text" inputMode="numeric" placeholder="YYYY-MM-DD" value={myActionDate} maxLength=10 onChange={event => {setMyActionDate(_ => JsxEvent.Form.target(event)["value"]); setActionDateError(_ => "")}} /></div>
                      <div><label className="note-label" htmlFor="their-action-date">{React.string("Their action date (optional)")}</label><input id="their-action-date" className="date-input" type_="text" inputMode="numeric" placeholder="YYYY-MM-DD" value={theirActionDate} maxLength=10 onChange={event => {setTheirActionDate(_ => JsxEvent.Form.target(event)["value"]); setActionDateError(_ => "")}} /></div>
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
                <p className="note-label">{React.string("What did you do? (required for CURE)")}</p>
                <div className="own-move-options" role="group" ariaLabel="Your move in this interaction">
                  <button type_="button" ariaPressed={myMove == Some(State.Cooperate) ? #"true" : #"false"} className={myMove == Some(State.Cooperate) ? "selected" : ""} onClick={_ => setMyMove(_ => Some(State.Cooperate))}>{React.string("Cooperated")}</button>
                  <button type_="button" ariaPressed={myMove == Some(State.Defect) ? #"true" : #"false"} className={myMove == Some(State.Defect) ? "selected" : ""} onClick={_ => setMyMove(_ => Some(State.Defect))}>{React.string("Withheld")}</button>
                </div>
                {myMove == None ? <p className="own-move-hint">{React.string("Choose your move to enable the log buttons.")}</p> : React.null}
              </div>
              <div className="move-buttons">
                <button type_="button" className="move-button cooperate" disabled={myMove == None} onClick={_ => log(person, State.Cooperate)}>{React.string("They cooperated")}</button>
                <button type_="button" className="move-button defect" disabled={myMove == None} onClick={_ => log(person, State.Defect)}>{React.string("They defected")}</button>
              </div>
            </section>

            <section className="history-section">
              <div className="history-heading"><div><h2>{React.string("The pattern")}</h2><p>{React.string("Most recent first")}</p></div><button className="text-button" type_="button" disabled={count == 0} onClick={_ => undo(person)}>{React.string("Undo last entry")}</button></div>
              {count == 0
                ? <p className="history-empty">{React.string("No moves yet. Start with their next interaction.")}</p>
                : <ol className="history-list">{history->Array.mapWithIndex((item, index) => {
                    let entry = item.entry
                    let different = entry.myMove != item.recommended
                    let hasActionDates = entry.myActionDate != "" || entry.theirActionDate != ""
                    <li key={Int.toString(index)} className={moveClass(entry.move)}>
                      <span className="history-symbol">{React.string(entry.move == State.Cooperate ? "C" : "D")}</span>
                      <div>
                        <strong>{React.string("They " ++ State.label(entry.move)->String.toLowerCase)}</strong>{entry.category != "" ? <span className="history-category">{React.string(entry.category)}</span> : React.null}
                        <p className="history-moves">{React.string("CURE before: " ++ nextLabel(item.recommended) ++ " (difference " ++ Int.toString(item.differenceBefore) ++ ")")}{!hasActionDates ? <span className={different ? "actual-move diverged" : "actual-move"}>{React.string(" · You: " ++ nextLabel(entry.myMove) ++ (different ? " (different)" : ""))}</span> : React.null}</p>
                        {hasActionDates
                          ? <div className="history-action-dates">
                              <p>{React.string("You: " ++ (entry.myMove == State.Cooperate ? "Cooperated" : "Withheld cooperation") ++ (entry.myActionDate == "" ? "" : " · " ++ displayDate(entry.myActionDate)) ++ (different ? " (different from suggestion)" : ""))}</p>
                              <p>{React.string("Them: " ++ State.label(entry.move) ++ (entry.theirActionDate == "" ? "" : " · " ++ displayDate(entry.theirActionDate)))}</p>
                              <p>{React.string("Round completed: " ++ displayDate(entry.date))}</p>
                            </div>
                          : React.null}
                        {entry.note != "" ? <p>{React.string(entry.note)}</p> : React.null}
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
    <nav className="mobile-bottom-nav" ariaLabel="Mobile navigation">
      <button type_="button" className={showDashboard ? "active" : ""} onClick={_ => openHome()}>{React.string("Home")}</button>
      <button type_="button" className={!showDashboard && !showInsights && !showInfo ? "active" : ""} onClick={_ => openLedger()}>{React.string("Ledger")}</button>
      <button type_="button" className="mobile-add" ariaLabel="Add a person" onClick={_ => {setAddOpen(_ => true); setMobileMenuOpen(_ => false); scrollTo(0, 0)}}>{React.string("+")}</button>
      <button type_="button" className={showInsights ? "active" : ""} onClick={_ => openInsights()}>{React.string("Insights")}</button>
      <button type_="button" ariaExpanded={mobileMenuOpen} ariaControls="mobile-settings-panel" onClick={_ => setMobileMenuOpen(previous => !previous)}>{React.string("Settings")}</button>
    </nav>
  </div>
}
