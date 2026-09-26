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
  {title: "Threats, abuse, or control", detail: "Violence, intimidation, stalking, coercion, isolation, and control of money or movement call for safety planning and support. Do not test a strategic response."},
  {title: "A serious first breach", detail: "Assault, theft, fraud, sexual boundary violations, and dangerous negligence may justify an immediate boundary or outside help. Do not reduce these events to a game move."},
  {title: "Consent and personal autonomy", detail: "A no, a changed mind, an ordinary delayed reply, or not sharing your feelings is not a defection. Nobody owes access to their body or affection."},
  {title: "Emergencies and basic needs", detail: "Do not withhold urgent medical help, food, shelter, safety assistance, or essential support to mirror someone else’s behavior."},
  {title: "Children or people in your care", detail: "Parenting, teaching, caregiving, and support for dependents come with responsibilities that do not switch off after a missed promise."},
  {title: "Unequal power", detail: "Boss and employee, teacher and student, landlord and tenant, or clinician and patient cannot always choose freely. A ‘matching’ response can be unfair or abusive."},
  {title: "High-stakes judgments", detail: "Never use a C/D log to decide hiring, firing, grading, housing, lending, insurance, immigration, legal outcomes, or healthcare."},
  {title: "Contracts, debts, and rights", detail: "Pay, rent, loans, custody, and formal services depend on agreements and rights. Use the proper process, not a game strategy."},
  {title: "One-off or anonymous encounters", detail: "The model needs repeated interaction and a shared expectation. A single encounter or a stranger’s silence provides neither."},
  {title: "Unclear or disputed expectations", detail: "If you never agreed on the task or deadline, or remember it differently, clarify first. A disappointment is not automatically a broken agreement."},
  {title: "Different capacity or resources", detail: "Illness, disability, caregiving, money, access, or exhaustion may change what someone can do. Revisit what is fair instead of assuming intent."},
  {title: "Accidents and missing information", detail: "Message failures, travel delays, time zones, and misunderstandings can look like a D. Check what happened before logging it."},
  {title: "Groups and institutions", detail: "A result caused by several people, a workplace system, or a platform cannot reliably be reduced to one person’s move."},
  {title: "Scorekeeping or testing loyalty", detail: "If the log is becoming a way to win arguments, provoke someone, or justify punishment, stop using the rule for that situation."},
  {title: "Sensitive records on shared devices", detail: "Names and notes are stored in this browser, and backup JSON is readable. Do not record details that could put someone at risk if seen."},
  {title: "Automatic trust after harm", detail: "A few cooperative moves do not prove safety or restore trust. You may need a different form of repair, a longer boundary, or no further contact."},
]

@react.component
let make = () =>
  <article className="info-page">
    <header className="info-header">
      <p className="context-label">{React.string("The thinking behind Good Faith")}</p>
      <h1>{React.string("A simple rule for a complicated thing.")}</h1>
      <p>{React.string("Good Faith now follows CAPRI, the five-rule strategy described by Murase and Baek in 2020. It uses what both people did in the last three rounds to suggest your next move. This is a decision aid you control, not a verdict about a person.")}</p>
    </header>

    <nav className="info-jump" ariaLabel="On this page">
      <a href="#when-to-use">{React.string("When it can help")}</a>
      <a href="#when-not-to-use">{React.string("When not to use it")}</a>
    </nav>

    <section className="info-section">
      <h2>{React.string("The game-theory idea")}</h2>
      <p>{React.string("The mathematical setting is the repeated Prisoner’s Dilemma. In each round, two players each choose cooperation (C) or defection (D). Defection can pay immediately, while continued mutual cooperation can be better for both than continued mutual defection.")}</p>
      <div className="payoff-example">
        <div><strong>{React.string("C + C")}</strong><span>{React.string("3 points each")}</span></div>
        <div><strong>{React.string("C + D")}</strong><span>{React.string("0 for C, 4 for D")}</span></div>
        <div><strong>{React.string("D + D")}</strong><span>{React.string("1 point each")}</span></div>
      </div>
      <p className="info-caption">{React.string("These are the illustrative payoffs in Murase and Baek’s Figure 2, not scores for real relationships. CAPRI is a ‘friendly rival’: it aims to maintain mutual cooperation while resisting repeated exploitation in the game model.")}</p>
    </section>

    <section className="info-section">
      <h2>{React.string("The exact rule in this app")}</h2>
      <p>{React.string("CAPRI reads three consecutive rounds of your C/D choices and their C/D choices. The app implements the 64 cases in Table 3 of the paper. It starts a new ledger by assuming an initial run of mutual cooperation (C/C, C/C, C/C), then replaces those assumed rounds as you record real ones.")}</p>
      <div className="info-table-wrap">
        <table className="info-table">
          <thead><tr><th scope="col">{React.string("Rule")}</th><th scope="col">{React.string("What it means")}</th><th scope="col">{React.string("Typical next move")}</th></tr></thead>
          <tbody>
            <tr><th scope="row">{React.string("C · Cooperate")}</th><td>{React.string("Continue when both have cooperated")}</td><td><strong>{React.string("C")}</strong></td></tr>
            <tr><th scope="row">{React.string("A · Accept")}</th><td>{React.string("If you broke mutual cooperation, accept their response")}</td><td><strong>{React.string("C")}</strong></td></tr>
            <tr><th scope="row">{React.string("P · Punish")}</th><td>{React.string("Answer their breach once, then return when they accept it")}</td><td><strong>{React.string("D, then C")}</strong></td></tr>
            <tr><th scope="row">{React.string("R · Recover")}</th><td>{React.string("Use a cooperative move to escape mutual defection")}</td><td><strong>{React.string("C")}</strong></td></tr>
            <tr><th scope="row">{React.string("I · Defect otherwise")}</th><td>{React.string("Protect yourself in all remaining patterns")}</td><td><strong>{React.string("D")}</strong></td></tr>
          </tbody>
        </table>
      </div>
      <div className="info-examples">
        <p><strong>{React.string("Their single D:")}</strong>{React.string(" From mutual cooperation, their D makes CAPRI suggest D once. If they accept that response by cooperating, CAPRI returns to C.")}</p>
        <p><strong>{React.string("Your single D:")}</strong>{React.string(" From mutual cooperation, your D makes CAPRI suggest C next: accept their response and help restore cooperation.")}</p>
      </div>
      <p>{React.string("Record both moves from the same round; both are required for new entries. Backdated entries are replayed in date order. History recomputes what CAPRI would have suggested before each round; it does not preserve advice from the old app. Older entries without your move stay visible, but CAPRI cannot infer it. After such a gap, the app waits for three complete paired rounds before giving another exact suggestion. ‘Withhold cooperation’ means an appropriate boundary, not harm or revenge.")}</p>
    </section>

    <section className="info-section">
      <h2>{React.string("Why remember three rounds?")}</h2>
      <p>{React.string("Murase and Baek searched deterministic strategies that could sustain cooperation with small accidental errors while avoiding a worse long-run game payoff than an opponent. CAPRI uses three rounds to distinguish a breach, a response to that breach, and a path back to cooperation. A simpler one-round copycat rule cannot make those distinctions.")}</p>
      <p>{React.string("The paper tests CAPRI in mathematical and evolutionary simulations, including errors in carrying out moves. It does not test this app on real relationships. The exact Table 3 strategy depends on complete, correctly ordered rounds; real interactions are much less tidy.")}</p>
    </section>

    <section className="info-section">
      <h2>{React.string("Where the model stops")}</h2>
      <p>{React.string("A game round has fixed rules, known payoffs, and a clean C or D. Human interactions rarely do. Someone may be unable to help, may understand an agreement differently, or may have made a harmless error. A missed promise and a serious violation should not receive the same automatic response just because both fit the letter D.")}</p>
      <p>{React.string("The paper’s results are about repeated games, not a universal best way to treat people. Use the log to notice patterns and slow down a decision. Talk, clarify, or leave a harmful situation when that fits the circumstances; the app cannot make those judgments for you.")}</p>
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
      <p>{React.string("These situations make the two-choice model misleading, unfair, or unsafe. CAPRI’s suggested boundary is never an instruction to retaliate or to stay in danger.")}</p>
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
        <li><a href="https://doi.org/10.1038/s41598-020-73855-x" target="_blank" rel="noopener noreferrer">{React.string("Murase & Baek (2020), Five rules for friendly rivalry in direct reciprocity")}</a><span>{React.string("The CAPRI rules, full action table (Table 3), and simulation results.")}</span></li>
      </ul>
    </section>
  </article>
