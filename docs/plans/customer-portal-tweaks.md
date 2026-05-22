# Plan: Customer Portal — My Tickets Nav + Post-Create Redirect

## Status

Draft — awaiting approval before implementation.

## Why

Two small UX papercuts in the **customer-facing portal** (CoffeeScript /
legacy frontend) that hurt the support flow:

1. After a customer submits a new ticket, they land on the ticket-zoom view
   (`#ticket/zoom/:id`). For customers without agent context, the zoom view is
   confusing — they want to see their ticket in the list of their tickets, not
   land on an unfamiliar single-ticket screen.

2. The "My Tickets" pane is rendered as a **middle column** with its own
   header + counter, while the left sidebar only shows "Overviews". The user
   has to scan two columns to reach a ticket. Consolidating "My Tickets" into
   the main left sidebar (alongside "Overviews") collapses two columns of
   navigation into one.

## Scope (small PR — fits "<300 lines ideal")

Customer-portal only. **No agent-facing changes.** No backend changes. No
GraphQL/REST changes.

### Change 1: Post-create redirect — TRIVIAL

- File: `app/assets/javascripts/app/controllers/customer_ticket_create.coffee:186`
- Current: `ui.navigate '#ticket/zoom/' + @id`
- Target:  `ui.navigate '#ticket/view/my_tickets'`
- ~1 line. No tests at this layer; verified manually.

### Change 2: Move "My Tickets" into the left sidebar

- Affected: customer-portal navigator (the "Overviews" sidebar code path).
- Approach: the existing "Overviews" left nav is rendered by a navigator
  controller that iterates over `Ticket::Overview` items the user has access
  to. The "My Tickets" pane is rendered separately as a secondary column.
  We change the secondary-column entry to render as a sibling item under
  "Overviews" in the same left nav, and drop the dedicated middle column.
- Files to identify during implementation (NOT pre-committed in this plan):
  - The customer overview controller (`customer_*.coffee` or
    `navigation.coffee` in `app/assets/javascripts/app/controllers/`)
  - The view template that renders the middle "My Tickets" column.
- Estimated ~50-150 lines of CoffeeScript + view template edits.

## Out of scope

- Vue 3 desktop / mobile apps — those have their own routing and are not
  what the user is on today.
- Agent-side ticket-create flow (`agent_ticket_create.coffee`) — agents
  rightly land on the zoom view after creating a ticket.
- Permission / role changes.

## Rollback strategy

- All changes are in CoffeeScript / view templates served by the Rails
  asset pipeline. Revert the commit + redeploy = full rollback.
- No DB migration, no config change, no schema change.
- Feature flag would be overkill for two CoffeeScript edits; if needed,
  gate Change 2 behind a `Setting` like `customer_portal_unified_nav`.

## Risk per CLAUDE.md

- "Automerge MUST be disabled for: ticket routing" — **N/A.** This changes
  post-create navigation in the **UI only**, not the routing of tickets
  themselves (who gets the ticket, which group, etc.).
- "Never lose tickets" — N/A. Ticket creation API call is unchanged.
- "Hardcoding policy: hardcoded routing" forbidden — the redirect target
  `#ticket/view/my_tickets` is a UI route, not business routing logic.
  Acceptable per "documented defaults".

## Test plan

- Manual: log in as `waye@mports.com` (customer role), create a ticket,
  confirm landing on `#ticket/view/my_tickets` and the new ticket appearing
  in the list.
- Manual: confirm "My Tickets" appears in the left nav, the old middle
  column is gone, ticket counts still correct.
- Manual: confirm agent ticket-create flow is **unchanged** (still lands
  on zoom).
- Automated: existing Cypress/RSpec coverage for `customer_ticket_create`
  should still pass.

## Sequence

1. Native dev env up (Ruby 3.4.9, bundle install, pnpm install, db setup).
2. Implement Change 1 (1-line redirect). Verify.
3. Implement Change 2 (sidebar restructure). Verify.
4. Single commit with both, branch `feature/customer-portal-unified-nav`,
   push to `derrickchen-gmail/zammad` fork.

## Open questions

- Does the user want this **only for customers**, or should agents also see
  a unified "My Tickets" in their left nav? Plan assumes customers only.
- After Change 2, is "Overviews" header still useful, or should "My Tickets"
  appear as a top-level item alongside Overviews? Plan assumes the latter.
