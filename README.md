# Good Faith

**[Open the website](https://scuba3198.github.io/reciprocity-tracker/)**

A ReScript + React tracker using an **app-level asynchronous adaptation of CURE**, the cumulative reciprocity strategy studied by [Li et al. (2022)](https://www.nature.com/articles/s43588-022-00334-w). The adaptation for dated, real-world actions is Good Faith's; it is not a method proposed or validated by Li et al. Each person has a separate history. A round records each person's status as Cooperated, Defected, or Requested, and requires at least one Cooperated or Defected status. Request is a neutral record that someone asked for help, a favor, or cooperation; it is neither cooperation nor defection. The rule tracks their cumulative defections minus yours and suggests cooperation while that difference is within your chosen tolerance of 1 or 2.

Choose an action for each person, then **Confirm round**. A Request records that someone asked for help, a favor, or cooperation; it adds zero defections. A request is not itself cooperation or an obligation. Keep a request as a draft until at least one person has Cooperated or Defected; then record the request and response/action in the same interaction and confirm it. A Request/Request round cannot be confirmed. Request can have an action date. Older saved **No action** entries keep their original meaning: no relevant action by that person, not a request. They remain distinct and are never silently relabeled. CURE tracks defection imbalance, not a running score of good deeds. Use **Defected** only when someone made a meaningful, safe choice not to do an agreed optional contribution. Leave out situations with no relevant action by either person or no clear reciprocal expectation. You can edit confirmed entries in **The pattern**; changes update the CURE calculation and analysis. You can keep multiple **Pending rounds** per person, reopen and edit each one, or start a new round. **Save draft** stores incomplete moves and fields; confirming or discarding one leaves the others intact. Check the completion date when confirming. The calendars accept past and future dates; action dates must be no later than the round completion date. Backdated entries are replayed in date order; **Undo last entry** removes the most recently confirmed entry.

## Learned behavior and decision analysis

Each person's page has a small **Learned behavior** section and an optional **Help me decide** action. Logging an interaction asks for no extra ratings. These features calculate from the existing history and do not change CURE's recommendation.

For each of your moves, the app estimates the chance that the other person cooperates, using only confirmed rounds that contain both people’s moves. Action dates, drafts, and events without a bilateral C/D entry are not observations. It starts with a Beta(1,1) prior, so the estimate is `(1 + their cooperations) / (2 + relevant interactions)`. An unseen response branch stays at 50%; one observation cannot produce 0% or 100%. Category estimates use two pseudo-observations at that person's overall conditional rate, then update with the category's observations. The displayed evidence label counts observations (Very limited: 0–2, Limited: 3–5, Moderate: 6–14, Strong: 15+); it is not a statistical confidence interval.

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

Use **CURE tolerance** in Settings to switch between 1 and 2 (default). The choice is saved in this browser while signed out and in your account while signed in. If your account has no saved tolerance yet, your browser choice is copied to it. Recommendations update across the tracker.

Open **How the method works** in the sidebar for the CURE rule, the optional models, worked examples, and the paper.
