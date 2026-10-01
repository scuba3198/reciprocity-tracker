# Good Faith

**[Open the website](https://scuba3198.github.io/reciprocity-tracker/)**

A ReScript + React tracker using an **app-level asynchronous adaptation of CURE**, the cumulative reciprocity strategy studied by [Li et al. (2022)](https://www.nature.com/articles/s43588-022-00334-w). The adaptation for dated, real-world actions is Good Faith's; it is not a method proposed or validated by Li et al. Each person starts with a General ledger and may have additional independent ledgers for different arrangements. A round records each person's status as Cooperated, Defected, Requested, or Unable. It requires at least one Cooperated or Defected status, or a Requested/Unable pair. Request and Unable are neutral. The rule tracks their cumulative defections minus yours and suggests cooperation while that difference is within your chosen tolerance of 1, 2, or 3.

Choose a role for each person, then **Confirm round**. A Request records that someone asked for help, a favor, or cooperation. Unable records that circumstances outside the person's reasonable control prevented help, such as illness, unavailability, insufficient resources, or a genuine conflicting obligation. Neither adds a defection. A Requested/Unable pair can be confirmed; Request/Request and Unable/Unable cannot. CURE tracks defection imbalance, not a running score of good deeds. Use **Defected** only when someone made a meaningful, safe choice not to do an agreed optional contribution. You can edit confirmed entries in **The pattern**; changes update CURE's recommendation and history. In **Edit entry**, change **Ledger** to move a round to another ledger for the same person when saving; both ledgers recalculate their recommendations. You can keep multiple **Pending rounds** per person, reopen and edit each one, or start a new round. **Save draft** stores incomplete moves and fields; confirming or discarding one leaves the others intact. Check the completion date when confirming. The calendars accept past and future dates; action dates must be no later than the round completion date. Backdated entries are replayed in date order; **Undo last entry** removes the most recently confirmed entry.

## Run

```bash
npm install
npm run dev
```

Open the local URL printed by Vite. For a production bundle, run `npm run build`. Run `npm run check` for the state-machine checks.

While signed out, your ledger stays in this browser. Sign up or sign in under **Cloud sync** to sync it to your private account. On first sign-in, the existing browser ledger is copied only if your account has no ledger yet; an existing cloud ledger always takes precedence. Sign-up may show a confirmation message depending on the project’s email settings.

To keep a copy without an account, open **Local backup** in Settings and download a JSON file. You can restore it on another device from the same section; review the preview before replacing the current data. The file includes your people, history, drafts, CURE tolerance, and Think Ahead scenarios.

Cloud sync uses `public.good_faith_ledgers`, protected by per-user row-level security (RLS).
For an existing account, choose **Forgot password?** to request a reset email, then follow its link to set a password of at least 8 characters.

Use **Appearance** for Auto (follows the device theme), Light, or Dark. The choice is saved in this browser.

Use **CURE Strategy** in Settings to choose the app default: Guarded (Δ1), **Balanced (Δ2, default)**, or Forgiving (Δ3). On a person's ledger screen, open **Change tolerance** near the recommendation to set a ledger override or the person's default. The compact summary shows the active tolerance and where it comes from, including General. Create another ledger for an arrangement such as Dishes or Money; it inherits by default. Each ledger keeps its own history and pending rounds. Insights shows each ledger separately. To remove an additional ledger added by mistake, select it and choose **Delete ledger**; confirm to remove its history, drafts, and override. General remains available.

Tolerance follows ledger override → person override → app default → Δ2. Removing an override restores inheritance. Changing a setting recalculates advice from existing history without resetting counts or rewriting events. Tolerance never switches automatically. The app default stays in this browser while signed out and in your account while signed in; person and ledger overrides are included in cloud sync and local backups. Old records without settings use Δ2, and explicitly saved values remain selected. No database migration is needed: the existing people JSON stores the optional overrides and additional ledgers.

Our robustness experiments found a consistent trade-off. Lower tolerance responded better to short relationships and deliberate exploitation. Higher tolerance improved recovery from mistakes and reduced false-retaliation cascades. Δ2 is therefore used as the general default, while Δ1 and Δ3 remain available for different relationship conditions. Simulations do not prove which tolerance is best for real humans.

Open **How the method works** in the sidebar for the CURE rule, worked examples, and the paper.

## Think Ahead

Use **Think Ahead** for an important one-off or sequential choice. Name two choices, rate their immediate outcomes, and add possible later consequences with rough likelihoods and importance. If a consequence depends on another person's future decision, ask whether they would have a reason to follow through at that point. That is backward induction. The app combines those estimates into an approximate expected value for each choice and flags close calls. The labels are judgment aids, not objective probabilities or moral advice.

Use **CURE** for repeated reciprocal interactions with the same person. Think Ahead scenarios are stored separately and never add interactions, change the defection difference or tolerance, or alter historical CURE recommendations. Scenarios stay in this browser while signed out, sync to the account while signed in, and are included in new local backups. Old backups and saved ledgers without scenarios still load.

Cloud sync for Think Ahead requires the additive database change in [`db/think_ahead.sql`](db/think_ahead.sql).
