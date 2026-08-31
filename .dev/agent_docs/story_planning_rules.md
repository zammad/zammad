# Zammad Story Rules

Single source of truth for when a story is ready to be planned, how it is sized, and what its plan
has to cover.

This file is **tool-neutral on purpose**. It says nothing about `gh`, GitHub issue types, board
columns, sub-issue mechanics or output format — those belong to whichever caller is using these
rules.

It is also **not a duplicate of the coding conventions**. Its sibling files in this directory are
the conventions; this file says which of them a plan has to account for, and it is the counterpart
of `code_review_rules.md` at the other end of the lifecycle: the same acceptance criteria that are
verified there are shaped and mapped here.

## Consumers

| Consumer             | Lives in    | Uses these rules for                                    |
| -------------------- | ----------- | ------------------------------------------------------- |
| `refine-story` skill | skills repo | Checking and improving a story before it can be planned |
| `plan-story` skill   | skills repo | Cutting a ready story into sub-issues and its plan      |

When a rule changes, it changes **here** and every consumer picks it up. Do not copy rule text into
a consumer.

---

## Step 1 — Definition of ready

A story is plannable when someone can cut it into work without inventing the story first. Two
groups of checks; the mechanical ones are cheap and unambiguous, the judgement ones are not.

These checks are defined for **stories**. A bug has no user story and no acceptance criteria by
design, so M2 and M3 can never pass for one and gating on them would be meaningless. For anything
that is not a story, report the definition of ready as not applicable rather than as failed.

**Mechanical** — a caller may enforce these before anything else runs:

- **M1** The body is not a placeholder: it is non-empty, it is not `TBD`, `TDB` or `?` as its
  entire content, and it carries **200 characters of prose or more** (fewer than 200 fails; exactly
  200 passes). Prose is what remains after removing headings, code blocks, HTML comments, list
  markers, emphasis and heading markup, and link and image syntax — link text counts, the URL does
  not — and after collapsing every run of whitespace to a single space.
- **M2** A user story is present — a role, an action and a benefit, in whatever wording.
- **M3** An acceptance-criteria section is present. Heading wording varies
  (`## Acceptance criteria`, `### Acceptance Criteria`); match tolerantly.
- **M4** At least two criteria, each an assertion rather than a question.
- **M5** No unresolved blocking item under a `Clarification needed` heading. Anything in that section
  that is not a ticked task item (`- [x]` or `1. [x]`) counts as open. An open item is blocking
  unless its text contains `non-blocking` or `blocks planning: no` — those two markers exactly, so
  that two callers reading the same item reach the same verdict. Prose in the section with no list
  items at all counts as one open blocking item, because a section that had nothing left to settle
  would have been removed.

**Judgement** — decided by reading, never by pattern matching:

- **J1** Every criterion is verifiable: it states an observable outcome, not an intention.
- **J2** Scope is bounded. A criterion that delegates its own scope — "any other relevant surface",
  "and wherever else this appears" — is not ready, because whoever plans it inherits an open search.
- **J3** Criteria do not contradict each other or the user story.
- **J4** Where the story is about UI, a design is linked and it is the current one (see Step 3).
- **J5** Open questions are stated as questions rather than implied by vague wording.
- **J6** No question anywhere on the story is left unanswered — and open questions belong under
  `Clarification needed` in the body, not in a comment, so that answering one removes it.

### Verdicts

| Verdict             | Meaning                                                              |
| ------------------- | -------------------------------------------------------------------- |
| **Ready**           | plan it                                                              |
| **Ready with gaps** | plannable, but named gaps go to their owner first — ask before cutting |
| **Not ready**       | do not plan. The list of failures _is_ the refinement to-do list      |

A **Not ready** story is not a failure of the caller. Producing a confident plan from an unshaped
story is worse than producing nothing, because the plan then looks like a decision that was taken.

### Decisions taken outside the issue

A decision made in a meeting, a chat or a call is **not a decision** until it is written in the
story or in a comment on it. Everything downstream of this file reads the issue and its comments as
the record. If a criterion is known to be settled but nothing on the issue says so, that is an
unanswered question, not a settled one.

Where the body and a comment disagree, the **comment wins** — a body describing the
pre-discussion state is normal.

---

## Step 2 — Story size

> **A shared prerequisite is a dependency, not a scope boundary.**

This is the rule that matters most, and the one most often broken. Several capabilities that each
need the same base to exist are not one story. They are one base story plus several stories that
depend on it.

### The per-criterion test

This is a **closed checklist, not an impression**. For every acceptance criterion, write the single
sentence that connects it to the story's own outcome, then classify it:

| The sentence is…                                 | Then                                       |
| ------------------------------------------------ | ------------------------------------------ |
| "it also changes another view or object"         | separate story — its scope left this story |
| "it needs the base to exist"                     | separate story, with a dependency          |
| "the story's outcome is not achieved without it" | it stays                                   |
| neither, or unclear                              | an open question, not a silent decision    |

The rows are in **precedence order, and the first one that applies decides**. A criterion can
truthfully match more than one — something required for the outcome can still reach another view —
and without an order two callers classify the same story differently. The two separating tests
therefore run before the keeping one: a criterion stays only when neither of them fires.

Where the first two rows both apply, the result is still one separate story, and **both** facts get
recorded: the dependency, because the order of work depends on it, and the scope reach, because that
is the part product has to hear.

Every criterion gets exactly one classification. A criterion that cannot be classified is itself a
finding.

### Signals that a story is too big

Two or more firing is a conversation, not a footnote:

- More criteria than roughly five, or criteria carrying sub-bullets of their own.
- A criterion naming a capability the title does not imply.
- A criterion whose scope reaches outside the story's own object or view.
- More than one outstanding UX decision.
- More than one surface affected (desktop, mobile, legacy interface, public help site).
- A criterion needing its own backend surface — a new model, a new mutation, a new endpoint.
- More than one spike needed before the story can be planned at all.
- A blocked criterion holding unblocked criteria hostage.

That last one is the real cost, and it is easy to miss because nothing looks wrong. One unresolved
UX decision on one criterion delays every other criterion in the same story.

### Splitting is cheap

Issue types are `Epic` → `Story` → `Task`, with `Spike` a sibling of `Task` under the same story
(Step 6), and the Epic level is in active use. A story split into three stories under the same Epic
changes nothing about the hierarchy, the board or product's view of the work. What changes is that
each piece carries its own criteria and can ship on its own.

### What may not become a story

A **layer slice** can never be a story. "Add the service and the mutation" has no role, no benefit
and nothing observable — forcing it into story form produces a fake user story, which is worse than
a large one. Layer slices are tasks. Split stories along capability and surface seams only.

### Worked example — `zammad/coordination-desktop-view#785`

"Edit an answer of the knowledge base", one story, sixteen tasks, one very large merge request.
Its criteria classified by the test above:

| Proposed story                          | Criteria                           | Why separate                       |
| --------------------------------------- | ---------------------------------- | ---------------------------------- |
| Edit an answer                          | new editor, auto-save, own taskbar | this _is_ the outcome              |
| Manage tags and attachments of an answer | tags, attachments                  | needs the base only                |
| Link related tickets to an answer       | links                              | needs the base only                |
| Show live users on the edit tab         | live users                         | needs the base only                |
| Warn when an answer was edited meanwhile | concurrent-edit warning            | needs the base only — blocked on UX |
| Configure taskbar behaviour on update   | taskbar selector                   | also changes the _Add answer_ view |
| Schedule visibility changes             | added a month after planning       | own capability, own backend surface |

Seven stories where there was one. Only the first four words of the original title survive as the
base story. The concurrent-edit warning was blocked on a UX decision and, in the single-story
shape, blocked everything else with it.

The story also grew from ten to sixteen sub-issues after it was planned, because a new capability
was added as tasks rather than raised as a story. **The size check therefore runs again whenever a
breakdown is extended**, not only before the first cut.

---

## Step 3 — Alignment: criteria, use cases, design

Three lists, written at three different moments by three different people, and they drift. This step
is a **closed cross-check between lists that already exist**, in three directions — never a fresh
search for behaviour nobody asked for.

### Which design

Collect every design link from the body **and every comment**. The most recent link wins; an earlier
one is superseded, and a superseded link that is still in the body is itself a finding. If the
design cannot be read — no connector, no access — say so explicitly and mark every check in this
step as **not run**. Never infer a design's contents from the story's prose.

### Direction 1 — design → criteria

Something is drawn that no criterion asserts.

| Verdict            | Meaning                                                     |
| ------------------ | ----------------------------------------------------------- |
| Asserted           | a criterion covers it — cite the criterion                  |
| Missing a criterion | the design is right and the criteria are incomplete         |
| Design overreach   | the design went beyond what the story asked for             |

The two gaps have different owners, and collapsing them is what makes a refinement unactionable.
"Missing a criterion" is work for whoever writes the story; "design overreach" is a scope
conversation.

### Direction 2 — criteria → design

Something is asserted that is not drawn.

| Verdict         | Meaning                                            |
| --------------- | -------------------------------------------------- |
| Drawn           | the design covers it                               |
| Not drawn       | UX work outstanding — name it                      |
| Not applicable  | the criterion has no UI (backend, API, deprecation) |

"Not applicable" must be stated, not assumed. It is the verdict that gets skipped silently.

### Direction 3 — states the design does not contain

The most expensive failures are not disagreements between the lists — they are states nobody drew
and nobody wrote down, found during implementation or in review. Walk this list as a closed
checklist and give each row a verdict, including "not applicable":

- empty state
- loading state
- error and validation states
- permission-denied — and for which roles, including granular permissions
- long content, truncation, overflow
- zero vs one vs many
- disabled state
- unsaved changes when leaving
- concurrent edit by a second user
- narrow viewport and mobile
- dark mode
- keyboard operation and focus order
- accessible name for icon-only controls
- translation length, where a longer language breaks the layout

The UI rules that apply to each of these are in `code_review_rules.md` under **UI principles**, and
the condensed list is in `.dev/ai-agent-instructions.md`. Do not restate them; check against them.

### Direction 4 — use cases → criteria

Where the story states use cases separately from its criteria, run the mapping described in
`code_review_rules.md` under **Use-case cross-check**. It is defined there for review; the verdicts
and their meanings are identical here, one stage earlier, and a gap found here costs nothing to fix.

---

## Step 4 — Affected layers

Task breakdown is open-ended imagination, and open-ended imagination misses things. The structural
fix is a closed list.

Walk **every** row. Give each one a verdict, and **write the negative verdicts out** — "not
affected" with its reason is the whole point, because a row that is silently skipped was never
considered. Read the routed document only for rows that come out affected.

| Layer                                                       | Read                        |
| ----------------------------------------------------------- | --------------------------- |
| Data model, migration, seeds                                | `database_migrations.md`    |
| Model behaviour, validations, legacy REST/notification concerns | `legacy_model_patterns.md` |
| Authorization — policies, permissions, granular roles        | —                           |
| Service objects                                             | `service_patterns.md`       |
| GraphQL — types, mutations, queries, subscriptions           | `graphql_patterns.md`       |
| Form updater / Core Workflow                                 | `frontend_patterns.md`      |
| Vue frontend — name which apps (desktop, mobile, shared)      | `frontend_patterns.md`      |
| Addon layer                                                  | `frontend_addon_layer.md`   |
| Legacy CoffeeScript interface and its REST controllers       | —                           |
| Real time — subscriptions, taskbar, live users, concurrent edit | —                        |
| Search index                                                | —                           |
| Background jobs and the scheduler                            | —                           |
| Settings, defaults, feature flags                            | —                           |
| Translations — new or changed source strings                 | `code_review_rules.md`      |
| Tests — backend, frontend, system                            | `testing.md`                |
| Documentation — admin docs, system requirements               | —                           |
| Breaking changes                                             | `BREAKING_CHANGES.md`       |

Two rows are missed most often and are worth naming: **authorization**, because a feature works
perfectly while being visible to the wrong role, and **breaking changes**, because nothing in the
diff looks like a breaking change. A story that removes, renames, restricts or raises anything needs
a `BREAKING_CHANGES.md` entry, and that entry is work in its own right.

Where a row is affected but cannot yet be planned, it becomes a **spike** — a piece of work whose
output is an answer, not a change. What a spike issue contains is in Step 6. Never hide an
unresolved question inside an implementation task.

---

## Step 5 — Depth of the plan

The plan exists so that whoever implements — a person or an agent — does not repeat the research,
and so that the review afterwards has something concrete to check the result against. It is not a
pre-written diff.

Go to code level **only** when one of these is true:

1. **The obvious reference diverges** — the thing that looks right to copy is the wrong thing.
2. **There is a trap** — something that looks right and is not, or something that must explicitly
   not be done, and why.
3. **An ordering or invariant constraint** that could not be inferred from reading the files.
4. **A decision was already taken**, with its reason, so nobody re-litigates it and the reviewer can
   check the result against it.

Everything else is an anchor: the reference implementation to follow, the files and areas touched,
the specs to write, the open questions. Name the anchor and stop.

The test on any bullet is _which of the four reasons is this here for?_ If the answer is
"completeness", delete it. Argument lists, method signatures and file skeletons are derivable from
the reference implementation faster than they can be written down, and they are wrong by the time
anyone reads them.

Depth is **earned by risk**, never applied uniformly. A layer whose verdict in Step 4 came out clean
and boring gets an anchor and one line. A layer with a trap gets as much as the trap needs.

---

## Step 6 — What a task issue contains

Two audiences: a human who wants to know in thirty seconds what this is and why it exists, and
whoever implements it, starting from the body without redoing the research.

In this order:

1. **Lead paragraph** — what this piece of work is and where it sits: the reference implementation
   it follows, the sibling it stays in sync with, the state of the code today. No heading.
2. **The plan** — grouped by file or area, at the depth Step 5 allows.
3. **Done means** — one sentence naming the observable state that makes this task finished. This is
   what a reviewer judges against, and what an implementing agent stops at. It is not a copy of the
   story's acceptance criteria.
4. **Open questions** — real ones only, each with a recommendation and, if it blocks, who decides.
   Never a question without a proposed answer.
5. **Tests** — the spec files to add or extend and the cases they must cover, including edge cases
   found during research. Say when coverage does not exist today.
6. **Dependencies** — what exactly is needed from which sibling. Only for siblings that already
   exist; refer to not-yet-created ones in prose.
7. **Parent reference** — always the last line.

Sections 1, 3, 5 and 7 are mandatory. A small task is a lead paragraph, three bullets, a "Done
means" line, a "Tests" line and the parent reference.

### Rules

- **Nothing invented.** Every path, class, setting and pattern named in the plan was opened in the
  checkout. If something could not be verified, say so in that bullet.
- **No copy of the story.** The task states what _it_ changes; the story is one click away.
- **No estimates, no assignees, no due dates.** That is the board's job.
- **No customer or personal data**, and no reference to a private support ticket beyond its number.
- One task is what one person can finish without waiting on a sibling, and what a reviewer can judge
  on its own. It is deliberately **not** defined in terms of merge requests — how the work is
  branched and merged is a separate decision that does not belong in a breakdown.

### What a spike issue contains

A **spike** is an issue type of its own, a sibling of `Task` under the same story — not a task with
a different name. Its output is an **answer**, so the task contract above does not fit it: there is
no plan of how to solve the thing, because what to solve is the open question. A spike carries:

1. **The question** — one sentence, answerable, naming the decision it unblocks.
2. **Why it cannot be answered now** — what was already read or tried, so the spike does not start
   from zero.
3. **What an answer looks like** — the form the result has to take: a recommendation with its
   reason, a measurement, a throwaway proof of concept. Name which one.
4. **Done means** — the answer is written down _in the spike_, in its body or as a comment. A spike
   whose result exists only in someone's head is not finished, and a spike does not finish by
   producing production code.
5. **What it blocks** — the sibling tasks or criteria waiting on the answer. A spike that blocks
   nothing is research, and research is not part of a breakdown.
6. **Parent reference** — always the last line.

All six are mandatory; a spike is short enough that none of them is a burden. Its traceability runs
the other way round from a task's: a spike traces to the **question** — the criterion or the Step 4
layer verdict that could not be planned — not to a criterion it implements.

### Coverage before anything is created

- Every acceptance criterion is covered by at least one task, and every task traces to a criterion.
  A task tracing to nothing is either invented work or a criterion nobody wrote down — both are
  findings, not things to resolve silently. A criterion that is blocked by a spike is covered by
  that spike for now, and the fact that it has no task yet is recorded, not left to be noticed.
- Every layer verdict from Step 4 is reflected: affected rows have a task, unaffected rows are
  recorded as unaffected. An affected row that cannot be planned yet is covered by the **blocking
  spike** instead — the spike names the row it holds, and the implementing task is created once the
  spike is answered. A row covered by neither is the gap this check exists to catch.
- Decisions taken in the story's comments are reflected, and outrank the body.
- What the story leaves out stays out. Where the story is vague, that becomes an open question in
  the affected task, not a silent decision.

---

## Step 7 — Writing back to the story

A caller may improve the story it is working on. Two sections behave differently, and the
distinction is not cosmetic.

**Acceptance criteria are a contract.** `code_review_rules.md` enumerates them verbatim and gives
each one a verdict, months later. Rewording a criterion silently changes what gets verified.
Criteria may only be added, changed or removed after an explicit confirmation from a human, one
change at a time, with the reason recorded.

A story may also carry a **`Solution outline`**: a few lines on which areas and layers are affected,
the shape of the approach, and what was ruled out. It is the only place the whole solution is visible
without opening every task. It names areas and decisions, never files, classes or methods — those
belong in the tasks, where they are checked against the checkout and can be corrected without
touching product's artefact.

**Everything else may be improved freely** — background information, technical notes, links, a scope
or out-of-scope section, a clarification section. Prefer adding a section over rewriting a
paragraph.

Mechanics that apply to any write-back:

- **Edit by section. Never regenerate the body.** Sections with nothing to add stay byte-identical.
- **Open questions live in the body, never in a comment.** They go under `Clarification needed`, as
  task items, because the body is current state: answering a question removes its item, and the
  answer becomes a criterion or background. A comment cannot do that — and comments are read
  downstream as settled context, so a question posted there is later taken for a decision.
- **A body edit notifies nobody, but a comment is not automatic.** Post one when the change would
  surprise somebody who read the story before: a criterion changed or removed, scope narrowed or
  widened, a decision that reverses an earlier one. An addition that fills a gap needs none — the
  body shows it and the edit history keeps it. Which of the two a given change is, is a judgement for
  the caller; this file does not try to decide it.
- **Never delete product's words** to make room. If the existing wording is wrong, propose the
  replacement; do not apply it silently.
- Splitting a story is a **product act**. Propose the split, never execute it.

---

## Alignment with product direction

Two different things get called this, and only one is checkable.

**Mechanically checkable, no extra source needed:**

- Does the design compose existing design-system components and tokens, or invent new ones? Whether
  composing them is _required_ is unsettled (`.dev/agent_docs/product_principles.md#UI-6`), so a new
  primitive is raised as a question for UX, never reported as a violation.
- Does a new source string near-duplicate an existing one? (`code_review_rules.md`, translatable
  strings.)
- Does the story build new behaviour on REST and the legacy CoffeeScript interface? New features
  target Vue 3 and GraphQL, but the principle keeps an exception, so this is a finding **only when
  the story states no reason** — extending existing legacy behaviour is a reason, and a stated one
  closes the check (`.dev/agent_docs/product_principles.md#STACK-1`).
- Does it need a pattern that does not exist in the codebase yet?

Two of these overlap a principle below. Where they do, the **principle's wording decides**,
exceptions included; the bullet is only the prompt to look.

**Checkable against `product_principles.md`**, in this directory: it states what the product holds to
be true, each principle as an assertion plus what it rules out, with stable IDs to cite
(`.dev/agent_docs/product_principles.md#UI-5`). Check against it; do not restate it here.

Its **Unsettled** section is as important as the rest. A story that touches one of those questions
gets a **question for a human**, never a verdict — and the distinction between "we decided against
it" and "we never decided" only exists because that section is written down. If the file is missing,
report product alignment as **not run**. Never reason about product direction from memory or from the
shape of the existing code.

---

## What none of this decides

- Which repository sub-issues are filed in, which board they land on, and in which column. That is
  team configuration and belongs to the caller.
- How the work is branched and merged.
- Sizing in points or days. Nothing here produces an estimate.
- Whether a story should exist at all. That is product's call, upstream of every rule in this file.
