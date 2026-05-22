# Plan: Agent Console Redesign (CSS-only Reskin)

## Status

Approved — implementation scope chosen: CSS-only reskin of all five
agent-facing surfaces. No controller or template rewrites of the
manage / settings pages (those touch auth/permissions/channels per
CLAUDE.md governance).

## Why

The wireframe at `~/Desktop/Agent Console.html` + `agent-styles.css`
+ `agent-{app,screens,detail,manage,data}.jsx` describes a refreshed
agent console with:

- 220 px branded sidebar (logo + "Helpdesk / Agent console") with
  three sections: main nav, Queues (with live counts), Admin.
- Dashboard with metric tiles, queue cards, and an awaiting-you list.
- Overviews as a card-style ticket list.
- Ticket detail as a threaded conversation with internal-note
  differentiation and a refined attribute sidebar.
- Manage pages (Users / Channels / Branding / System / Security / API)
  as a two-pane settings layout.

Same `oklch()`-derived token system as the customer portal (already
in `body.is-customer-portal`). The agent variant uses an `--ac-*`
prefix and scopes under a new `body.is-agent-console` class so the
two themes don't leak into each other and agent rules don't affect
anonymous (login) pages.

## Constraints from CLAUDE.md governance

- Each phase = one branch / one PR / one merge. <300 lines ideal.
- "Automerge MUST be disabled for: auth, permissions, uploads,
  email parsing, ticket routing, background jobs, webhooks, AI
  integrations, infra/docker/k8s, secrets/config" — Manage pages
  cross many of these surfaces. **CSS-only reskin** is in-scope;
  template/controller rewrites of Manage pages are explicitly out.
- "Agents MUST NOT redesign architecture silently" — this plan is
  the explicit record.

## Scope (5 phases, separately merged)

### Phase 1 — Theme tokens + sidebar reskin

- Add a `body.is-agent-console` class toggle in
  `_plugin/navigation.coffee` (set when the user has `ticket.agent`
  permission and the customer-portal class is not active).
- Add an `--ac-*` token set (light surfaces, indigo accent, etc.)
  + sidebar layout overrides in `zammad.scss`, all scoped under
  `body.is-agent-console`.
- Brand block at top of nav: small logo + "Helpdesk" + the existing
  `Setting.get('organization')` as subtitle (or a literal "Agent
  console" if `organization` is blank).
- Nav-section "Queues" / "Admin" headings injected via CSS
  pseudo-elements where existing NavBar items naturally group
  (no template rewrite required).

### Phase 2 — Agent dashboard restyle

- Restyle `App.Dashboard`'s rendered HTML (`app/views/dashboard*`)
  via scoped CSS only. Card aesthetic on `.stat-widgets`, refined
  type, dashboard-matching page header.

### Phase 3 — Overviews restyle

- Already partially covered by `body.is-customer-portal` rules
  (the table card layout from Phase 3 of the customer portal).
- Apply the same card style for agents under `body.is-agent-console`
  but **keep the per-page overview sidebar** (agents do use it).
- Tighten typography to match the wireframe.

### Phase 4 — Ticket detail restyle

- Mirror customer-portal Phase 4 (article cards, dashboard-matching
  header) for agents under `body.is-agent-console`.
- Visual differentiation for internal notes vs public replies via
  existing `.internal` / `.no-internal` classes Zammad already
  emits — no template change.

### Phase 5 — Manage pages restyle

- Apply card aesthetic + type pass on `#manage/*` and `#system/*`
  pages via CSS scoped under `body.is-agent-console`.
- No template/controller changes.
- Hard rule: any rule that would visually mask validation errors,
  warning banners, or destructive action affordances is **out of
  scope**.

## Out of scope

- Vue 3 desktop / mobile apps (separate codebase).
- New backend behavior; new GraphQL/REST endpoints.
- Workflow changes (which group sees what, which agent owns what).
- Custom Manage-page templates or controllers.
- Login page — kept as the existing Zammad login.

## Risk per CLAUDE.md governance

- All changes are CSS in `app/assets/stylesheets/zammad.scss` plus a
  body-class toggle in `_plugin/navigation.coffee`. No DB, no schema,
  no REST/GraphQL, no permission changes, no migrations.
- Asset cache must invalidate on each phase merge (existing CSS
  cache-busting via ETag works correctly per current dev verification).
- Customer portal styles already exist under `body.is-customer-portal`
  and don't conflict because the body class is mutually exclusive.

## Test plan

Per phase:
- Manual: log in as agent (`admin@local.test`) at
  http://localhost:3188, walk the affected screens, screenshot.
- Manual: log in as customer (`waye@mports.com`), confirm the
  customer portal is **byte-identical** to before (no agent
  styles bleed across).
- Manual: log out, confirm the anonymous login screen has no
  agent-console body class applied.

## Rollback

Each phase is one merge commit. `git revert <merge sha>` reverts.
No DB or schema state to undo.

## Sequence

1. This plan committed and merged first.
2. Phases 1–5 land in order, each its own PR.
