# Issue tracker: GitHub

Issues and specs for this repo live in GitHub Issues. Use `gh` from this repository to create, read, list, comment on, label, and close issues.

## Conventions

- Create: `gh issue create --title "..." --body-file <file>`
- Read: `gh issue view <number> --comments`
- List: `gh issue list --state open`, with label or state filters as needed
- Comment: `gh issue comment <number> --body-file <file>`
- Label: `gh issue edit <number> --add-label <label>` or `--remove-label <label>`
- Close: `gh issue close <number> --comment "..."`

Infer the repository from `git remote -v`.

## Pull requests as a triage surface

**PRs as a request surface: no.** Set this to `yes` if external PRs should enter the triage queue.

## Skill operations

- "Publish to the issue tracker": create a GitHub issue.
- "Fetch the relevant ticket": run `gh issue view <number> --comments`.

## Wayfinding operations

- Map: one issue labelled `wayfinder:map`, with Notes, Decisions-so-far, and Fog in its body.
- Child tickets: GitHub sub-issues where available; otherwise list them in the map body and put `Part of #<map>` in each child. Label each `wayfinder:<type>` (`research`, `prototype`, `grilling`, or `task`).
- Blocking: use GitHub issue dependencies where available; otherwise put `Blocked by: #<n>` at the top of the child body.
- Frontier: take the first open, unassigned child with no open blockers.
- Claim: assign the child to the driving developer before work.
- Resolve: comment with the answer, close the child, and add a short pointer to the map's Decisions-so-far.
