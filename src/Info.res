@react.component
let make = () =>
  <article className="info-page">
    <header className="info-header">
      <h1>{React.string("A simple rule for a complicated thing.")}</h1>
      <p>{React.string("Good Faith uses an app-level asynchronous adaptation of CURE (cumulative reciprocity), the strategy studied by Li et al. (2022). The paper defines choices in repeated game rounds; this app's use of separate action dates for real-world events is our adaptation, not a method from or validated by Li et al. It tracks a running imbalance across recorded rounds and suggests a move. This is a decision aid you control, not a verdict about a person.")}</p>
    </header>

    <section className="info-section">
      <h2>{React.string("The game-theory idea")}</h2>
      <p>{React.string("CURE is a strategy for the repeated Prisoner’s Dilemma, a mathematical game where two players repeatedly choose cooperation (C) or defection (D). It keeps the full history’s imbalance in one running count instead of looking only at the latest round.")}</p>
    </section>

    <section className="info-section">
      <h2>{React.string("The exact rule in this app")}</h2>
      <p>{React.string("Before each round, d = their cumulative D count − your cumulative D count. Cooperate (C) if d ≤ your chosen tolerance Δ; otherwise defect (D). Choose Δ = 1 or 2 in Settings; 2 is the default. A D by them when you chose C raises d by 1; a D by you when they chose C lowers d by 1. C/C and D/D leave d unchanged. In this app's real-world adaptation, Request, Unable, and legacy No action add no defection. A Requested/Unable round leaves d unchanged. Their D raises d by 1 and your D lowers it by 1 regardless of the other person's neutral status. Cooperation earns no CURE credit: this is defection imbalance, not a score of good deeds. The count never decays within a person's history, so earlier unequal defections continue to matter. The paper explores other thresholds and its human-behavior comparison uses Δ = 3. No threshold is established as optimal for human relationships.")}</p>
      <div className="info-examples">
        <p><strong>{React.string("Their D while you C:")}</strong>{React.string(" d rises from 0 to 1. With the default Δ = 2, you still cooperate; if they keep defecting while you cooperate, d eventually exceeds 2 and the rule suggests D.")}</p>
        <p><strong>{React.string("Your D while they C:")}</strong>{React.string(" d falls by 1, reflecting that your defection puts the imbalance in your favor. This count is mechanical; it does not decide what is fair in a real situation.")}</p>
      </div>
      <p>{React.string("Each saved round classifies both people and needs at least one Cooperated or Defected status, or a Requested/Unable pair. Request means someone asked for help, a favor, or cooperation. Unable means circumstances outside that person's reasonable control prevented help; illness, unavailability, insufficient resources, or a genuine conflicting obligation can qualify. Both are neutral and add no defection. Request/Request and Unable/Unable cannot be confirmed. Older saved ‘No action’ entries retain their distinct meaning: that person had no relevant action. They are never silently relabeled. Optional action dates do not add rounds or change the calculation. The completion date orders the round in history, and backdated entries are replayed by that date. A D means withholding cooperation when there was a meaningful, safe choice under a clear expectation. In real life, defection must never mean harm or revenge. CURE differs from CAPRI: CURE tracks cumulative imbalance across the history, while CAPRI classifies patterns in the last three rounds using five rules.")}</p>
      <p><strong>{React.string("Dishwashing agreement:")}</strong>{React.string(" “I wash on Sunday and my roommate washes on Wednesday.” If I wash Sunday and they wash Wednesday, record one C/C round completed on Wednesday. Optionally record Sunday as my action date and Wednesday as their action date. If both actions happen on one day, the completion date is enough.")}</p>
      <p><strong>{React.string("A favor or request:")}</strong>{React.string(" If you ask someone for help, record your Request. If they were genuinely unable to help, record their Unable and confirm the pair. Neither status changes CURE's balance. If they cooperated or defected instead, record that response. A request by itself creates no obligation; keep an unanswered request as a draft.")}</p>
    </section>

    <section className="info-section">
      <h2>{React.string("One person, selective entries")}</h2>
      <p>{React.string("CURE tracks the cumulative imbalance across interactions with an opponent. The researchers also describe it as capturing a general sense of fairness in close relationships rather than an itemized account of every favor. Good Faith therefore keeps one ledger per person. Optional categories organize entries and do not change CURE's count d.")}</p>
      <p>{React.string("Only record a relevant action in a reciprocal relationship with a clear expectation. Request records that someone asked for help, a favor, or cooperation; Unable records genuine inability to help. Both are neutral and add no defection. Legacy No action entries remain distinct and mean that person had no relevant action. The model gives each logged D the same weight, but real events are not equal: a forgotten text, an unbought coffee, a serious broken promise, and abandonment in an emergency should not be entered as four interchangeable D's. Handle serious harm and emergencies directly, outside this rule.")}</p>
      <p>{React.string("A separate 2025 study found that behavior can spill between concurrent games, and that such links can also reduce cooperation. It does not test CURE as relationship advice or show that every kind of real-life event belongs in one binary count.")}</p>
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

    <section className="info-sources" ariaLabel="Research sources">
      <h2>{React.string("Read the research")}</h2>
      <ul>
        <li><a href="https://www.nature.com/articles/s43588-022-00334-w" target="_blank" rel="noopener noreferrer">{React.string("Li et al. (2022), Evolution of cooperation through cumulative reciprocity")}</a><span>{React.string("The CURE strategy, mathematical and computational results, and economic experiment.")}</span></li>
        <li><a href="https://www.evolbio.mpg.de/3619529/news_publication_19411039_transferred" target="_blank" rel="noopener noreferrer">{React.string("Max Planck Institute, CURE research summary")}</a><span>{React.string("The researchers' description of cumulative reciprocity and an overall sense of fairness.")}</span></li>
        <li><a href="https://www.nature.com/articles/s41467-025-56083-7" target="_blank" rel="noopener noreferrer">{React.string("Nature Communications (2025), concurrent games study")}</a><span>{React.string("Cross-game effects in a separate study; not a validation of CURE for relationships.")}</span></li>
      </ul>
    </section>
  </article>
