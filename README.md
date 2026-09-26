# Good Faith

**[Open the website](https://scuba3198.github.io/reciprocity-tracker/)**

A ReScript + React tracker for **CURE**, the cumulative reciprocity strategy in [Li et al. (2022)](https://www.nature.com/articles/s43588-022-00334-w). Each person has a separate interaction history. Log **both your move and their move** from each interaction. CURE tracks their cumulative defections minus yours and suggests cooperation while that difference is at most 1. This version starts a fresh ledger; earlier CAPRI entries and backups are not imported.

Set when the interaction happened with the custom calendar, **Today**, **Yesterday**, or a date in `YYYY-MM-DD` / `YYYYMMDD` form. Backdated entries are replayed in date order; **Undo last entry** removes the most recently logged entry.

## Run

```bash
npm install
npm run dev
```

Open the local URL printed by Vite. For a production bundle, run `npm run build`. Run `npm run check` for the state-machine checks.

Data stays in this browser's local storage. Use **Backup & restore** to download a JSON copy before clearing site data or switching browsers. Restoring previews the file and asks before replacing the current ledger.

Use **Appearance** for Auto (follows the device theme), Light, or Dark. The choice is saved in this browser.

Open **How the method works** in the sidebar for the CURE rule, worked examples, the paper, and practical scenarios where a game model may help or should not be used.
