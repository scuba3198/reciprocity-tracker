%%raw(`import "./styles.css"`)
%%raw(`import "./dashboard.css"`)
%%raw(`import "./redesign.css"`)

switch ReactDOM.querySelector("#root") {
| Some(root) => ReactDOM.Client.createRoot(root)->ReactDOM.Client.Root.render(<App />)
| None => ()
}
