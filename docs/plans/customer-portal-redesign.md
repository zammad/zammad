# Plan: Customer Portal Redesign

## Status

Draft — awaiting approval before implementation.

## Why

The customer-facing portal today is a thin re-use of the agent UI with
read-only permissions and the recent left-nav consolidation. It's
serviceable but not designed for end-users:

- No dashboard / landing — customers drop straight into a table of their
  tickets with no overview of state, no greeting, no "what needs my
  attention" cue.
- Ticket detail screen is the agent-style zoom view, with vocabulary,
  controls, and density tuned for support agents.
- Visual style is muted enterprise; the brand surfaces are minimal.

A wireframe lives at `~/Desktop/{ui,screens,app,data,tweaks-panel}.jsx`
+ `styles.css`. It describes a four-screen customer portal:

1. **Dashboard** — greeting, stats row (Open / Awaiting you / Resolved
   / Closed / Unread), recent tickets, "awaiting you" list, primary
   "+ New ticket" button.
2. **TicketList** — filterable + searchable list. Filter chips for
   state, category, priority. Each row shows state pill, priority,
   title, last-update time, unread badge.
3. **TicketDetail** — single ticket as a threaded conversation
   (customer + agent messages), reply box, status actions (reopen /
   resolve), attachments.
4. **NewTicket** — category, priority, title, body, attachments form.

The wireframe uses an `oklch()` theme with indigo accent, light
surfaces, 8/12 px radii, comfy 44 px row, and an inline geometric logo.

The user has explicitly approved a "redesign the customer portal to
match this wireframe" scope. Login screen stays as-is for now.

## Constraints from CLAUDE.md governance

- **Small PR Policy** — <300 lines ideal, <600 acceptable. This work
  must be **phased** into 5–6 PRs rather than one mega-PR.
- **AI Agent Governance** — "Agents MUST NOT redesign architecture
  silently" — this plan exists to make the redesign explicit.
- **No silent architectural drift** — must decide stack (CoffeeScript vs
  Vue 3) explicitly and document.
- **Automerge disabled for: ticket routing / permissions** — N/A here:
  pure UI redesign on existing customer-permission routes. No
  permission, backend, or routing logic changes.
- **Documentation Lifecycle** — this plan covers Plan; per-phase commits
  reference it.

## Stack decision: CoffeeScript (existing legacy frontend)

Zammad has two frontends:

- CoffeeScript + REST (legacy, current customer portal)
- Vue 3 + GraphQL (new desktop / mobile apps, currently **agent**-facing)

We will **stay on CoffeeScript** for this redesign because:

- The existing customer portal already lives there. Adding a Vue 3
  customer portal would create a third UI stack for one product.
- The Vue 3 apps are agent-facing today; a customer Vue app would mean
  net-new GraphQL queries/mutations on the customer permission surface,
  net-new auth + session plumbing, and net-new build/deploy slots —
  well beyond a "redesign" scope.
- The wireframe maps cleanly to existing Zammad CoffeeScript primitives
  (controllers, views, `App.Config.set` NavBar entries, SCSS partials).

Cost: the legacy CoffeeScript stack is on its way out; investment here
won't carry forward to Vue 3 verbatim. Accepted trade-off for delivery
speed and consistency with the existing customer surface.

## Scope (phased, separately merged)

Each phase = one branch, one PR, one merge. Each phase is independently
revertable.

### Phase 1 — Theme tokens + Sidebar reskin

- Extract `--accent`, `--ink-*`, `--surface-*`, status colors, radii
  from the wireframe's `styles.css` into Zammad's `zammad.scss`. Scope
  them under a new `body.is-customer-portal` (or `.overviews` for the
  first cut) class so agent UI is **unchanged**.
- Rework the customer left nav per wireframe:
  - Brand block (logo + "Helpdesk" + "Cenports portal")
  - Primary "+ New ticket" button at top of sidebar
  - Dashboard + My Tickets nav items with unread badge on My Tickets
  - Filter section: Open / Awaiting you / Resolved / Closed (dot
    indicators), wired to existing overview URLs / new query params
  - User card pinned bottom (avatar + name + email + sign out)
- Files: `zammad.scss`, `navigation/menu.jst.eco`, `_plugin/navigation.coffee`,
  new `App.Config.set('Dashboard', …, 'NavBar')` (with `permission: ticket.customer`).

### Phase 2 — Dashboard screen (NEW)

- Net-new controller `App.CustomerDashboard` + view + route
  `#dashboard` (gated `ticket.customer`).
- Computes counts from existing customer overviews:
  - Open / Pending / Resolved / Closed: pull from
    `App.OverviewIndexCollection` or via REST count endpoint
  - Awaiting you: overview with condition `last_contact_at >
    customer's last reply` (may need a new server-side overview seed)
  - Unread: existing `OnlineNotification` count for the user
- "Recent tickets" list: top-N from `App.OverviewListCollection` for
  `my_tickets`
- Primary "+ New ticket" CTA → existing `#customer_ticket_new` route
- Set `Dashboard` as the default landing for `ticket.customer` users
  (post-login redirect)

### Phase 3 — TicketList reskin

- New view template + controller for the customer-facing my_tickets
  list, replacing the table rendering for customers only.
- Filter chips for state + category + priority
- Search box (client-side initially; switch to server search if
  results exceed N)
- Empty state when no tickets

### Phase 4 — TicketDetail reskin

- New view + controller for customer ticket zoom — render
  conversation as threaded messages (you / agent), with reply box at
  bottom, status actions (reopen / mark resolved), attachments.
- Reuses existing REST endpoints for article fetch + create.
- Agent ticket zoom is untouched.

### Phase 5 — NewTicket reskin

- Reskin `app/assets/javascripts/app/views/customer_ticket_create.jst.eco`
  to match wireframe form layout (category dropdown, priority radio,
  title, body, attachments). Reuse existing REST `POST /tickets` flow.

## Out of scope

- **Login page** — explicitly excluded by current scope decision.
- **Vue 3 customer portal** — explicitly deferred (see Stack decision).
- **Mobile customer portal** — not in wireframe.
- **Agent-side UI** — every change is permission-gated to
  `ticket.customer` (or `!ticket.agent`).
- **GraphQL changes** — none required; customer portal stays on REST.
- **New permissions or roles** — none.
- **Email templates / outbound notifications** — unchanged.

## Risk per CLAUDE.md governance

- **Ticket routing** (automerge disabled) — **N/A.** No routing
  changes (which group, which agent, which channel).
- **Auth/permissions** (automerge disabled) — **N/A.** All new
  controllers use existing `ticket.customer` permission gate.
- **Background jobs / webhooks / email parsing** — **N/A.**
- **Schema-breaking changes** — **N/A.** Phase 2 may seed a new
  overview (`awaiting_you`) — purely additive, no schema change.
- **CSS/JS bundle size** — modest. New SCSS section, new CoffeeScript
  controller per phase. Estimated +~30KB minified across all phases.
- **Asset cache** — must bump `Rails.application.config.assets.version`
  on first phase merge so customers don't see half-styled portal due
  to cached CSS.

## Test plan

Per phase:
- Manual: log in as customer (`waye@mports.com`) on
  http://localhost:3188, walk the screen end-to-end, take before/after
  screenshots.
- Manual: log in as agent (`admin@local.test`), confirm **no visual
  or behavioral change** on agent screens.
- Automated: existing Cypress customer flow specs (if any) still
  pass. New specs only where worth the maintenance cost — primarily
  the new Dashboard route and the filter/search logic in Phase 3.

## Rollback strategy

- Each phase is one merge commit on `develop`. `git revert <merge sha>`
  reverts the phase atomically.
- No DB migrations except a tiny additive overview seed in Phase 2 —
  the seed is `create_if_not_exists`, so re-running is safe; revert =
  manual `Overview.find_by(link: 'awaiting_you')&.destroy` (one
  Rails-runner line, documented in the PR).
- Asset cache: bumping the version invalidates customer caches once,
  rollback bumps it again.

## Sequence

1. **This plan committed and merged first** (it's docs only, no risk).
2. Phase 1 (theme + sidebar). Merge.
3. Phase 2 (Dashboard). Merge.
4. Phase 3 (TicketList reskin). Merge.
5. Phase 4 (TicketDetail reskin). Merge.
6. Phase 5 (NewTicket reskin). Merge.

After Phase 5, retro on whether to invest in a Vue 3 customer portal
or leave the CoffeeScript redesign in place indefinitely.

## Decisions (confirmed)

- **Awaiting you** = tickets where the last message is from an agent
  (i.e. customer needs to reply). Implement as a new overview with
  condition `last_contact_agent_at > last_contact_customer_at`.
- **Brand text** = literal "Helpdesk" + `Setting.get('organization')`
  as subtitle. Stays in sync with the admin org-name setting.
- **Default landing** for customers = `#dashboard` post-login. Existing
  deep links to `#ticket/view/my_tickets` keep working.
- **Tweaks panel** (`tweaks-panel.jsx`) — wireframe authoring tool
  only, **not** shipped.
