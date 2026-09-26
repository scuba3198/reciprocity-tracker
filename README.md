# Good Faith

**[Open the website](https://scuba3198.github.io/reciprocity-tracker/)**

A ReScript + React tracker for **CURE**, the cumulative reciprocity strategy in [Li et al. (2022)](https://www.nature.com/articles/s43588-022-00334-w). Each person has a separate interaction history. Log **both your move and their move** from each interaction. CURE tracks their cumulative defections minus yours and suggests cooperation while that difference is at most 1.

Set when the interaction happened with the custom calendar, **Today**, **Yesterday**, or a date in `YYYY-MM-DD` / `YYYYMMDD` form. Backdated entries are replayed in date order; **Undo last entry** removes the most recently logged entry.

## Learned behavior and decision analysis

Each person's page has a small **Learned behavior** section and an optional **Help me decide** action. Logging an interaction asks for no extra ratings. These features calculate from the existing history and do not change CURE's recommendation.

For each of your moves, the app estimates the chance that the other person cooperates. It starts with a Beta(1,1) prior, so the estimate is `(1 + their cooperations) / (2 + relevant interactions)`. An unseen response branch stays at 50%; one observation cannot produce 0% or 100%. Category estimates use two pseudo-observations at that person's overall conditional rate, then update with the category's observations. The displayed evidence label counts observations (Very limited: 0–2, Limited: 3–5, Moderate: 6–14, Strong: 15+); it is not a statistical confidence interval.

**Help me decide** opens four optional 1–5 ratings, all initially 3: cooperation cost (`C`), successful reciprocity value (`V`), exploitation cost (`E`), and relationship importance (`R`). The app uses an illustrative, editable payoff mapping:

| Outcome (you / them) | Utility |
| --- | ---: |
| Cooperate / Cooperate | `V + R − C` |
| Cooperate / Defect | `−C − E` |
| Defect / Cooperate | `V/2 − R` |
| Defect / Defect | `−R` |

For each possible move, expected utility is the estimated cooperation probability times its cooperative-outcome utility plus the remaining probability times its defecting-outcome utility. The higher result is suggested; a tie shows **No clear advantage**. This payoff mapping is a subjective decision aid, not a rule from Li et al. or a judgment of anyone's motives. CURE remains the app's reciprocity strategy, and the two recommendations may disagree.

## Run

```bash
npm install
npm run dev
```

Open the local URL printed by Vite. For a production bundle, run `npm run build`. Run `npm run check` for the state-machine checks.

While signed out, your ledger stays in this browser. Sign up or sign in under **Cloud sync** to sync it to your private account. On first sign-in, the existing browser ledger is copied only if your account has no ledger yet; an existing cloud ledger always takes precedence. Sign-up may show a confirmation message depending on the project’s email settings.

Cloud sync uses `public.good_faith_ledgers`, protected by per-user row-level security (RLS).
For an existing account, choose **Forgot password?** to request a reset email, then follow its link to set a password of at least 8 characters.

Use **Appearance** for Auto (follows the device theme), Light, or Dark. The choice is saved in this browser.

Open **How the method works** in the sidebar for the CURE rule, the optional models, worked examples, the paper, and practical scenarios where a game model may help or should not be used.
