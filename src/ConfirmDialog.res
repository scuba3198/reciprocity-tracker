@send external showModal: 'a => unit = "showModal"
@send external addEventListener: ('a, string, 'b => unit) => unit = "addEventListener"
@send external removeEventListener: ('a, string, 'b => unit) => unit = "removeEventListener"
@send external preventDefault: 'a => unit = "preventDefault"
@send external focus: 'a => unit = "focus"
@get external isConnected: 'a => bool = "isConnected"
@scope("document") @val external activeElement: Dom.element = "activeElement"
@val external setTimeout: (unit => unit, int) => int = "setTimeout"

@react.component
let make = (~title, ~message, ~keepLabel, ~confirmLabel, ~onKeep, ~onConfirm) => {
  let dialog: ReactDOM.Ref.currentDomRef = React.useRef(Nullable.null)
  React.useEffect0(() => {
    switch dialog.current->Nullable.toOption {
    | Some(element) => {
        let previous = activeElement
        let cancel = event => {preventDefault(event); onKeep()}
        addEventListener(element, "cancel", cancel)
        showModal(element)
        Some(() => {
          removeEventListener(element, "cancel", cancel)
          setTimeout(() => {if isConnected(previous) {focus(previous)}}, 0)->ignore
        })
      }
    | None => None
    }
  })
  <dialog ref={ReactDOM.Ref.domRef(dialog)} className="confirm-dialog" ariaLabel={title}>
    <h2>{React.string(title)}</h2>
    {message != "" ? <p>{React.string(message)}</p> : React.null}
    <div className="confirm-dialog-actions">
      <button type_="button" autoFocus=true onClick={_ => onKeep()}>{React.string(keepLabel)}</button>
      <button type_="button" className="confirm-dialog-danger" onClick={_ => onConfirm()}>{React.string(confirmLabel)}</button>
    </div>
  </dialog>
}
