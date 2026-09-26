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
      <h1>{React.string("A simple rule for a complicated thing.")}</h1>
      <p>{React.string("Good Faith now follows CURE (cumulative reciprocity), based on Li et al. (2022). It counts the running imbalance in cooperation across all recorded rounds and suggests a move for the next round. This is a decision aid you control, not a verdict about a person.")}</p>
    </header>

    <nav className="info-jump" ariaLabel="On this page">
      <a href="#when-to-use">{React.string("When it can help")}</a>
      <a href="#when-not-to-use">{React.string("When not to use it")}</a>
    </nav>

    <section className="info-section">
      <h2>{React.string("The game-theory idea")}</h2>
      <p>{React.string("CURE is a strategy for the repeated Prisoner’s Dilemma, a mathematical game where two players repeatedly choose cooperation (C) or defection (D). It keeps the full history’s imbalance in one running count instead of looking only at the latest round.")}</p>
    </section>

    <section className="info-section">
      <h2>{React.string("The exact rule in this app")}</h2>
      <p>{React.string("Before each round, d = their cumulative D count − your cumulative D count. With Δ = 1, cooperate (C) if d ≤ Δ; otherwise defect (D). A D by them when you chose C raises d by 1. A D by you when they chose C lowers d by 1. C/C and D/D leave d unchanged. The count never decays within a person's history, so earlier unequal defections continue to matter. The paper explores several thresholds; this app fixes Δ = 1, a common setting in its simulations. Its human-behavior comparison uses Δ = 3.")}</p>
      <div className="info-examples">
        <p><strong>{React.string("Their D while you C:")}</strong>{React.string(" d rises from 0 to 1. With Δ = 1, you still cooperate; if they keep defecting while you cooperate, d eventually exceeds 1 and the rule suggests D.")}</p>
        <p><strong>{React.string("Your D while they C:")}</strong>{React.string(" d falls by 1, reflecting that your defection puts the imbalance in your favor. This count is mechanical; it does not decide what is fair in a real situation.")}</p>
      </div>
      <p>{React.string("Record both moves from the same round; both are required for new entries. Backdated entries are replayed in date order, and the displayed history suggestion is recomputed from the recorded moves. CURE differs from CAPRI: CURE tracks cumulative imbalance across the history, while CAPRI classifies patterns in the last three rounds using five rules. ‘Defect’ in the game means choosing not to cooperate; in life it must never mean harm or revenge.")}</p>
    </section>

    <section className="info-section">
      <h2>{React.string("What the study found")}</h2>
      <p>{React.string("Li and colleagues used mathematical analysis and computer simulations to study CURE. They report that cumulative reciprocity can sustain cooperation despite errors, promote fair outcomes in the modeled games, and evolve in hostile environments. In an economic experiment, participants played a repeated game for small monetary stakes; CURE was more predictive of participants’ choices than several classical strategies. That result concerns behavior in that experiment, not how people should act in relationships.")}</p>
    </section>

    <section className="info-section">
      <h2>{React.string("Where the model stops")}</h2>
      <p>{React.string("CURE is an exact strategy for a simplified game with repeated choices and a clear C or D. Real interactions have context, unequal power, changing capacity, and unclear expectations. The study did not validate this rule for relationships, and a missed promise is not automatically a defection.")}</p>
      <p>{React.string("Use the log to notice patterns and slow down a decision. Talk, clarify, or leave a harmful situation when that fits the circumstances; the app cannot make those judgments for you.")}</p>
    </section>

    <section id="when-to-use" className="info-section scenario-section">
      <h2>{React.string("When this can help")}</h2>
      <p>{React.string("The best fit is one recurring, low-stakes agreement between people with similar freedom to choose. Both know what counts as keeping it, and stepping back from your own optional contribution would be safe and fair. These are examples for using a decision aid, not situations validated by the cited studies.")}</p>
      <p><strong>{React.string("Keep C and D in the same reciprocal domain.")}</strong>{React.string(" Do not combine unrelated exchanges in one ledger. For example, ‘Alex did not invite me to a party, so I will not cover their class’ mixes social invitations with work favors. A coherent ledger could follow work favors, shared household responsibilities, reciprocal commitments, or taking turns helping each other.")}</p>
      <ul className="scenario-list useful">{useful->Array.map(item => <li key={item.title}><strong>{React.string(item.title)}</strong><span>{React.string(item.detail)}</span></li>)->React.array}</ul>
    </section>

    <section id="when-not-to-use" className="info-section scenario-section info-limits">
      <h2>{React.string("When not to use it")}</h2>
      <p>{React.string("These situations make the two-choice model misleading, unfair, or unsafe. A suggested boundary is never an instruction to retaliate or to stay in danger.")}</p>
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
        <li><a href="https://www.nature.com/articles/s43588-022-00334-w" target="_blank" rel="noopener noreferrer">{React.string("Li et al. (2022), Evolution of cooperation through cumulative reciprocity")}</a><span>{React.string("The CURE strategy, mathematical and computational results, and economic experiment.")}</span></li>
      </ul>
    </section>
  </article>
