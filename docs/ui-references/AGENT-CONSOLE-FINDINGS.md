# Agent Console — Honest Findings Before Coding

## What just happened (and why my prior PRs missed the mark)

PRs #8–#13 attempted a CSS-only reskin of the existing Zammad agent UI to
match `~/Desktop/Agent Console.html`. **That approach can't get us to the
target design.** The wireframe is structurally a different application,
not a restyle of the same DOM:

| Wireframe element | Lives in Zammad? | Why CSS alone can't get there |
|---|---|---|
| 3-section sidebar (Main / Queues / Admin) with per-queue counts | No | Zammad's NavBar is a flat list. Queue counts come from new TaskManager workers we'd need to wire up. |
| 4-card metric grid (My open / AHT / First-reply rate / CSAT) with sparkline + deltas | No | `App.Dashboard` renders `DashboardStats` widgets that produce a completely different DOM (the "My Stats / First Steps" tabs you saw). |
| "SLA at risk" widget with breach countdowns | No | Zammad has SLA data but no widget that lists breaching tickets like this. |
| Team workload bars | No | Per-agent active-ticket counts aren't surfaced as a widget. |
| Activity feed (`feed` list with grouped events) | Partial | Zammad has an activity stream but renders rows differently. |
| Ticket detail as 3-column (queue / conversation / metadata) | No | Zammad ticket zoom is one wide column + right attribute sidebar. |
| Composer with internal-note vs public-reply tabs side-by-side | No | Zammad has internal/public toggle but visually integrated, not a tab pair. |
| Manage screens as two-pane (settings nav + form) | Loosely | Existing `#manage/*` is similar in topology but uses different markup. |

The DOM that Zammad emits today and the DOM the wireframe expects don't
overlap on most screens — CSS can only retint what already exists, not
restructure it.

## What I copied into this repo

```
docs/ui-references/
├── AGENT-CONSOLE-FINDINGS.md   ← this file
├── agent-console/
│   ├── index.html              ← copy of ~/Desktop/Agent Console.html
│   ├── styles.css              (shared)
│   ├── agent-styles.css        (agent-specific)
│   ├── ui.jsx                  (shared icons + pills + avatar)
│   ├── tweaks-panel.jsx        (authoring-time tool — not for prod)
│   ├── agent-app.jsx           (shell + sidebar + router)
│   ├── agent-screens.jsx       (Dashboard + Overviews)
│   ├── agent-detail.jsx        (3-column ticket detail)
│   ├── agent-manage.jsx        (Users / Channels / Branding / etc.)
│   └── agent-data.jsx          (mock data)
└── customer-portal/
    ├── index.html
    ├── styles.css
    ├── ui.jsx
    ├── tweaks-panel.jsx
    ├── app.jsx
    ├── screens.jsx
    └── data.jsx
```

These files are the single source of truth for the design. Any future
implementation should reference them directly.

## What we are missing

### 1. Component library

The wireframe defines reusable bits Zammad doesn't have an exact match for:

- `<StatePill state="open" />` — colored pill with dot + label per state
- `<PriorityPill priority="high" />` — quiet pill, three shades
- `<Avatar name="..." size={28} tone="accent" />` — initials in a circle
- `<Icon name="dashboard|tickets|plus|search|bell|paperclip|...|" />` — 22 inline SVGs (lucide-style)
- `<LogoMark />` — geometric 4-square logo

Zammad has `@Icon('icon-name')` referencing its own icon set (`@svg-symbols`).
Many of the wireframe's icon names (`dashboard`, `inbox`, `paperclip`,
`send`, `filter`, `flag`, `settings`, `logout`) don't map 1:1.

### 2. Data + GraphQL/REST queries

Several widgets need data sources that don't exist as REST endpoints today:

- **My open** — easy (existing `ticket/view/my_assigned`).
- **Avg handle time** — Zammad has reporting for this but not as a dashboard widget endpoint.
- **First-reply rate** — same, reporting only.
- **CSAT (30d)** — Zammad's smile feedback module; not in the default install.
- **SLA at risk** — derivable from `Ticket.escalation_at` field + open state filter, but no current endpoint surfaces "tickets breaching within X hours."
- **Team workload** — needs `GROUP BY assignee_id WHERE state in (open, pending)`; not exposed as REST today.
- **Recent activity feed** — close to existing `History` model but different shape.

For a faithful port we'd need either new REST controllers, new GraphQL
queries, or client-side aggregation over existing data.

### 3. Theme tokens

The wireframe uses `oklch()` colors and a CSS-variable system. Zammad's
SCSS uses HSL with named variables (`$sidebarWidth`, `$navigationWidth`)
plus CSS custom properties for theme. The two systems can coexist (and
my prior phases did add `--cp-*` and `--ac-*` token sets) — but the
spacing/density variables (`--row-h`, `--pad`, `--font`, `--title`)
controlled by the wireframe's "Tweaks" panel are bespoke and not wired
to anything in Zammad.

## What can be done

### Option A — Faithful reimplementation in Zammad's CoffeeScript stack

Replace `App.Dashboard` for agents with a new controller that emits the
wireframe DOM, build out the missing widgets, and wire to REST
endpoints (some new). Per-screen estimate:

- Dashboard rewrite: ~600 lines CoffeeScript + ~400 lines SCSS + new REST
  endpoint for SLA-at-risk + new endpoint for workload aggregation.
  ~1–2 days.
- Overviews list as card layout: ~300 lines CoffeeScript + SCSS.
- 3-column ticket detail: bigger lift (~800 lines) because we'd be
  reorganizing the zoom controller's tabsSidebar / main / new column
  composition. Touches a lot of agent muscle memory.
- Manage pages: settings two-pane layout matches reasonably; lighter
  lift but many sub-pages.

Total estimate: **2–3 weeks** of careful work. Phased PRs <300 lines
each per CLAUDE.md.

### Option B — Build it in Zammad's Vue 3 desktop app

Zammad's Vue 3 frontend (`app/frontend/apps/desktop/`) is the new
direction. Implementing this wireframe there would future-proof the
work and use GraphQL instead of REST. The Vue desktop app is currently
**agent-facing already** — this would be a major chunk of work but
aligned with Zammad's roadmap. **~4–6 weeks.**

### Option C — Vendor the wireframe as a static React app on a Zammad route

Host the React app at `/agent-console-preview` as static assets,
authenticate via existing Zammad session cookie, fetch real data via
the REST API. Pros: faithful to the design, fast to ship. Cons: a
parallel UI that has to be maintained separately and won't pick up
Zammad's future Vue 3 work. **~3–5 days.**

### Option D — Revert what I built, do nothing further until you decide

The CSS-only PRs (#9–#13) are small and revertable. I can revert them
in one go if you'd rather start from a clean baseline.

## Recommendation

If we want the wireframe **as-shown**, the only realistic paths are
**A** (CoffeeScript) or **C** (vendored React).

- **A** stays in the existing stack (no new frontend), and the
  resulting screens behave like the rest of Zammad (router, search,
  notifications, etc. integrate). Best for long-term.
- **C** is the fastest way to see the exact wireframe running against
  real data, but it's a parallel surface that won't share the rest of
  Zammad's UX (e.g. the global search bar).

**Option A, phased, is my recommendation** — but I want your sign-off
before writing any more code, because each phase is substantially
larger than the CSS-only ones and the prior approach demonstrated I
can drift from what you actually want when running fast.

## Open questions for you

1. Pick a path: **A**, **B**, **C**, or **D**?
2. If A: which screen first — Dashboard (highest visual impact) or
   Ticket detail (most-used by agents)?
3. SLA data: OK to compute "at risk" client-side from existing
   `escalation_at` field, or do you want a new REST endpoint?
4. CSAT widget: skip it (no data source in default Zammad) or replace
   with a different metric?
5. Should I revert the merged CSS-only PRs (#9–#13) so we have a
   clean baseline? They're not actively harmful — they just don't
   match the wireframe.
