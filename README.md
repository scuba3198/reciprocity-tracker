# Reciprocity tracker (CURE)

**[Open the website](https://scuba3198.github.io/reciprocity-tracker/)**

A small, dependency-free tracker for **cumulative reciprocity (CURE)** from Li, Zhao, Li, Rossetti, Hilbe & Xia, ["Evolution of cooperation through cumulative reciprocity"](https://www.nature.com/articles/s43588-022-00334-w), *Nature Computational Science* 2, 677–686 (2022).

For each person you keep two counts: how often they defected against you (n_B) and how often you defected against them (n_A). The rule looks only at the difference d = n_B − n_A: when they ask you for something, **cooperate if d ≤ Δ, defect if d > Δ**. Δ is your tolerance for that person (default 1). Every defection counts as exactly 1 and nothing is ever reset.

## Features

- People list with search (`/` to focus), drag-or-arrow reordering, sort A–Z or by d.
- Log asks in either direction, mark them "not answered yet", and resolve them later from the **Waiting on you** strip or the history.
- Edit or delete history entries, with a preview of each entry's effect on d.
- Number line showing d against the cooperate/defect boundary.
- In-app help for every concept (the `?` buttons).
- Data stays in the browser (`localStorage`). **Export** saves a JSON file; **Import** replaces or merges.
- Installable as a web app (manifest + icons); light and dark themes follow the device.

## Run

```bash
npm install
npm run dev
```

- `npm test` runs the unit tests for the CURE logic, data normalisation, and storage.
- `npm run build` makes a production bundle in `dist/`.
- Pushing to `main` deploys to GitHub Pages via `.github/workflows/pages.yml`.

## Layout

Plain ES modules bundled by Vite. No framework.

```
index.html               static markup shell
src/
  main.js                entry: wires modules together and draws
  state.js               shared app state + commit()/render()
  actions.js             state mutations (log, resolve, edit, delete…)
  core/                  pure logic, no DOM (unit-tested)
    cure.js              the CURE rule: effect, stats, verdict text
    model.js             normalisation, migration, import merge
    storage.js           localStorage load/save (+ v13 migration)
    util.js              dates, ids, formatting
    help-content.js      help-dialog text
  ui/                    DOM rendering
    dom.js               $, el(), segmented control
    rail.js              people list, search, reorder
    strip.js             "Waiting on you"
    detail.js            selected person view
    editor.js            inline history-entry editor
    help.js              help dialog
    import-export.js     JSON import/export
    add-person.js        "Add someone" form
    motion.js            animation layer (observes re-renders)
  styles/                CSS, imported in order by index.css
tests/core.test.js       node:test unit tests
```

Data written by the earlier single-file version (`cure_tracker_v14`, and `v13` via migration) loads unchanged, and its export files import as before.
