# Plan: Agent Console — Faithful CoffeeScript Port (v2)

## Status

Approved — user picked Path A (faithful CoffeeScript) from
`docs/ui-references/AGENT-CONSOLE-FINDINGS.md`. Dashboard first,
SLA "at risk" via a new REST endpoint, CSAT widget skipped.

## Why this plan replaces the prior agent-console-redesign.md

The prior plan was CSS-only. PRs #9–#13 implemented it and have been
reverted in #15 because the wireframe DOM is structurally different
from Zammad's existing DOM — CSS retint of the wrong DOM produced
nothing close to the design.

This plan rebuilds each agent surface as new controllers + views +
SCSS that emit the wireframe DOM directly.

## Source of truth

`docs/ui-references/agent-console/` — HTML + agent-styles.css +
6 JSX files. Every implementation phase below must visually match
the corresponding screen there.

## Stack

CoffeeScript + REST (existing Zammad legacy frontend), as decided.

## Phased scope (each = one PR)

Phases land in this order. Each <600 lines per CLAUDE.md small-PR
preference; if a phase grows beyond that, it splits.

### Phase 1 — SLA-at-risk REST endpoint (backend)

- New `Agent::DashboardController` in `app/controllers/agent_dashboard_controller.rb`.
- Action `sla_at_risk` → returns up to 10 tickets with
  `escalation_at IS NOT NULL` ordered by `escalation_at ASC`,
  filtered to states the agent can view, with attributes the
  dashboard needs (id, number, title, customer name, group,
  escalation_at, state, priority).
- Route: `GET /api/v1/agent_dashboard/sla_at_risk`.
- Permission: `ticket.agent`.
- Spec: `spec/requests/agent_dashboard_spec.rb` (existence, perm,
  ordering, viewable-only).

### Phase 2 — Workload REST endpoint (backend)

- Action `workload` → returns
  `[{agent_id, name, open_count}, …]` for every active agent,
  open_count = tickets currently in `open` or `pending reminder`
  state assigned to that agent.
- Route: `GET /api/v1/agent_dashboard/workload`.
- Permission: `ticket.agent`.
- Spec.

### Phase 3 — Dashboard frontend (the visible win)

- New CoffeeScript controller `App.AgentDashboardFaithful` in
  `app/assets/javascripts/app/controllers/agent_dashboard_faithful.coffee`
  (faithful suffix to avoid clashing with the existing `App.Dashboard`
  used by other roles).
- New view `customer_dashboard_faithful.jst.eco` — wait, **agent**
  dashboard. `agent_dashboard_faithful.jst.eco`. Renders the exact
  wireframe layout:
  - Header: kicker "Agent console" + "Good afternoon, {firstname}"
    + ghost button "Open overviews" + primary "+ New ticket"
  - 4-metric grid:
    - My open (count from `my_assigned` overview, filter to open/pending)
    - Avg handle time (placeholder — Zammad reporting not exposed yet;
      show "—" with tooltip explaining)
    - First-reply rate (same — placeholder)
    - CSAT (30d) → **skipped per decision; the 4th tile becomes
      "Unassigned open" count instead**
  - "My open tickets" card with SLA chips
  - "Unassigned & open" card with Claim button
  - Right sidebar (`.dash-aside`):
    - "SLA at risk" — feeds from REST `sla_at_risk`
    - "Team workload" — feeds from REST `workload`
    - "Recent activity" — feeds from existing
      `Ticket::Article` history (closest existing data source)
- Dispatch from `DashboardRouter` (already role-aware from the
  customer portal redesign) so users with `ticket.agent` see
  `AgentDashboardFaithful` instead of `App.Dashboard`.
- New SCSS section copying tokens + layout from
  `docs/ui-references/agent-console/agent-styles.css`, scoped under
  `body.is-agent-console` (the body-class infrastructure is re-added
  in this phase, since the revert removed it).
- Icons: add new SVG paths to the icon library for `dashboard`,
  `inbox`, `flag`, `clock`, `settings`, `logout` if not already
  present.

### Phase 4 — Overviews queue list (visible win #2)

- Reskin the `#ticket/view/:view` route for agents to use the
  wireframe's card list when the user is an agent (mirror of the
  customer portal Phase 3 pattern). Per-row state pill, priority
  pill, last-update relative time. Multi-select stays for agents.

### Phase 5 — Ticket detail 3-column

- New view + controller for agents that re-orders the existing
  ticket-zoom regions into queue / conversation / metadata columns
  per the wireframe. Largest single PR; will likely split.

### Phase 6 — Manage two-pane

- Light visual restyle of `#manage/*` pages (NavBarAdmin sidebar +
  main content) to the two-pane wireframe layout. CSS-only is fine
  here since the existing manage DOM matches well enough — same
  pattern that worked for the customer portal manage hint.

## Decisions confirmed by user

- Path A (faithful CoffeeScript), not Vue 3 / vendored React.
- Dashboard first.
- SLA "at risk" → **new REST endpoint** (Phase 1).
- CSAT widget → **skipped**; replaced with "Unassigned open" count.
- Prior CSS-only PRs (#9–#13) → **reverted in #15**.

## Out of scope

- Vue 3 desktop agent app.
- New customer portal work (already shipped, untouched here).
- Login page redesign.
- GraphQL changes.
- Background jobs / email parsing / webhooks per CLAUDE.md
  automerge-disabled list — explicitly not touched.
- "Tweaks" panel (wireframe authoring tool only).

## Risk per CLAUDE.md governance

- Two new REST endpoints under `/api/v1/agent_dashboard/` — read-only
  GETs on existing data. No new permissions, no new tables, no
  destructive operations. Spec coverage included.
- Reuses existing `Auth` / `Pundit` chain via `ticket.agent`
  permission check.
- New view templates only emit data the agent already has access to
  via existing REST.
- No migrations.

## Rollback

Each phase = one merge commit. `git revert <sha>` reverts.

## Sequence

1. Phase 1 (SLA REST + spec).
2. Phase 2 (workload REST + spec).
3. Phase 3 (dashboard frontend).
4. Phase 4 (overviews queue list).
5. Phase 5 (ticket detail).
6. Phase 6 (manage two-pane).
