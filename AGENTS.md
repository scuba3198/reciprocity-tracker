## Multi-agent routing

- The root agent plans, routes work, and makes final decisions. Use `gpt-6-sol` with medium reasoning by default.
- Delegate substantial bounded work when useful. Prefer named agents: `researcher` investigates, `coder` implements, `browser_debugger` investigates UI behavior, and `reviewer` reviews diffs. Parallelize independent work only.
- Use `gpt-6-luna` with medium reasoning for routine research and coding, low for simple bounded tasks, and high for browser investigation or tricky debugging. Use `gpt-6-sol` with high for complex debugging and medium for reviews. Use xhigh only after lower effort fails. Do not use `gpt-6-astra` for subagents without explicit per-task approval.
- Spawn subagents with `fork_turns = "none"` and pass their task, relevant files, constraints, and required output. Subagents return findings to root and do not spawn other agents.
- Apply installed Matt Pocock skills when relevant. Keep Ponytail active.

## Agent skills

### Issue tracker

Issues and specs live in GitHub Issues for `scuba3198/reciprocity-tracker`. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the five default triage labels. See `docs/agents/triage-labels.md`.

### Domain docs

Use the single-context layout. See `docs/agents/domain.md`.
For recommendation changes, consult `CONTEXT.md`: CURE is the sole strategy.
