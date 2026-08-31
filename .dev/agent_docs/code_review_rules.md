# Zammad Review Rules

Single source of truth for how an AI review decides what to flag, and how it says it.

This file is **tool-neutral on purpose**. It says nothing about `glab`, worktrees, GitLab APIs,
approval gates or output transport — those belong to whichever caller is using these rules.

It is also **not a duplicate of the coding conventions**. Its sibling files in this directory, and
`.dev/ai-agent-instructions.md`, are the conventions; this file tells a reviewer which of them to
read and how to turn a violation into a useful comment. When a convention changes, it changes there.

## Consumers

| Consumer                        | Lives in    | Uses these rules for                        |
| ------------------------------- | ----------- | ------------------------------------------- |
| `.dev/agents/code-reviewer.md`  | core repo   | Reviewing changes in a fresh context        |
| `code-review` skill             | skills repo | Local review, delegates to the agent above  |
| `review-mr` skill               | skills repo | Reviewing a GitLab MR interactively         |

When a rule changes, it changes **here** and every consumer picks it up. Do not copy rule text into
a consumer.

---

## Step 1 — Read the conventions for what the change touches

Before reviewing, identify which areas the diff touches and read **only** the applicable reference
docs. Do not read them all upfront, and do not review conventions from memory — these files are the
authority, and they change.

| The diff touches…                                     | Read                              |
| ----------------------------------------------------- | --------------------------------- |
| GraphQL types, mutations, queries, subscriptions      | `graphql_patterns.md`             |
| Knowledge base code in the new stack                  | `knowledge_base_patterns.md`      |
| Vue components, composables, routing, the form system | `frontend_patterns.md`            |
| Addon extensions to the Vue frontend                  | `frontend_addon_layer.md`         |
| New models used by the legacy CoffeeScript stack      | `legacy_model_patterns.md`        |
| Specs, test setup, test helpers                       | `testing.md`                      |
| Specs for a service or its GraphQL caller             | `testing_services_and_graphql.md` |
| Service objects (`app/services/service/`)             | `service_patterns.md`             |
| Migrations or seeds                                   | `database_migrations.md`          |

A convention violation is a finding. "The surrounding code doesn't follow it either" is not a
defence — if the doc says it, the change should do it.

`.dev/ai-agent-instructions.md` carries the repo-wide rules that apply regardless of area:

- Every new file except Markdown files (`*.md`) needs the Zammad copyright header.
- `i18n/*.po` is never edited directly — translations come from translations.zammad.org.
- New features target Vue 3 + GraphQL. A new feature built on REST + CoffeeScript is worth
  questioning unless it is extending existing legacy behaviour.

## Step 2 — Decide what is worth flagging

Precision matters more than recall. A review that reports five real problems is more useful than one
that reports five real problems buried in fifteen speculative ones, because the second teaches
people to skim.

Flag something only when **all** of these hold:

1. It meaningfully impacts correctness, performance, security or maintainability.
2. It is discrete and actionable — one specific problem, not "this area is messy" or a bundle of
   related complaints.
3. It matches the rigor Zammad actually holds, which is high. A missing spec on new public
   behaviour, an unchecked authorization path, or a bug fix without a regression test **is** a
   finding — do not excuse it because neighbouring code is no better.
4. It was introduced by this change. Pre-existing problems are out of scope.
5. The author would plausibly fix it if they knew. If they would reasonably shrug, it is not a
   finding.
6. It does not rest on unstated assumptions about the codebase or the author's intent.
7. It is not speculation. "This might break something elsewhere" is not a finding unless you can
   name the affected code and show that it is affected.
8. It is clearly not a deliberate choice by the author.

**On volume:** report every finding that meets the bar — do not stop at the first one. If nothing
meets the bar, report nothing. "No findings" is a legitimate and useful outcome; inventing issues to
make a review look thorough is not.

Also out of scope in every review:

- Style and formatting a linter owns (RuboCop, ESLint, Prettier), unless it actively obscures
  meaning or breaks a documented standard.
- Naming preferences not covered by a convention doc.
- Speculative future requirements that are not in the issue.
- Pre-existing code visible in diff context but untouched by the change.

Verify before reporting: read the actual code, not just the diff hunk. Prefer evidence over
inference — if a working checkout is available, grep for related call sites and tests.

An honest "I cannot tell from the code" is a useful answer. Never manufacture confidence.

## Step 3 — Classify

Every finding gets **a category and a severity**. They are independent: the category says what kind
of problem it is, the severity says how much it matters.

**Category** (labels the type of finding):

| Prefix       | Meaning                                                            |
| ------------ | ------------------------------------------------------------------ |
| `[security]` | Security issue introduced by the change                            |
| `[issue]`    | Divergence from the linked issue's use cases or acceptance criteria |
| `[ui]`       | Frontend convention regression                                     |
| `[backend]`  | Backend convention or correctness concern                          |
| `[test]`     | Missing or inadequate test coverage for new behaviour              |
| `[cleanup]`  | Leftover artifacts, dead code, unnecessary complexity              |

**Severity** (drives grouping and ordering):

| Level | Meaning                                                                              |
| ----- | ------------------------------------------------------------------------------------ |
| P0    | Blocks. Security issue, broken functionality, missing authorization, data loss risk. |
| P1    | Should fix. Bugs, missing error handling, missing tests, convention violations.       |
| P2    | Consider. Minor improvements, alternative approaches.                                 |

Write them together: `[security] P0`, `[ui] P2`. Present findings grouped by severity in the
order P0, P1, then P2.

## Step 4 — Write the comment

1. Be clear about **why** it is a problem, not just that it is one.
2. **State the preconditions up front** — the inputs, environment or scenario needed for the problem
   to occur, so the reader can judge severity immediately rather than inferring it.
3. Communicate severity accurately. Never inflate it.
4. One paragraph. The author should grasp it without close reading.
5. Be specific and actionable. Never vague feedback like "this could be better" — say what to do.
6. No code chunks longer than ~3 lines. Wrap code in inline code tags or a fenced block.
7. Matter-of-fact tone. Not accusatory, not congratulatory. No "Great job…", no "Thanks for…".
8. Anchor to the tightest line range that pinpoints the problem — 5–10 lines at most. Do not restate
   the location in the body; the anchor already carries it.
9. One comment per distinct problem. Do not merge two issues into one, and do not post the same
   issue at two locations.

### Suggestion blocks

Where the fix is mechanical, offer it as a suggestion the author can apply in one click:

````markdown
```suggestion:-0+0
  the replacement line(s)
```
````

- Preserve the **exact** leading whitespace of the replaced lines — spaces vs tabs, and the count.
- Do not add or remove an indentation level unless that is the actual fix.
- Nothing but replacement code inside the block. Explanation goes in the paragraph above it.
- `-N+M` extends the range N lines above and M lines below the anchored line; `-0+0` replaces just
  the anchored line. This differs from GitHub's suggestion syntax.
- Only when the fix is genuinely mechanical. If it needs a judgement call, describe it instead — a
  wrong one-click fix is worse than prose.

## Step 5 — Report what you could not judge

Step 2 is precision-first on purpose: no speculation, nothing resting on unstated assumptions. That
makes "I cannot tell from the code" an honest and expected outcome — and since it produces no
finding, it is lost unless it has somewhere to go. It is often the most useful thing a reviewer
knows.

Report it separately from the findings: **at most three items**, each naming a place and the
question a human should answer there. Draw only on what the review actually produced:

- An `Unverifiable` acceptance criterion.
- A specific uncertainty with a named file — not "this might break something elsewhere".
- Something the change cannot show on its own: migration timing on a large installation, a rendered
  result, `i18n/*.po` content, binary assets.

Two rules keep it honest:

- **Never park a finding here.** If it meets the bar in Step 2 it is a finding, with an anchor and a
  severity. Moving a real problem into this list hides it from whoever has to fix it.
- **No items is the normal case.** Then write nothing — not a reassurance that there is nothing.
  An open-ended list of things to double-check is a "check everything" disclaimer, and it trains
  people to skim, for exactly the reason Step 2 exists.

Where this surfaces is the caller's business: a reviewer working in a terminal can print it for the
person running the review, while one posting to a merge request may deliberately keep it out of the
thread. It is guidance for the human reviewing, not a comment for the author.

---

## What to check

### Correctness

Logic errors, edge cases, off-by-ones, incorrect API usage, broken assumptions — anything that would
cause wrong behaviour or a crash. Also: **unintended side effects** — does the change affect code
paths that were not part of the plan?

### Security — `[security]`

OWASP-style issues **introduced by the change**:

- SQL / command / template injection
- XSS, unsafe raw HTML rendering
- Missing authorization or authentication checks (Pundit policies in `app/policies/`)
- Insecure deserialization
- Path traversal, SSRF
- Hardcoded secrets or credentials
- Weak or missing input validation at trust boundaries
- Unsafe use of `eval`, `system`, raw SQL, `send`/`public_send`, `constantize`/`safe_constantize`
  on user-influenced input

### Issue alignment — `[issue]`

Only when a linked issue was found. Does the change cover the use cases the issue describes, and the
edge cases implied by them?

Acceptance criteria get their own pass below — do not fold them in here.

#### Acceptance criteria pass

When the linked issue lists acceptance criteria, this is a **closed checklist, not an open search**.
Work through it item by item rather than forming a general impression of whether the change "does
the right thing".

This pass is **exempt from the flagging threshold**: every criterion gets a verdict whether or not it
produces a finding.

- Enumerate **every** criterion verbatim, in the issue's own order. Do not merge, reword, skip or
  summarise any of them — not even ones that look trivially satisfied.
- Give each criterion exactly one verdict:
  - **Met** — demonstrably implemented. Cite the `file:line` that satisfies it.
  - **Not met** — not implemented, or only partially. Each becomes an `[issue]` finding.
  - **Unverifiable** — cannot be judged from code alone (needs manual testing, a screenshot, a
    design review, or depends on code outside the change). State _why_. Never invent a Met/Not met
    verdict just to avoid this outcome.
- Report as a table **every time**, including when everything is met — "all criteria verified" is
  itself the answer the reviewer needs, not merely an absence of findings.

  | #   | Acceptance criterion | Verdict      | Evidence          |
  | --- | -------------------- | ------------ | ----------------- |
  | 1   | &lt;verbatim text&gt; | Met          | `app/foo.rb:42`   |
  | 2   | &lt;verbatim text&gt; | Not met      | not addressed     |
  | 3   | &lt;verbatim text&gt; | Unverifiable | needs manual test |

- If the linked issue has **no** acceptance criteria, say so in one line and move on. Do not invent
  criteria from the issue's prose.
- A change with no findings but an unaddressed or unverifiable criterion is **not** clean.

#### Use-case cross-check

Criteria and use cases are written at different moments and drift apart. A criteria list can pass
completely while the story it was meant to describe is only half covered — so after the criteria
pass, map the issue's use cases / user stories onto its criteria.

Like the criteria pass, this is a **closed mapping between two lists the issue already contains**,
not a fresh search for behaviour the issue never asked for. Never invent a use case from prose.

Give each use case exactly one verdict:

| Verdict           | Meaning                                                                |
| ----------------- | ---------------------------------------------------------------------- |
| Covered           | a criterion asserts its observable outcome — cite the criterion numbers |
| Partially covered | an edge case, error path or role variant it describes has no criterion  |
| Not covered       | no criterion touches it                                                |
| Conflicts         | a criterion asserts something the use case contradicts                 |

What a gap means depends on the change, and the distinction decides who has work to do:

- **Not covered, but the change implements it** — not a finding. The change is fine; the issue's
  criteria list is incomplete. Report it as that, and never attach it to the author's lines.
- **Not covered, and the change does not implement it** — an `[issue]` finding. This is the case
  the cross-check exists for: it is invisible to the criteria pass, because there is no criterion
  to fail.
- **Partially covered** — apply the same two cases to the uncovered aspect alone: an `[issue]`
  finding when the change does not implement it, a gap in the criteria list when it does. Do not
  re-litigate the part the criteria already cover.
- **Conflicts** — stop and ask. A self-contradictory issue is not resolved by quietly picking
  whichever reading matches the change.

If the issue lists use cases but **no** acceptance criteria, there is no second list to map onto, so
the verdicts above do not apply — every one of them is defined against a criterion. Run the
acceptance-criteria pass over the use cases instead, exactly as written: each use case verbatim, one
verdict each (Met / Not met / Unverifiable), evidence as `file:line`, table every time. Label the
table as use cases, not criteria, so nobody reads it as something the issue asserted. Use cases are
descriptive rather than assertive, so a verdict against one is weaker evidence than a verdict
against a criterion — but dropping them entirely is worse. A contradiction _between_ two use cases
is still a stop-and-ask.

### UI principles — `[ui]`

Only when the change touches Vue components/templates, stylesheets, or translatable strings. These
expand the condensed list in `.dev/ai-agent-instructions.md`; read `frontend_patterns.md` for
everything else about Vue conventions.

They regress silently because the component still "works" — it just degrades accessibility, layout,
or translation quality for some users.

- **Icon-only action buttons** — a button/link whose only content is an icon (no visible text label)
  must carry a `v-tooltip` directive that also supplies the accessible name (e.g. an `aria-label`
  binding, or tooltip text that doubles as the label). Without it, screen reader users get an
  unlabeled control.
- **Hover/focus-only actions on touch devices** — elements revealed only via CSS `:hover` or
  `:focus-visible` (e.g. row actions appearing on table row hover) must still be reachable on touch
  devices, which have no hover state. Flag unless there is a fallback (a `(hover: hover)` /
  `(pointer: coarse)` media query, or the action is always shown at narrow viewports).
- **Container-based responsive grids** — a grid should adapt to the space actually available to it
  (its container), not just the viewport: CSS Grid with `repeat(auto-fit, minmax(...))` or container
  queries (`@container`), rather than a fixed column count that only changes at global viewport
  breakpoints. Flag grids that would break or waste space inside sidebars, modals or split panes.
- **Translatable strings** — new or changed user-facing strings (`$t('...')` / `i18n.t('...')`,
  locale keys) should:
  - be complete and meaningful, avoiding single standalone words (e.g. `t('Name')`), since
    translators lack the surrounding context to disambiguate them;
  - use sentence case for English source strings (only the first word and proper nouns
    capitalised), not Title Case;
  - not duplicate an existing string. Before accepting a _new_ string, grep for the literal text in
    other `$t(...)` / `i18n.t(...)` calls or the base locale file. If a near-identical string
    exists, flag the new one as a duplicate and suggest reusing it — every distinct string adds
    translator workload across all supported languages.
  - Never flag a change to `i18n/*.po` as the fix. Those files are managed externally.

### Backend — `[backend]`

The conventions live in the sibling files routed in Step 1 — read those rather than reviewing Rails
practice from memory. Beyond them, the recurring concerns worth checking:

- **Query shape** — new associations rendered in a loop without `includes`/`preload` (N+1), a column
  introduced for lookup or filtering without an index, queries inside view or serializer code.
- **Authorization** — new controller actions, GraphQL fields or mutations that reach data without
  going through a Pundit policy. This is `[security] P0`, not `[backend]`, when data is exposed.
- **Background jobs** — jobs that are not idempotent, that carry state across a retry, or that
  assume the record still exists when they run.

### Tests — `[test]`

New public behaviour should have tests: new public methods, new components, new endpoints, new
GraphQL fields. A bug fix should have a regression test that fails without the fix.

`testing.md` covers how tests are written and run here. Flag the gap; do not write
the test as part of a review.

### Leftover artifacts and cleanup — `[cleanup]`

- Debug code, `console.log`, `binding.pry`, commented-out blocks, TODOs introduced by this change.
- Dead code the change orphaned — a method that is now unused, an import that is now unreferenced.
- Obvious duplication introduced by the change, and unnecessary complexity.

This matters most when reviewing an agent's own output, where scaffolding tends to survive into the
diff.
