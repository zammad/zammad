// Mock data + helpers for the ticket portal

const NOW = Date.now();
const MIN = 60 * 1000;
const HOUR = 60 * MIN;
const DAY = 24 * HOUR;

const INITIAL_TICKETS = [
  {
    id: 53006,
    title: "Order #A-7821 shipped to wrong address",
    category: "Shipping",
    priority: "high",
    state: "open",
    createdAt: NOW - 13 * MIN,
    updatedAt: NOW - 8 * MIN,
    unread: 1,
    messages: [
      {
        from: "me",
        author: "Wayne T.",
        body: "Hi — my order A-7821 was supposed to ship to my office (550 Front St) but the tracking says it's heading to my old apartment. Can you intercept and reroute? It hasn't arrived yet according to UPS.",
        at: NOW - 13 * MIN,
        attachments: [{ name: "ups-tracking.png", size: "248 KB", kind: "image" }],
      },
      {
        from: "agent",
        author: "Maya R., Support",
        body: "Hi Wayne — thanks for the heads up. I'm pulling the shipment now and contacting UPS to reroute. I'll need 2–3 hours for them to confirm. Will update you as soon as I hear back.",
        at: NOW - 8 * MIN,
        attachments: [],
      },
    ],
  },
  {
    id: 53005,
    title: "Discount code SPRING25 not applying at checkout",
    category: "Billing",
    priority: "normal",
    state: "pending",
    createdAt: NOW - 14 * MIN,
    updatedAt: NOW - 14 * MIN,
    unread: 0,
    messages: [
      {
        from: "me",
        author: "Wayne T.",
        body: "Tried using SPRING25 on a $180 cart — the field accepts the code but the total doesn't change. Tried in Chrome and Safari, same thing.",
        at: NOW - 14 * MIN,
        attachments: [],
      },
    ],
  },
  {
    id: 53004,
    title: "Can't export sales report to CSV",
    category: "Reports",
    priority: "low",
    state: "open",
    createdAt: NOW - 45 * MIN,
    updatedAt: NOW - 32 * MIN,
    unread: 0,
    messages: [
      {
        from: "me",
        author: "Wayne T.",
        body: "The CSV export button on the Sales report spins for a few seconds and nothing downloads. PDF export works fine.",
        at: NOW - 45 * MIN,
        attachments: [],
      },
      {
        from: "agent",
        author: "Devon K., Support",
        body: "Can you tell me which date range you're using? I'd like to reproduce it on my end.",
        at: NOW - 32 * MIN,
        attachments: [],
      },
    ],
  },
  {
    id: 53003,
    title: "Two-factor reset for finance@",
    category: "Account",
    priority: "normal",
    state: "resolved",
    createdAt: NOW - 1 * HOUR - 4 * MIN,
    updatedAt: NOW - 22 * MIN,
    unread: 0,
    messages: [
      {
        from: "me",
        author: "Wayne T.",
        body: "Our finance person lost their phone over the weekend. Need to reset 2FA on finance@cenports.com.",
        at: NOW - 1 * HOUR - 4 * MIN,
        attachments: [],
      },
      {
        from: "agent",
        author: "Maya R., Support",
        body: "Sent a reset link to the recovery address on file. Once they re-enroll, the old codes will be invalidated.",
        at: NOW - 50 * MIN,
        attachments: [],
      },
      {
        from: "me",
        author: "Wayne T.",
        body: "All set, they re-enrolled. Thanks Maya.",
        at: NOW - 22 * MIN,
        attachments: [],
      },
    ],
  },
  {
    id: 53002,
    title: "Inventory sync stuck — Warehouse 03",
    category: "Integrations",
    priority: "high",
    state: "resolved",
    createdAt: NOW - 1 * HOUR - 4 * MIN,
    updatedAt: NOW - 40 * MIN,
    unread: 0,
    messages: [
      {
        from: "me",
        author: "Wayne T.",
        body: "Warehouse 03 hasn't synced inventory counts since 6am. All other warehouses are current.",
        at: NOW - 1 * HOUR - 4 * MIN,
        attachments: [],
      },
      {
        from: "agent",
        author: "Devon K., Support",
        body: "Connector restarted, sync ran cleanly. Counts are matching now. Let us know if it stalls again.",
        at: NOW - 40 * MIN,
        attachments: [],
      },
    ],
  },
  {
    id: 52998,
    title: "Request: bulk vendor invite via CSV",
    category: "Feature request",
    priority: "low",
    state: "closed",
    createdAt: NOW - 3 * DAY,
    updatedAt: NOW - 2 * DAY,
    unread: 0,
    messages: [
      {
        from: "me",
        author: "Wayne T.",
        body: "Would love to bulk-invite vendors by uploading a CSV instead of one at a time.",
        at: NOW - 3 * DAY,
        attachments: [],
      },
      {
        from: "agent",
        author: "Product team",
        body: "Logged as FR-1284. Tentatively on the Q3 roadmap — we'll comment here when it ships.",
        at: NOW - 2 * DAY,
        attachments: [],
      },
    ],
  },
];

function relTime(t) {
  const d = Date.now() - t;
  if (d < MIN) return "just now";
  if (d < HOUR) return Math.floor(d / MIN) + "m ago";
  if (d < DAY) return Math.floor(d / HOUR) + "h ago";
  if (d < 7 * DAY) return Math.floor(d / DAY) + "d ago";
  const dt = new Date(t);
  return dt.toLocaleDateString(undefined, { month: "short", day: "numeric" });
}

function absTime(t) {
  const dt = new Date(t);
  return dt.toLocaleString(undefined, {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });
}

const STATE_META = {
  open:     { label: "Open",     dot: "var(--st-open)",     fg: "var(--st-open-fg)",     bg: "var(--st-open-bg)" },
  pending:  { label: "Pending",  dot: "var(--st-pend)",     fg: "var(--st-pend-fg)",     bg: "var(--st-pend-bg)" },
  resolved: { label: "Resolved", dot: "var(--st-res)",      fg: "var(--st-res-fg)",      bg: "var(--st-res-bg)" },
  closed:   { label: "Closed",   dot: "var(--st-closed)",   fg: "var(--st-closed-fg)",   bg: "var(--st-closed-bg)" },
};

const PRIORITY_META = {
  low:    { label: "Low",    fg: "var(--pri-low-fg)",  bg: "var(--pri-low-bg)" },
  normal: { label: "Normal", fg: "var(--pri-norm-fg)", bg: "var(--pri-norm-bg)" },
  high:   { label: "High",   fg: "var(--pri-high-fg)", bg: "var(--pri-high-bg)" },
};

const CATEGORIES = ["Shipping", "Billing", "Account", "Reports", "Integrations", "Feature request", "Other"];

Object.assign(window, {
  INITIAL_TICKETS, relTime, absTime, STATE_META, PRIORITY_META, CATEGORIES,
});
