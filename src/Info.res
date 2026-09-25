@react.component
let make = () =>
  <article className="info-page">
    <header className="info-header">
      <p className="context-label">{React.string("The thinking behind Good Faith")}</p>
      <h1>{React.string("A simple rule for a complicated thing.")}</h1>
      <p>{React.string("Good Faith turns a pattern of repeated interactions into a suggested next move. It begins with cooperation, allows one mistake, responds to a repeated breach, and leaves a way back. The rule is a decision aid you control—not a verdict about a person.")}</p>
    </header>

    <section className="info-section">
      <h2>{React.string("The game-theory idea")}</h2>
      <p>{React.string("The mathematical starting point is the repeated Prisoner’s Dilemma. In each round, two players choose to cooperate (C) or defect (D). In the usual setup, defection can reward one player immediately, yet repeated mutual cooperation leaves both better off than repeated mutual defection.")}</p>
      <div className="payoff-example">
        <div><strong>{React.string("C + C")}</strong><span>{React.string("3 points each")}</span></div>
        <div><strong>{React.string("C + D")}</strong><span>{React.string("0 for C, 5 for D")}</span></div>
        <div><strong>{React.string("D + D")}</strong><span>{React.string("1 point each")}</span></div>
      </div>
      <p className="info-caption">{React.string("These are the illustrative payoffs used in Axelrod’s tournament, not scores for real relationships. What matters is the tradeoff: a tempting short-term gain can damage a valuable ongoing exchange.")}</p>
      <p>{React.string("Robert Axelrod and William Hamilton showed how a reciprocal strategy could sustain cooperation in their computer-tournament and evolutionary model. Classic tit-for-tat starts with C, then copies the other player’s previous move. Its appeal is clarity: cooperation is met with cooperation; defection has a consequence.")}</p>
    </section>

    <section className="info-section">
      <h2>{React.string("The exact rule in this app")}</h2>
      <p>{React.string("This app uses a small state machine: four states, two possible observations, and one next-move suggestion. Log what the other person did. Good Faith reads their interactions in date order and updates the state. The last column shows the suggestion in the current state; the middle columns show how their next move changes it.")}</p>
      <div className="info-table-wrap">
        <table className="info-table">
          <thead><tr><th scope="col">{React.string("Current state")}</th><th scope="col">{React.string("If they cooperate")}</th><th scope="col">{React.string("If they defect")}</th><th scope="col">{React.string("Suggested move now")}</th></tr></thead>
          <tbody>
            <tr><th scope="row">{React.string("In good standing")}</th><td>{React.string("Stay in good standing")}</td><td>{React.string("Give one chance")}</td><td><strong>{React.string("Cooperate")}</strong></td></tr>
            <tr><th scope="row">{React.string("One chance given")}</th><td>{React.string("One clean move; trust is rebuilding")}</td><td>{React.string("Hold your boundary")}</td><td><strong>{React.string("Cooperate")}</strong></td></tr>
            <tr><th scope="row">{React.string("Trust rebuilding")}</th><td>{React.string("Second clean move; reset")}</td><td>{React.string("Hold your boundary")}</td><td><strong>{React.string("Cooperate")}</strong></td></tr>
            <tr><th scope="row">{React.string("Hold your boundary")}</th><td>{React.string("Resume cooperation; one clean move")}</td><td>{React.string("Keep the boundary")}</td><td><strong>{React.string("Withhold cooperation")}</strong></td></tr>
          </tbody>
        </table>
      </div>
      <div className="info-examples">
        <p><strong>{React.string("One slip:")}</strong>{React.string(" D → C → C clears the strike. The next move stays C throughout.")}</p>
        <p><strong>{React.string("A repeated breach:")}</strong>{React.string(" D → C → D makes your next move D. Keep D while they keep defecting. When they cooperate, return to C; one more clean C resets trust.")}</p>
      </div>
      <p>{React.string("The app records their moves, not your actions. Its recommendation assumes you follow the suggested move. “Withhold cooperation” means choosing an appropriate boundary; the model does not decide what that boundary should be.")}</p>
    </section>

    <section className="info-section">
      <h2>{React.string("Why forgive, and why remember?")}</h2>
      <p>{React.string("Strict tit-for-tat answers every D with D. That can turn one mistake or misunderstanding into a cycle of retaliation. Later mathematical work explored more generous strategies that sometimes forgive a defection, especially when actions can be misread or go wrong by accident. In a laboratory study with noisy repeated games, successful strategies in settings where cooperation was sustainable were often lenient about a first defection and quick to return to cooperation after punishment.")}</p>
      <p>{React.string("Good Faith makes that idea deterministic: forgive the first D, require two clean C moves to erase it, and respond to another D before the reset. The one-strike allowance and two-move reset are design choices for this app. They are not constants established by those studies, and this exact state machine has not been tested as a named strategy in them.")}</p>
    </section>

    <section className="info-section info-limits">
      <h2>{React.string("Where the model stops")}</h2>
      <p>{React.string("A game round has fixed rules, known payoffs, and a clean C or D. Human interactions rarely do. Someone may be unable to help, may understand an agreement differently, or may have made a harmless error. A missed promise and a serious violation should not receive the same automatic response just because both fit the letter D.")}</p>
      <p>{React.string("Research also does not show one universal best strategy: results change with the payoffs, the other strategies present, and how success is measured. Use the log to notice patterns and slow down a decision. Talk, clarify, or leave a harmful situation when that fits the circumstances; the app cannot make those judgments for you.")}</p>
    </section>

    <section className="info-sources" ariaLabel="Research sources">
      <h2>{React.string("Read the research")}</h2>
      <ul>
        <li><a href="https://pubmed.ncbi.nlm.nih.gov/7466396/" target="_blank" rel="noopener noreferrer">{React.string("Axelrod & Hamilton (1981), The Evolution of Cooperation")}</a><span>{React.string("Repeated-game model and reciprocity in computer tournaments.")}</span></li>
        <li><a href="https://www.nature.com/articles/355250a0" target="_blank" rel="noopener noreferrer">{React.string("Nowak & Sigmund (1992), Tit for tat in heterogeneous populations")}</a><span>{React.string("Mathematical work on the emergence of more generous reciprocity.")}</span></li>
        <li><a href="https://www.aeaweb.org/articles?id=10.1257/aer.102.2.720" target="_blank" rel="noopener noreferrer">{React.string("Fudenberg, Rand & Dreber (2012), Slow to Anger and Fast to Forgive")}</a><span>{React.string("Laboratory evidence on leniency and forgiveness in noisy repeated games.")}</span></li>
        <li><a href="https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0134128" target="_blank" rel="noopener noreferrer">{React.string("Rapoport, Seale & Colman (2015), Is Tit-for-Tat the Answer?")}</a><span>{React.string("A reanalysis showing why tournament success depends on its setup.")}</span></li>
      </ul>
    </section>
  </article>
