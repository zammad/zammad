# Zammad Product Principles

What the product holds to be true, in a form a story can be checked against.

Every principle is an **assertion plus what it rules out**. The second half is what does the work: it
says what a violation looks like. A statement nothing could violate — "we value a consistent user
experience" — is decoration, and it makes this file worse, because it trains readers to skim and it
lets a tool generate findings nobody can act on.

This file is **not** the coding conventions. Its sibling files in this directory are the conventions;
this file is about the product, and most of its content was extracted from decisions the team had
already taken and documented once, in `BREAKING_CHANGES.md` or in a single story, where the next
story could not find it.

## Consumers

| Consumer             | Lives in    | Uses these principles for                                    |
| -------------------- | ----------- | ------------------------------------------------------------ |
| `refine-story` skill | skills repo | Checking a story and its design against the product's stance |

## How to cite and change

- IDs are **section-prefixed and append-only**: `CHANGE-1`, `UI-5`. Cite as
  `.dev/agent_docs/product_principles.md#CHANGE-1` — the repository-relative path, because most
  citations are written from outside this directory.
- The `#ID` suffix is a **stable citation token, not a Markdown anchor**. The IDs are bold list
  items, and an explicit anchor would need inline HTML, which this repository's `markdownlint`
  configuration rejects.
- A citation therefore resolves by **searching for the list item that defines the ID** — a line
  starting `- **` followed by the ID and then either `**` or a space, as in `- **CHANGE-1**` or
  `- **UI-6 (proposed)**`. That line is unique for every ID in this file. Searching for the bare ID
  is not deterministic: it also matches this section, and it prefix-matches a future `CHANGE-10`.
- Do not "fix" the missing anchor by promoting the IDs to headings. A heading anchor is derived from
  the heading text, so it would break on every wording change — the opposite of what the next rule
  guarantees.
- **Never renumber.** The change and dependency principles get cited outside this file — in a
  `BREAKING_CHANGES.md` entry, a review comment, a refinement note — so an old citation has to keep
  resolving.
- A principle that no longer holds keeps its ID and is marked `(retired)` with the date. It is not
  deleted.
- Anything genuinely undecided goes in **Unsettled** at the bottom rather than being guessed at. A
  consumer reading this file must be able to tell "we decided against it" from "we never decided".

---

## How we change things

Owner: development · last reviewed 2026-08

- **CHANGE-1** — Nothing is removed, renamed or restricted without a deprecation announced at least
  one release earlier. _Violation: a removal whose first appearance in `BREAKING_CHANGES.md` is the
  release that removes it._
- **CHANGE-2** — Every breaking change states who is affected, what they have to do, and links a
  public issue. _Violation: an entry that describes the change but not the action, or that has no
  public issue to point at._
- **CHANGE-3** — Only versions the vendor still maintains are supported, for every dependency —
  database, search index, Redis, Node, browsers, reverse proxy. The supported matrix stays small and
  predictable for administrators. _Violation: keeping compatibility with an end-of-life version in
  order to avoid a breaking change._
- **CHANGE-4** — Prefer one general mechanism over several bespoke ones. Where a general mechanism
  covers what a special-cased feature did, the special case is a candidate for removal. This is a
  preference and a judgement call, not an automatic verdict: _a new special case for something an
  existing general mechanism already does is worth questioning, not automatically wrong._
- **CHANGE-5** — Every removal names its replacement, or states explicitly that there is none.
  _Violation: "X was removed" with no forward path and no admission that there isn't one._

## Access and permissions

Owner: development · last reviewed 2026-08

- **ACCESS-1** — Access is least-privilege and explicit, and tightening it is worth a breaking
  change. _Violation: a new endpoint, field or action that is reachable more widely than the data it
  exposes justifies, or a permission left broad because narrowing it would break someone._

## Defaults and configuration

Owner: product · last reviewed 2026-08

- **DEFAULT-1** — Defaults move toward the safe value, even when that breaks someone. _Violation: an
  unsafe default kept for compatibility._
- **DEFAULT-2** — Prefer a single behaviour that fits most users of the product over a new setting. A
  setting is the right answer when installations genuinely differ, not when a decision is hard to
  make. Configuration growing over a product's lifecycle is normal, so this is a preference and not a
  prohibition: _a new setting whose justification is "people will disagree" is worth questioning; one
  whose justification is a real difference between installations is not._

## Interface

Owner: product & UX · last reviewed 2026-08

- **UI-1** — Icon-only controls carry their accessible name. _Violation: a button whose only content
  is an icon and that has no tooltip or label supplying the name._
- **UI-2** — Actions revealed only on hover or focus are reachable on touch devices. _Violation: a
  row action that exists only behind `:hover`._
- **UI-3** — Responsive layouts adapt to the space their container actually has, not to the viewport.
  _Violation: a fixed column count that only changes at global breakpoints, inside something that can
  sit in a sidebar, a modal or a split pane._
- **UI-4** — In the contexts that use the taskbar — tickets, and the knowledge base in the new
  desktop view — work that auto-saves and has to survive the user switching to another context for a
  moment lives in a taskbar tab. The taskbar is not the container for everything; it is the container
  for resumable work in those contexts. _Violation: putting auto-saving, resumable work in a modal or
  a flyout that cannot be left open._
- **UI-5** — An action that deletes, removes or discards something the user cannot get back is
  confirmed before it happens, through the shared confirmation dialog. _Violation: a delete that goes
  straight through, or a bespoke confirm dialog next to the shared one._

## Deployment

Owner: development · last reviewed 2026-08

- **DEPLOY-1** — What the application is made of is decided at **build time**. A running instance
  never mutates its own application files, and a container least of all. _Violation: any feature that
  writes into the application directory at runtime and expects it to survive — installing a package,
  dropping in a custom file override, generating assets in place._

  Worth stating rather than assuming, because the codebase already contradicts it:
  `app/models/package.rb` writes to `Rails.root` on install and uninstall, and reads
  `auto_install/`. That mechanism predates containers being a supported deployment.

  This principle rules the runtime write **out**. It says nothing about what replaces it — which of
  an image layer, a mount or a documented build step is the supported answer is **unsettled**, so
  treat a story that proposes one of them as touching an open question rather than as aligned.

## Language and localisation

Owner: product · last reviewed 2026-08

- **LANG-1** — Source strings are complete, meaningful sentences in sentence case. _Violation: a
  single standalone word as a translatable string — translators have no context to disambiguate it._
- **LANG-2** — An existing string is reused rather than a near-duplicate introduced. _Violation: a
  new string that differs from an existing one only in punctuation or word order; every distinct
  string is work in every supported language._
- **LANG-3** — Translations come from translations.zammad.org. _Violation: editing `i18n/*.po`
  directly, or proposing that as the fix for a wording problem._
- **LANG-4** — Locale codes follow the standard, even when correcting one is a breaking change.
  _Violation: keeping a wrong locale code because changing it would affect existing installations._

## Honesty about what the system does

Owner: product · last reviewed 2026-08

- **HONEST-1** — Labels describe what the system actually did, not the most impressive reading of it.
  In particular, AI is not claimed for mechanical behaviour: a similarity search is presented as
  knowledge, not as AI understanding. _Violation: wording that implies reasoning where there is
  retrieval, or that credits AI for a step it only fed into._

  This is the one principle in the file that cost a whole story to learn — `zammad/zammad#6323`
  renamed "Suggested by AI" to "Suggested knowledge" because the label overstated a similarity
  search. It is also the product-level form of the company's stated commitment to AI that is "safe,
  transparent, and aligned with our values".

## Stack direction

Owner: development · last reviewed 2026-08

- **STACK-1** — New features target Vue 3 and GraphQL. _Violation: new behaviour built on REST and
  the legacy CoffeeScript interface without a stated reason, such as extending existing legacy
  behaviour._

---

## Unsettled

Questions this file cannot answer yet. A consumer that hits one of these **raises it as a question
for a human** — it must not produce a verdict, and it must not infer the answer from the shape of the
existing code.

- **ACCESS-2 (proposed)** — Should every new surface have to state which roles can see and use it,
  including the granular-permission case? "Agents" would not be an acceptable answer.
- **UI-6 (proposed)** — Should new UI be required to compose existing design-system components and
  tokens, with a new primitive treated as a decision rather than a detail?
- **UI-7 (proposed)** — Should a resumable view offer its own taskbar-behaviour-on-update setting,
  stored independently per view? Seen once, in
  `zammad/coordination-desktop-view#785`; unclear whether it generalises.
- **When is a new setting justified?** `DEFAULT-2` states the preference but not the test. There are
  ~300 settings today, so a usable criterion would have real leverage.
- **Are bulk or batch variants expected** for single-record actions, or added only on demand?
- **Where does deferred or scheduled state belong** in the interface? `#785` grew a whole scheduled
  visibility capability, which suggests there is no settled pattern for it yet.
- **How much of the legacy interface does a new feature have to reach**, and when is parity
  explicitly not required?
- **How custom file overrides and packages are meant to work in a container**, given `DEPLOY-1`.
  The principle says a runtime write is out; it does not say which of an image layer, a mount or a
  build step is the answer. `zammad/zammad#6229` is blocked on exactly that choice.
- **Product direction beyond the above.** The company vision — democratising customer service,
  transparency, open source, data protection — is real but not story-level: nothing in a story can
  violate it. Whatever exists as actual direction is not written down anywhere in this repository
  yet, and until it is, alignment with it is a question for product, never a finding.
