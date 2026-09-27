# Good Faith

Good Faith tracks reciprocal choices between the user and each person they interact with.

## Language

**Person**:
An individual whose reciprocal interactions with the user form one history.

**Round**:
One recorded interaction with another person. The app's real-world extension allows Request, Unable, and legacy No action statuses. A confirmed round contains at least one Cooperated or Defected status, or a Request/Unable pair; CURE's original game rounds have two C/D moves.

**Request**:
A neutral status meaning the person asked for help, a favor, or cooperation. It adds no defection to CURE, is not cooperation, and can have an action date. A request alone creates no obligation.

**Unable**:
A neutral status meaning circumstances outside a person's reasonable control prevented them from helping. It is neither cooperation nor defection; illness, unavailability, insufficient resources, and conflicting obligations can qualify.

**No action**:
For legacy saved entries, the person had no relevant move in a recorded interaction. It is neither cooperation nor defection and differs from Request. Preserve existing No action entries as this distinct meaning; never silently relabel them as Request.

**Defection**:
A choice to withhold cooperation under a clear, meaningful expectation. Inability to act and a safety boundary are not defections.

**Completion date**:
The date an interaction is complete or resolved. It determines the interaction's place in the history; events completed on the same date retain their confirmation order.

**Confirmation**:
The act of adding a completed interaction to a person's history. Undo removes the most recently confirmed interaction.

**History**:
The confirmed interactions for one person, ordered by completion date and then confirmation order. An interaction can be corrected or removed, and later CURE results are recalculated.

**Historical recommendation**:
CURE's retrospective recommendation before a confirmed interaction. It is recalculated when earlier interactions are added, edited, or removed; it is not a record of advice shown at the time.

**Draft**:
A provisional interaction record. It does not enter the person's history or affect advice until confirmed.

**Category**:
An optional label for the context of a round. It does not divide a person's CURE history.

**CURE**:
A cumulative reciprocity strategy where d is their total defections minus yours. Its strategic moves remain C/D: Cooperated and Defected. It recommends cooperation when d is at most the chosen tolerance (one or two, default two); otherwise it recommends withholding cooperation. Request, Unable, and legacy No action add no defection; each defection has equal weight regardless of stakes.

**Decision analysis**:
An optional comparison of the two choices using estimated responses and user-rated stakes. Its payoff mapping is illustrative and subjective; it does not replace CURE's recommendation.

**Behavior estimate**:
A descriptive association between the person's cooperation and each of the user's two choices across confirmed bilateral C/D interactions only, regardless of who acted first. Request, Unable, legacy No action, and drafts are not observations. It does not claim that the user's choice caused the person's choice.
