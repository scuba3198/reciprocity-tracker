# Good Faith

**[Open the website](https://scuba3198.github.io/reciprocity-tracker/)**

A ReScript + React tracker for **CURE**, the cumulative reciprocity strategy in [Li et al. (2022)](https://www.nature.com/articles/s43588-022-00334-w). Each person has a separate interaction history. Log **both your move and their move** from each interaction. CURE tracks their cumulative defections minus yours and suggests cooperation while that difference is at most 1.

Set when the interaction happened with the custom calendar, **Today**, **Yesterday**, or a date in `YYYY-MM-DD` / `YYYYMMDD` form. Backdated entries are replayed in date order; **Undo last entry** removes the most recently logged entry.

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

Open **How the method works** in the sidebar for the CURE rule, worked examples, the paper, and practical scenarios where a game model may help or should not be used.
