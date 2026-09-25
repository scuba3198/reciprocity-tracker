type scenario = {title: string, detail: string}

let useful: array<scenario> = [
  {title: "Roommates and housemates", detail: "A shared chore rota, quiet hours, or another specific household promise comes up repeatedly. Clarify a missed turn before counting it."},
  {title: "Neighbors", detail: "You take turns with bins, watering plants, or small optional favors under an agreement both people understand."},
  {title: "Adult family coordination", detail: "Relatives share low-stakes planning or errands by mutual agreement. Essential care and family obligations need different judgment."},
  {title: "Friends and recurring plans", detail: "You agreed to alternate driving, hosting, organizing, or showing up. A pattern may matter more than one cancellation."},
  {title: "Small favors and borrowing", detail: "You trade routine help or lend low-value items with clear terms, and either person can freely decline next time."},
  {title: "Study partners", detail: "Peers take turns preparing material or attending planned sessions, without using the log to decide grades or access."},
  {title: "Peer projects", detail: "Equal collaborators share noncritical tasks or handoffs. Track the agreed task, not a teammate’s overall worth."},
  {title: "Clubs and volunteers", detail: "Members share nonessential shifts, event preparation, or routine organizing and can safely step back."},
  {title: "Creative collaborators", detail: "Band practice, writing groups, and hobby projects have recurring, clear contributions that can be discussed when missed."},
  {title: "Known online collaborators", detail: "A small community shares hobby project work under explicit rules. Silence from a stranger is not a broken promise."},
  {title: "Optional time and effort", detail: "You are deciding whether to keep offering nonessential help after a specific reciprocal promise is repeatedly missed."},
  {title: "Repair after a small lapse", detail: "You can note whether later commitments were kept after a low-stakes mistake, while deciding for yourself what repair requires."},
  {title: "Everyday dating logistics", detail: "Only mutually agreed, low-stakes plans or practical tasks fit. Attention, affection, intimacy, and sex are never owed."},
]

let unsuitable: array<scenario> = [
  {title: "Threats, abuse, or control", detail: "Violence, intimidation, stalking, coercion, isolation, and control of money or movement call for safety planning and support. Do not wait for a second strike or test a response."},
  {title: "A serious first breach", detail: "Assault, theft, fraud, sexual boundary violations, and dangerous negligence may justify an immediate boundary or outside help. You do not owe one automatic pass."},
  {title: "Consent and personal autonomy", detail: "A no, a changed mind, an ordinary delayed reply, or not sharing your feelings is not a defection. Nobody owes access to their body or affection."},
  {title: "Emergencies and basic needs", detail: "Do not withhold urgent medical help, food, shelter, safety assistance, or essential support to mirror someone else’s behavior."},
  {title: "Children or people in your care", detail: "Parenting, teaching, caregiving, and support for dependents come with responsibilities that do not switch off after a missed promise."},
  {title: "Unequal power", detail: "Boss and employee, teacher and student, landlord and tenant, or clinician and patient cannot always choose freely. A ‘matching’ response can be unfair or abusive."},
  {title: "High-stakes judgments", detail: "Never use a C/D log to decide hiring, firing, grading, housing, lending, insurance, immigration, legal outcomes, or healthcare."},
  {title: "Contracts, debts, and rights", detail: "Pay, rent, loans, custody, and formal services depend on agreements and rights. Use the proper process, not a two-strike rule."},
  {title: "One-off or anonymous encounters", detail: "The model needs repeated interaction and a shared expectation. A single encounter or a stranger’s silence provides neither."},
  {title: "Unclear or disputed expectations", detail: "If you never agreed on the task or deadline, or remember it differently, clarify first. A disappointment is not automatically a broken agreement."},
  {title: "Different capacity or resources", detail: "Illness, disability, caregiving, money, access, or exhaustion may change what someone can do. Revisit what is fair instead of assuming intent."},
  {title: "Accidents and missing information", detail: "Message failures, travel delays, time zones, and misunderstandings can look like a D. Check what happened before logging it."},
  {title: "Groups and institutions", detail: "A result caused by several people, a workplace system, or a platform cannot reliably be reduced to one person’s move."},
  {title: "Scorekeeping or testing loyalty", detail: "If the log is becoming a way to win arguments, provoke someone, or justify punishment, stop using the rule for that situation."},
  {title: "Sensitive records on shared devices", detail: "Names and notes are stored in this browser, and backup JSON is readable. Do not record details that could put someone at risk if seen."},
  {title: "Automatic trust after harm", detail: "Two cooperative moves do not prove safety or restore trust. You may need a different form of repair, a longer boundary, or no further contact."},
]

@react.component
let make = () =>
  <article className="info-page">
    <header className="info-header">
      <p className="context-label">{React.string("The thinking behind Good Faith")}</p>
      <h1>{React.string("A simple rule for a complicated thing.")}</h1>
      <p>{React.string("Good Faith turns a pattern of repeated interactions into a suggested next move. It begins with cooperation, allows one mistake, responds to a repeated breach, and leaves a way back. The rule is a decision aid you control—not a verdict about a person.")}</p>
    </header>

    <nav className="info-jump" ariaLabel="On this page">
      <a href="#when-to-use">{React.string("When it can help")}</a>
      <a href="#when-not-to-use">{React.string("When not to use it")}</a>
    </nav>

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

    <section className="info-section">
      <h2>{React.string("Where the model stops")}</h2>
      <p>{React.string("A game round has fixed rules, known payoffs, and a clean C or D. Human interactions rarely do. Someone may be unable to help, may understand an agreement differently, or may have made a harmless error. A missed promise and a serious violation should not receive the same automatic response just because both fit the letter D.")}</p>
      <p>{React.string("Research also does not show one universal best strategy: results change with the payoffs, the other strategies present, and how success is measured. Use the log to notice patterns and slow down a decision. Talk, clarify, or leave a harmful situation when that fits the circumstances; the app cannot make those judgments for you.")}</p>
    </section>

    <section id="when-to-use" className="info-section scenario-section">
      <p className="context-label">{React.string("Practical examples")}</p>
      <h2>{React.string("When this can help")}</h2>
      <p>{React.string("The best fit is one recurring, low-stakes agreement between people with similar freedom to choose. Both know what counts as keeping it, and stepping back from your own optional contribution would be safe and fair. These are examples for using a decision aid, not situations validated by the cited studies.")}</p>
      <ul className="scenario-list useful">{useful->Array.map(item => <li key={item.title}><strong>{React.string(item.title)}</strong><span>{React.string(item.detail)}</span></li>)->React.array}</ul>
    </section>

    <section id="when-not-to-use" className="info-section scenario-section info-limits">
      <p className="context-label">{React.string("Hard limits")}</p>
      <h2>{React.string("When not to use it")}</h2>
      <p>{React.string("These situations make the two-choice model misleading, unfair, or unsafe. The app’s first-strike forgiveness is never an obligation, and its suggested boundary is never an instruction to retaliate.")}</p>
      <ul className="scenario-list unsuitable">{unsuitable->Array.map(item => <li key={item.title}><strong>{React.string(item.title)}</strong><span>{React.string(item.detail)}</span></li>)->React.array}</ul>
      <div className="scenario-check">
        <h3>{React.string("Before you log a D")}</h3>
        <p>{React.string("Ask: Was there a specific mutual agreement? Could they reasonably meet it? Am I judging that one agreement rather than their character? Would stepping back from my optional contribution be safe and proportionate? If any answer is unclear, talk or gather context before reducing the event to C or D.")}</p>
      </div>
      <p className="scenario-safety">{React.string("If you feel unsafe, seek help from someone you trust or a local specialist service. For safety guidance, see the ")}<a href="https://www.who.int/news-room/fact-sheets/detail/violence-against-women" target="_blank" rel="noopener noreferrer">{React.string("World Health Organization")}</a>{React.string(" and the ")}<a href="https://www.thehotline.org/plan-for-safety/" target="_blank" rel="noopener noreferrer">{React.string("National Domestic Violence Hotline")}</a>{React.string(" (US).")}</p>
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
