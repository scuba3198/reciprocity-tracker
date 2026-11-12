// Help-dialog text, keyed by topic. Each entry: t = title, p = paragraphs, m = muted notes.
export const HELP = {
  overview: {
    t: 'How this works',
    p: [
      'This implements cumulative reciprocity (CURE) from Li, Zhao, Li, Rossetti, Hilbe & Xia, "Evolution of cooperation through cumulative reciprocity", Nature Computational Science 2, 677–686 (2022).',
      'The paper studies a repeated prisoner\'s dilemma in which each player either cooperates or defects. Here, granting a request is cooperating and refusing it is defecting. The paper names friends exchanging favours as one of the situations this game approximates, and likens CURE to keeping a loose record of favours that need to be repaid.',
      'For each person you keep two counts: how often they have defected against you (n_B) and how often you have defected against them (n_A). What matters is the difference, d = n_B − n_A, which the paper calls the defection difference statistic.',
      'The rule: when they ask you for something, cooperate if d ≤ Δ and defect if d > Δ. Δ is your tolerance for that person.',
      'Only defections are counted; cooperation changes nothing. Every defection counts as exactly 1, whatever the reason, and nothing is ever reset. The count covers your whole history with that person. That is what separates CURE from strategies like tit-for-tat that only look at the last move.'
    ],
    m: [
      'The paper notes such bookkeeping may be rare among close friends but can play an important role in the early stages of a relationship, when mutual trust has not been established.',
      'Data stays in this browser. Export saves a JSON file you can import later or on another device.'
    ]
  },
  tolerance: {
    t: 'Tolerance (Δ)',
    p: [
      'Δ is how far ahead in defections the other person can get while you keep cooperating. You cooperate while d ≤ Δ and defect once d > Δ.',
      'Δ = 0 means they must defect no more often than you do. Δ = 1 absorbs one extra defection from them; the second switches you to defecting. Each step up is more lenient.',
      'The trade-off, from the paper: when two people both play this way and mistakes happen, higher tolerance gives both a better outcome, because more tolerant players cope better with each other\'s unintentional defections. The cost is exposure: someone who never cooperates can get up to Δ + 1 defections ahead before the rule stops them, and from then on each of their defections is matched by one of yours.',
      'Either way you cannot be exploited in the long run. The paper proves that against any strategy, a cumulative reciprocator eventually gets the same payoff as the other person, for every Δ and every error rate.'
    ],
    m: [
      'Values used in the paper: Δ = 1 is the default in the simulations, Δ = 2 is used in the Fig. 1 illustration, and Δ = 3 is the instance used to predict participants\' choices in the experiment (the authors report other thresholds gave similar results). The default here is 1. The paper does not recommend values for particular kinds of relationship.'
    ]
  },
  counts: {
    t: 'The three numbers',
    p: [
      'They defected (n_B): times you asked them and they defected.',
      'You defected (n_A): times they asked you and you defected. This includes defections the rule told you to make. The paper\'s counters record every defection, and your own defections are what bring d back down.',
      'd = n_B − n_A. Positive means they have defected more; negative means you have. The switch from cooperate to defect sits between Δ and Δ + 1.'
    ]
  },
  rule: {
    t: 'What to do next',
    p: [
      'Within tolerance (d ≤ Δ): cooperate on their next request.',
      'Past tolerance (d > Δ): defect on their next request. Your defection lowers d by 1. Once d is back to Δ, you cooperate again.',
      'The paper points out that once the tolerance is used up, CURE behaves like tit-for-tat: each further defection from them is answered by one defection from you, and you return to cooperating right after. There is no extended punishment and no reset.',
      'If d is negative, you have defected more often than they have. The rule still says cooperate.'
    ]
  },
  errors: {
    t: 'Why every defection counts as 1',
    p: [
      'The paper\'s model includes mistakes: someone who intends to cooperate sometimes ends up defecting anyway (a "trembling hand" error). Those defections still count in full.',
      'CURE does not try to judge intent. In the paper\'s experiment, participants could not tell whether the other person\'s choice had been carried out as intended. Tolerance is what forgives honest failures: an occasional "couldn\'t" fits inside Δ, a steady pattern does not. The paper shows this is why CURE keeps cooperation going when errors occur, where tit-for-tat breaks down.',
      'The game has two choices per round, cooperate or defect, so requests are not weighted by size either. If something is too small to count as a favour, don\'t log it.'
    ],
    m: ['If you want to remember that a defection was a genuine can\'t, write it in the subject. It does not change the count.']
  },
  logging: {
    t: 'Logging an ask',
    p: [
      'Pick the row by who asked. "They asked you" records whether you cooperated or defected. "You asked them" records what they did.',
      'Log it when the ask happens. If there is no answer yet, use the "not answered" button: it counts for nothing until you resolve it from the waiting list or the history.',
      'In the "They asked you" row, the choice the rule recommends is marked. You can log anything; this is a record of what happened.',
      'Date and subject are for your reference. The count does not depend on them.'
    ]
  },
  pending: {
    t: 'Waiting on you',
    p: [
      'Requests from anyone that you have not answered yet, oldest first.',
      'Each one shows what the rule says given that person\'s current d. Answering one updates d, so if someone has several open requests, the suggestion for the next one can change.'
    ]
  },
  history: {
    t: 'History',
    p: [
      'Newest first, with unanswered entries pinned on top.',
      'The right-hand number is the entry\'s effect on d: +1 when they defected, −1 when you defected, 0 for cooperation.',
      '✎ edits an entry: date, subject, who asked, and the outcome. Enter saves, Esc cancels. The editor previews the effect on d before you save.',
      '× deletes an entry. Use editing and deleting to fix mistakes in the record, not to forgive: the rule never wipes the slate. Tolerance is the forgiveness.'
    ]
  }
};
