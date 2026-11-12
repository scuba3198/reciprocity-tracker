# Reciprocity tracker

Tracks asks between the user and each person they know, and applies cumulative reciprocity (CURE, Li et al. 2022) to suggest how to answer the next one. CURE is the sole strategy.

## Language

**Person**:
Someone the user exchanges favours with. Has a name, a tolerance Δ, and a list of events.

**Event (ask)**:
One request. `dir` is who asked: `theyAsked` (they asked the user) or `iAsked` (the user asked them). `outcome` is `yes` (cooperated), `no` (defected) or `waiting` (not answered yet).

**Defection**:
Any `no` outcome. Counts as exactly 1 regardless of reason; a genuine "couldn't" is still a defection (the paper's trembling-hand errors). Tolerance, not reclassification, is what forgives honest failures.

**n_B / n_A / d**:
n_B = their defections (`iAsked` + `no`), n_A = the user's defections (`theyAsked` + `no`), d = n_B − n_A. Cooperation and waiting events do not change d. Nothing is ever reset.

**Tolerance (Δ)**:
Integer 0–20, default 1. The rule: on their next ask, cooperate if d ≤ Δ, defect if d > Δ.
