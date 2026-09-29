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
      <p>{React.string("Before each round, d = their cumulative D count − your cumulative D count. Cooperate (C) if d ≤ your chosen tolerance Δ; otherwise defect (D). Choose Δ = 1, 2, or 3 in Settings. A D by them when you chose C raises d by 1; a D by you when they chose C lowers d by 1. C/C and D/D leave d unchanged. In this app's real-world adaptation, Request, Unable, and No action add no defection. A Requested/Unable round leaves d unchanged. Their D raises d by 1 and your D lowers it by 1 regardless of the other person's neutral status. Cooperation earns no CURE credit: this is defection imbalance, not a score of good deeds. The count never decays within a person's history, so earlier unequal defections continue to matter. Good Faith defaults to Δ = 3 because Li et al. used it for CURE in their human-behavior comparison; it is the closest app default to the version in that experiment. The paper explores other thresholds and does not establish Δ = 3 as universally optimal for real-world relationships.")}</p>
      <div className="info-examples">
        <p><strong>{React.string("Their D while you C:")}</strong>{React.string(" d rises from 0 to 1. With the default Δ = 3, you continue cooperating through d = 3; if they keep defecting while you cooperate, the rule suggests D once d exceeds 3.")}</p>
        <p><strong>{React.string("Your D while they C:")}</strong>{React.string(" d falls by 1, reflecting that your defection puts the imbalance in your favor. This count is mechanical; it does not decide what is fair in a real situation.")}</p>
      </div>
      <p>{React.string("Each saved round classifies both people and needs at least one Cooperated or Defected status, or a Requested/Unable pair. No action means nothing was required or done by that person; it can pair with cooperation or defection when only one person acted. Request means someone asked for help, a favor, or cooperation. Unable means circumstances outside that person's reasonable control prevented help; illness, unavailability, insufficient resources, or a genuine conflicting obligation can qualify. All three are neutral and add no defection. No action/No action, Request/Request, and Unable/Unable cannot be confirmed. Optional action dates do not add rounds or change the calculation. The completion date orders the round in history, and backdated entries are replayed by that date. A D means withholding cooperation when there was a meaningful, safe choice under a clear expectation. In real life, defection must never mean harm or revenge. CURE differs from CAPRI: CURE tracks cumulative imbalance across the history, while CAPRI classifies patterns in the last three rounds using five rules.")}</p>
      <p><strong>{React.string("Dishwashing agreement:")}</strong>{React.string(" “I wash on Sunday and my roommate washes on Wednesday.” If I wash Sunday and they wash Wednesday, record one C/C round completed on Wednesday. Optionally record Sunday as my action date and Wednesday as their action date. If both actions happen on one day, the completion date is enough.")}</p>
      <p><strong>{React.string("A favor or request:")}</strong>{React.string(" If someone helps without being asked, record your No action and their Cooperated. If you ask someone for help, record your Request. If they were genuinely unable to help, record their Unable and confirm the pair. These neutral statuses do not change CURE's balance. If they cooperated or defected instead, record that response. A request by itself creates no obligation; keep an unanswered request as a draft.")}</p>
    </section>

    <section className="info-section">
      <h2>{React.string("One person, selective entries")}</h2>
      <p>{React.string("CURE tracks the cumulative imbalance across interactions with an opponent. The researchers also describe it as capturing a general sense of fairness in close relationships rather than an itemized account of every favor. Good Faith therefore keeps one ledger per person. Optional categories organize entries and do not change CURE's count d.")}</p>
      <p>{React.string("Only record a relevant action in a reciprocal relationship with a clear expectation. Request records that someone asked for help, a favor, or cooperation; Unable records genuine inability to help. Both are neutral and add no defection. The model gives each logged D the same weight, but real events are not equal: a forgotten text, an unbought coffee, a serious broken promise, and abandonment in an emergency should not be entered as four interchangeable D's. Handle serious harm and emergencies directly, outside this rule.")}</p>
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

    <section className="info-section">
      <h2>{React.string("Think Ahead is a separate decision tool")}</h2>
      <p>{React.string("Use Think Ahead for a one-off or sequential decision with important future consequences. Backward induction means asking whether someone would still have a reason to take a future action when that moment arrives. Expected utility combines each choice’s immediate value with possible consequences, weighted by rough likelihood. The qualitative labels are your approximate judgments, not objective probabilities. Close scores can reverse if your assumptions change. Think Ahead does not log rounds or change CURE's difference, tolerance, or historical advice. Use CURE for repeated reciprocal interactions with the same person.")}</p>
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
