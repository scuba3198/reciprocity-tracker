# Good Faith

**[Open the website](https://scuba3198.github.io/reciprocity-tracker/)**

A ReScript + React tracker for **CAPRI**, the deterministic three-round strategy in Murase and Baek (2020). Each person has a separate interaction history. Log **both your move and their move** from each interaction; the app uses the last three paired rounds to suggest your next move. A new ledger begins with three assumed C/C rounds. Older entries with no recorded move from you remain visible, but after such a gap CAPRI waits for three complete paired rounds before giving an exact suggestion.

Set when the interaction happened with the custom calendar, **Today**, **Yesterday**, or a date in `YYYY-MM-DD` / `YYYYMMDD` form. Backdated entries are replayed in date order; **Undo last entry** removes the most recently logged entry.

## Run

```bash
npm install
npm run dev
```

Open the local URL printed by Vite. For a production bundle, run `npm run build`. Run `npm run check` for the state-machine checks.

Data stays in this browser's local storage. Use **Backup & restore** to download a JSON copy before clearing site data or switching browsers. Restoring previews the file and asks before replacing the current ledger.

Use **Appearance** for Auto (follows the device theme), Light, or Dark. The choice is saved in this browser.

Open **How the method works** in the sidebar for CAPRI’s five rules, worked examples, the paper, and practical scenarios where a game model may help or should not be used.
