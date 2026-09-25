# Good Faith

**[Open the website](https://scuba3198.github.io/reciprocity-tracker/)**

A ReScript + React tracker for the generous tit-for-tat rule. Each person has a separate interaction history. Log **their** move after an interaction; the app suggests **your next** move. You can optionally record what **you** actually did. History compares it with the suggestion for that interaction, but your move does not change the recommendation rule.

Set when the interaction happened with the custom calendar, **Today**, **Yesterday**, or a date in `YYYY-MM-DD` / `YYYYMMDD` form. Backdated entries are replayed in date order; **Undo last entry** removes the most recently logged entry.

## Run

```bash
npm install
npm run dev
```

Open the local URL printed by Vite. For a production bundle, run `npm run build`. Run `npm run check` for the state-machine checks.

Data stays in this browser's local storage. Use **Backup & restore** to download a JSON copy before clearing site data or switching browsers. Restoring previews the file and asks before replacing the current ledger.

Use **Appearance** for Auto (follows the device theme), Light, or Dark. The choice is saved in this browser.

Open **How the method works** in the sidebar for the state machine, worked examples, research sources, and practical scenarios where the rule may help or should not be used.
