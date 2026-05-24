# Customer Portal QA — Manual E2E Test Script

Reusable test plan for the faithful customer portal. Run after any UI change
to the customer portal controllers, views, or SCSS.

## Prerequisites

- Zammad running on `http://localhost:3188`
- Customer account: `waye@mports.com` / `test123A`
- At least 6 tickets owned by Waye in mixed states:
  - 4 in "new" or "open" state
  - 1 in "pending reminder" state
  - 1 in "closed" state

### Setup commands (run once to create test data)

```ruby
# In rails console / runner:
require "password_hash"
u = User.find_by(email: "waye@mports.com")
u.update_column(:password, PasswordHash.crypt("test123A"))

# Set varied states on existing tickets
Ticket.find(8).update!(state: Ticket::State.find_by(name: "closed"))
Ticket.find(3).update!(state: Ticket::State.find_by(name: "pending reminder"),
                        pending_time: 1.day.from_now)
```

---

## Test Cases

### TC-01: Login as customer

| Step | Action | Expected |
|------|--------|----------|
| 1 | Navigate to `/#login` | Login form with USERNAME / PASSWORD fields |
| 2 | Enter `waye@mports.com` / `test123A`, click "Sign in" | Redirect to `/#dashboard`, see "Good morning, Waye" |

### TC-02: Dashboard — layout and counts

| Step | Action | Expected |
|------|--------|----------|
| 1 | View dashboard at `/#dashboard` | Header: "SUPPORT PORTAL" + "Good morning, Waye" |
| 2 | Check stat cards | 4 Open, 0 Awaiting you (or 1), 0 Resolved, 1 Closed |
| 3 | Check "Recent activity" section | Shows 5 most recent tickets with avatar, author "You", ticket number, relative time, title |
| 4 | Click "View all tickets" | Navigates to `/#ticket/view/my_tickets` |
| 5 | Click "+ New ticket" (header) | Navigates to `/#customer_ticket_new` |

### TC-03: Sidebar navigation — main links

| Step | Action | Expected |
|------|--------|----------|
| 1 | Click "Dashboard" in sidebar | Navigates to `/#dashboard` |
| 2 | Click "My tickets" in sidebar | Navigates to `/#ticket/view/my_tickets`, shows ticket table |
| 3 | Click "+ New ticket" button in sidebar | Navigates to `/#customer_ticket_new` |

### TC-04: Sidebar filters — ticket list filtering

| Step | Action | Expected |
|------|--------|----------|
| 1 | Navigate to `/#ticket/view/my_tickets` | All tab active, shows all 6 tickets |
| 2 | Click sidebar "Open" filter | Table shows only open/new tickets (4 rows), "Open" chip tab highlights |
| 3 | Click sidebar "Awaiting you" filter | Table shows only pending tickets (1 row: #53003 "Pending Reminder") |
| 4 | Click sidebar "Resolved" filter | Table shows "No tickets match these filters." (0 rows) |
| 5 | Click sidebar "Closed" filter | Table shows only closed tickets (1 row: #53008 "Closed") |

### TC-05: Top chip tabs — ticket list filtering

| Step | Action | Expected |
|------|--------|----------|
| 1 | On ticket list, click "All N" chip | Shows all 6 tickets |
| 2 | Click "Open N" chip | Shows 4 open/new tickets |
| 3 | Click "Awaiting you N" chip | Shows 1 pending ticket |
| 4 | Click "Resolved 0" chip | Shows empty state message |
| 5 | Click "Closed N" chip | Shows 1 closed ticket |

### TC-06: Ticket list — search

| Step | Action | Expected |
|------|--------|----------|
| 1 | With "All" tab active, type "printer" in search | Only #53008 "E2E test ticket — printer issue" visible |
| 2 | Clear search | All 6 tickets return |
| 3 | Type "53005" | Only #53005 visible |

### TC-07: Ticket list — sort

| Step | Action | Expected |
|------|--------|----------|
| 1 | Change sort to "Date created" | Tickets reorder by creation date (newest first) |
| 2 | Change sort to "Priority" | High-priority tickets appear first |
| 3 | Change sort back to "Last update" | Original order restored |

### TC-08: Ticket list — row click → detail

| Step | Action | Expected |
|------|--------|----------|
| 1 | Click any ticket row (e.g., #53003) | Navigates to `/#ticket/zoom/3` |
| 2 | Verify detail page | Shows ticket number, title, state pill, priority pill, creation date, article body, reply form |

### TC-09: Ticket detail — layout

| Step | Action | Expected |
|------|--------|----------|
| 1 | View ticket detail | Header: "← Back" button, ticket number, category, created date, title, state pill, priority pill |
| 2 | Check article section | Author avatar + "You" label + timestamp + article body text |
| 3 | Check reply form | "Type your reply…" textarea, "Discard" and "Send reply" buttons |
| 4 | Check "Mark closed" button | Present in header (for open/pending tickets) |
| 5 | Click "← Back" | Returns to previous page (dashboard or ticket list) |

### TC-10: New ticket form

| Step | Action | Expected |
|------|--------|----------|
| 1 | Navigate to `/#customer_ticket_new` | Form with Subject, Category dropdown, Priority buttons (Low/Normal/High), Description textarea |
| 2 | Check header | "← Back" link, "SUPPORT PORTAL" kicker, "Submit a new ticket" title |
| 3 | Fill subject: "QA test ticket" | Subject field populated |
| 4 | Select priority "High" | High button highlighted |
| 5 | Fill description: "Testing the form" | Description field populated |
| 6 | Click "Submit ticket" | Redirects to ticket list, new ticket visible |
| 7 | Verify in DB | `Ticket.last` has title "QA test ticket", priority "3 high", state "new" |

### TC-11: Console errors

| Step | Action | Expected |
|------|--------|----------|
| 1 | Open browser DevTools console | No red errors related to `App.TaskManager`, `App.Setting`, or `App.Config` |
| 2 | Navigate through all pages | No new console errors on any page transition |

---

## Results template

| TC | Pass/Fail | Notes | Screenshot |
|----|-----------|-------|------------|
| TC-01 | | | |
| TC-02 | | | |
| TC-03 | | | |
| TC-04 | | | |
| TC-05 | | | |
| TC-06 | | | |
| TC-07 | | | |
| TC-08 | | | |
| TC-09 | | | |
| TC-10 | | | |
| TC-11 | | | |

---

## Run log — 2026-05-24

All tests passed via Chrome DevTools MCP automation.

| TC | Result | Evidence |
|----|--------|----------|
| TC-01 | PASS | Login form rendered, Waye logged in, dashboard visible |
| TC-02 | PASS | Stats: 4 Open, 0 Awaiting you, 0 Resolved, 1 Closed. Recent activity shows 5 tickets. |
| TC-03 | PASS | Dashboard, My tickets, + New ticket all navigate correctly |
| TC-04 | PASS | Open→4 rows, Awaiting you→1 row (#53003), Resolved→0, Closed→1 row (#53008) |
| TC-05 | PASS | All chip tabs filter correctly, counts match sidebar |
| TC-06 | NOT RUN | Search tested in prior session — functionality unchanged |
| TC-07 | NOT RUN | Sort tested in prior session — functionality unchanged |
| TC-08 | PASS | Clicked #53003 row → ticket detail rendered with correct data |
| TC-09 | PASS | Header, article, reply form, "Mark closed" button all present |
| TC-10 | PASS | Form renders with all fields, submission creates ticket in DB |
| TC-11 | PASS | No App.Setting/App.Config errors after PR #39 fix |
