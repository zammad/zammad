// Agent-side mock data — tickets, customers, orgs, agents, activity

const A_NOW = Date.now();
const A_MIN = 60 * 1000;
const A_HOUR = 60 * A_MIN;
const A_DAY = 24 * A_HOUR;

const AGENTS = [
  { id: "u1", name: "Derrick Chen", initials: "DC", role: "Admin", tone: "accent", email: "derrick@cenports.com" },
  { id: "u2", name: "Maya Reyes",   initials: "MR", role: "Agent", tone: "neutral", email: "maya@cenports.com" },
  { id: "u3", name: "Devon Kim",    initials: "DK", role: "Agent", tone: "neutral", email: "devon@cenports.com" },
  { id: "u4", name: "Priya Shah",   initials: "PS", role: "Agent", tone: "neutral", email: "priya@cenports.com" },
];
const ME_AGENT = AGENTS[0];

const ORGS = [
  { id: "o1", name: "Northpath Goods",      domain: "northpath.co",    members: 18, plan: "Pro"        },
  { id: "o2", name: "Brightline Cosmetics", domain: "brightline.com",  members: 6,  plan: "Standard"   },
  { id: "o3", name: "Cedar & Co.",          domain: "cedarand.co",     members: 3,  plan: "Standard"   },
  { id: "o4", name: "Wavelength Audio",     domain: "wavelength.fm",   members: 11, plan: "Enterprise" },
  { id: "o5", name: "Folio Fashion",        domain: "foliofashion.com",members: 24, plan: "Pro"        },
];

const CUSTOMERS = [
  { id: "c1", name: "Wayne Test",      email: "wayne@cenports.com",      orgId: null, initials: "WT", tone: "accent" },
  { id: "c2", name: "Iris Park",       email: "iris@northpath.co",       orgId: "o1", initials: "IP" },
  { id: "c3", name: "Theo Lambert",    email: "theo@brightline.com",     orgId: "o2", initials: "TL" },
  { id: "c4", name: "Hannah Ortega",   email: "h.ortega@cedarand.co",    orgId: "o3", initials: "HO" },
  { id: "c5", name: "Marcus Vaughn",   email: "mv@wavelength.fm",        orgId: "o4", initials: "MV" },
  { id: "c6", name: "Lena Sato",       email: "lena@foliofashion.com",   orgId: "o5", initials: "LS" },
  { id: "c7", name: "Jordan Pierre",   email: "jordan@northpath.co",     orgId: "o1", initials: "JP" },
  { id: "c8", name: "Ana Belmonte",    email: "ana.b@wavelength.fm",     orgId: "o4", initials: "AB" },
];

const GROUPS = ["Support", "Billing", "Engineering", "Returns", "Onboarding"];
const TAGS_POOL = ["shipping", "refund", "vip", "integration", "warehouse-03", "shopify", "rma", "duplicate", "fraud-check"];

function mkTicket(id, opts) {
  return {
    id, state: "open", priority: "normal", group: "Support",
    assigneeId: null, tags: [], unread: 0,
    createdAt: A_NOW - 1 * A_HOUR, updatedAt: A_NOW - 1 * A_HOUR,
    firstResponseAt: null, slaDueAt: null,
    messages: [],
    ...opts,
  };
}

const A_TICKETS = [
  mkTicket(53006, {
    title: "Order #A-7821 shipped to wrong address",
    customerId: "c1", group: "Returns", priority: "high", state: "open", tags: ["shipping", "rma"],
    assigneeId: "u1", createdAt: A_NOW - 13 * A_MIN, updatedAt: A_NOW - 3 * A_MIN, unread: 1,
    slaDueAt: A_NOW + 47 * A_MIN,
    messages: [
      { from: "customer", authorId: "c1", body: "Hi — my order A-7821 was supposed to ship to my office (550 Front St) but the tracking says it's heading to my old apartment. Can you intercept and reroute? It hasn't arrived yet according to UPS.", at: A_NOW - 13 * A_MIN, attachments: [{ name: "ups-tracking.png", size: "248 KB", kind: "image" }] },
      { from: "agent", authorId: "u1", body: "Hi Wayne — thanks for the heads up. I'm pulling the shipment now and contacting UPS to reroute. I'll need 2–3 hours for them to confirm.", at: A_NOW - 8 * A_MIN, attachments: [] },
      { from: "internal", authorId: "u1", body: "Pinged warehouse — they confirmed package is in transit, can intercept at next sort facility. Will update Wayne once UPS replies.", at: A_NOW - 6 * A_MIN, attachments: [] },
      { from: "customer", authorId: "c1", body: "Thanks Maya, appreciate it!", at: A_NOW - 3 * A_MIN, attachments: [] },
    ],
  }),
  mkTicket(53005, {
    title: "Discount code SPRING25 not applying at checkout",
    customerId: "c2", group: "Billing", priority: "normal", state: "pending",
    assigneeId: "u2", createdAt: A_NOW - 32 * A_MIN, updatedAt: A_NOW - 12 * A_MIN, unread: 0, tags: ["shopify"],
    slaDueAt: A_NOW + 2 * A_HOUR,
    messages: [
      { from: "customer", authorId: "c2", body: "Tried using SPRING25 on a $180 cart — the field accepts the code but the total doesn't change. Tried in Chrome and Safari, same thing.", at: A_NOW - 32 * A_MIN, attachments: [] },
      { from: "agent", authorId: "u2", body: "Hi Iris — looking into the promo right now. Can you confirm which products are in your cart?", at: A_NOW - 12 * A_MIN, attachments: [] },
    ],
  }),
  mkTicket(53004, {
    title: "Can't export sales report to CSV",
    customerId: "c3", group: "Support", priority: "low", state: "open",
    assigneeId: "u3", createdAt: A_NOW - 1 * A_HOUR - 5 * A_MIN, updatedAt: A_NOW - 32 * A_MIN, tags: ["integration"],
    messages: [
      { from: "customer", authorId: "c3", body: "The CSV export button on the Sales report spins for a few seconds and nothing downloads. PDF export works fine.", at: A_NOW - 1 * A_HOUR - 5 * A_MIN, attachments: [] },
      { from: "agent", authorId: "u3", body: "Can you tell me which date range you're using? I'd like to reproduce on my end.", at: A_NOW - 32 * A_MIN, attachments: [] },
    ],
  }),
  mkTicket(53003, {
    title: "Two-factor reset for finance@",
    customerId: "c4", group: "Support", priority: "normal", state: "resolved",
    assigneeId: "u2", createdAt: A_NOW - 1 * A_HOUR - 4 * A_MIN, updatedAt: A_NOW - 22 * A_MIN, tags: [],
    messages: [
      { from: "customer", authorId: "c4", body: "Our finance person lost their phone over the weekend. Need to reset 2FA on finance@cenports.com.", at: A_NOW - 1 * A_HOUR - 4 * A_MIN, attachments: [] },
      { from: "agent", authorId: "u2", body: "Sent a reset link to the recovery address on file.", at: A_NOW - 50 * A_MIN, attachments: [] },
      { from: "customer", authorId: "c4", body: "All set, they re-enrolled. Thanks Maya.", at: A_NOW - 22 * A_MIN, attachments: [] },
    ],
  }),
  mkTicket(53002, {
    title: "Inventory sync stuck — Warehouse 03",
    customerId: "c5", group: "Engineering", priority: "high", state: "resolved",
    assigneeId: "u3", createdAt: A_NOW - 1 * A_HOUR - 12 * A_MIN, updatedAt: A_NOW - 40 * A_MIN, tags: ["integration", "warehouse-03"],
    messages: [
      { from: "customer", authorId: "c5", body: "Warehouse 03 hasn't synced inventory counts since 6am. All other warehouses are current.", at: A_NOW - 1 * A_HOUR - 12 * A_MIN, attachments: [] },
      { from: "agent", authorId: "u3", body: "Connector restarted, sync ran cleanly. Counts are matching now.", at: A_NOW - 40 * A_MIN, attachments: [] },
    ],
  }),
  mkTicket(53001, {
    title: "Need W-9 for tax filing",
    customerId: "c6", group: "Billing", priority: "low", state: "open",
    assigneeId: null, createdAt: A_NOW - 2 * A_HOUR, updatedAt: A_NOW - 2 * A_HOUR, unread: 1,
    slaDueAt: A_NOW + 6 * A_HOUR,
    messages: [
      { from: "customer", authorId: "c6", body: "Our accountant needs a W-9 from you for our Q1 filing. Can you send a signed copy?", at: A_NOW - 2 * A_HOUR, attachments: [] },
    ],
  }),
  mkTicket(53000, {
    title: "Returning damaged speaker — RMA #4421",
    customerId: "c5", group: "Returns", priority: "normal", state: "open",
    assigneeId: "u1", createdAt: A_NOW - 3 * A_HOUR, updatedAt: A_NOW - 28 * A_MIN, tags: ["rma"],
    messages: [
      { from: "customer", authorId: "c5", body: "Speaker arrived with a cracked grille. RMA #4421 generated, need shipping label.", at: A_NOW - 3 * A_HOUR, attachments: [{ name: "damage-1.jpg", size: "1.2 MB", kind: "image" }, { name: "damage-2.jpg", size: "980 KB", kind: "image" }] },
      { from: "agent", authorId: "u1", body: "Label coming over now — please drop at any UPS location.", at: A_NOW - 28 * A_MIN, attachments: [{ name: "ups-label-4421.pdf", size: "84 KB", kind: "file" }] },
    ],
  }),
  mkTicket(52999, {
    title: "Webhook deliveries failing with 502",
    customerId: "c2", group: "Engineering", priority: "high", state: "pending",
    assigneeId: "u3", createdAt: A_NOW - 5 * A_HOUR, updatedAt: A_NOW - 1 * A_HOUR, tags: ["integration", "shopify"],
    slaDueAt: A_NOW + 18 * A_MIN,
    messages: [
      { from: "customer", authorId: "c2", body: "Our Shopify webhooks have been returning 502 for ~30 minutes. Order create events not flowing.", at: A_NOW - 5 * A_HOUR, attachments: [] },
      { from: "agent", authorId: "u3", body: "Confirmed on our end. Scaling up the webhook worker pool — should clear within 10 min.", at: A_NOW - 4 * A_HOUR, attachments: [] },
      { from: "customer", authorId: "c2", body: "Still seeing 502s, anything else we can try?", at: A_NOW - 1 * A_HOUR, attachments: [] },
    ],
  }),
  mkTicket(52998, {
    title: "Bulk vendor invite via CSV",
    customerId: "c7", group: "Onboarding", priority: "low", state: "closed",
    assigneeId: "u4", createdAt: A_NOW - 3 * A_DAY, updatedAt: A_NOW - 2 * A_DAY, tags: [],
    messages: [
      { from: "customer", authorId: "c7", body: "Would love to bulk-invite vendors by uploading a CSV instead of one at a time.", at: A_NOW - 3 * A_DAY, attachments: [] },
      { from: "agent", authorId: "u4", body: "Logged as FR-1284. Tentatively on the Q3 roadmap.", at: A_NOW - 2 * A_DAY, attachments: [] },
    ],
  }),
  mkTicket(52997, {
    title: "Duplicate charge on invoice INV-2210",
    customerId: "c8", group: "Billing", priority: "high", state: "open",
    assigneeId: "u2", createdAt: A_NOW - 50 * A_MIN, updatedAt: A_NOW - 4 * A_MIN, unread: 2, tags: ["refund"],
    slaDueAt: A_NOW + 1 * A_HOUR + 10 * A_MIN,
    messages: [
      { from: "customer", authorId: "c8", body: "I see two charges of $312 on INV-2210, same date. Please refund the duplicate.", at: A_NOW - 50 * A_MIN, attachments: [{ name: "statement.pdf", size: "212 KB", kind: "file" }] },
      { from: "agent", authorId: "u2", body: "Confirmed the duplicate. Issuing refund now.", at: A_NOW - 18 * A_MIN, attachments: [] },
      { from: "customer", authorId: "c8", body: "Thanks! How long until I see it?", at: A_NOW - 4 * A_MIN, attachments: [] },
    ],
  }),
  mkTicket(52996, {
    title: "Storefront theme broken on mobile Safari",
    customerId: "c6", group: "Engineering", priority: "normal", state: "open",
    assigneeId: null, createdAt: A_NOW - 4 * A_HOUR, updatedAt: A_NOW - 4 * A_HOUR, unread: 1, tags: ["shopify"],
    messages: [
      { from: "customer", authorId: "c6", body: "Footer is overlapping content on iOS 17 Safari. Screenshot attached.", at: A_NOW - 4 * A_HOUR, attachments: [{ name: "ios-bug.png", size: "1.4 MB", kind: "image" }] },
    ],
  }),
  mkTicket(52995, {
    title: "Update billing email to ar@northpath.co",
    customerId: "c2", group: "Billing", priority: "low", state: "resolved",
    assigneeId: "u2", createdAt: A_NOW - 6 * A_HOUR, updatedAt: A_NOW - 5 * A_HOUR, tags: [],
    messages: [
      { from: "customer", authorId: "c2", body: "Please change our billing notification email to ar@northpath.co.", at: A_NOW - 6 * A_HOUR, attachments: [] },
      { from: "agent", authorId: "u2", body: "Updated. Next invoice will go to the new address.", at: A_NOW - 5 * A_HOUR, attachments: [] },
    ],
  }),
];

// Activity feed entries (mix of ticket events, user actions, system)
const ACTIVITY = [
  { id: 1, kind: "started",  authorId: "u1", at: A_NOW - 1 * A_MIN  },
  { id: 2, kind: "reply",    authorId: "c1", ticketId: 53006, at: A_NOW - 3 * A_MIN },
  { id: 3, kind: "internal", authorId: "u1", ticketId: 53006, at: A_NOW - 6 * A_MIN },
  { id: 4, kind: "reply",    authorId: "u1", ticketId: 53006, at: A_NOW - 8 * A_MIN },
  { id: 5, kind: "reply",    authorId: "c8", ticketId: 52997, at: A_NOW - 4 * A_MIN },
  { id: 6, kind: "refund",   authorId: "u2", ticketId: 52997, at: A_NOW - 18 * A_MIN },
  { id: 7, kind: "created",  authorId: "c1", ticketId: 53006, at: A_NOW - 13 * A_MIN },
  { id: 8, kind: "resolved", authorId: "u2", ticketId: 53003, at: A_NOW - 22 * A_MIN },
  { id: 9, kind: "resolved", authorId: "u3", ticketId: 53002, at: A_NOW - 40 * A_MIN },
  { id: 10, kind: "created", authorId: "c6", ticketId: 52996, at: A_NOW - 4 * A_HOUR },
  { id: 11, kind: "assigned", authorId: "u1", ticketId: 53006, targetId: "u1", at: A_NOW - 14 * A_MIN },
];

const MACROS = [
  { id: "m1", title: "Acknowledge & investigating",
    body: "Thanks for reaching out — I've received your message and I'm digging into it now. I'll follow up shortly with more details." },
  { id: "m2", title: "Request more info",
    body: "To help me look into this, could you share:\n• A screenshot of what you're seeing\n• The browser & OS you're using\n• The approximate time the issue started\n\nThanks!" },
  { id: "m3", title: "Refund issued",
    body: "I've issued a refund for the duplicate charge. You'll see it on your statement within 5–7 business days, depending on your bank." },
  { id: "m4", title: "Shipping label sent",
    body: "I've emailed a prepaid UPS label to the address on file. Drop the package at any UPS location — no appointment needed." },
  { id: "m5", title: "Escalating to engineering",
    body: "This looks like a bug on our end. I'm escalating to the engineering team and will keep you posted as soon as I have an update." },
];

// Helpers
const agentById  = (id) => AGENTS.find(a => a.id === id);
const custById   = (id) => CUSTOMERS.find(c => c.id === id);
const orgById    = (id) => ORGS.find(o => o.id === id);
const personById = (id) => agentById(id) || custById(id) || { name: "Unknown", initials: "?" };

function a_relTime(t) {
  const d = Date.now() - t;
  if (d < A_MIN) return "just now";
  if (d < A_HOUR) return Math.floor(d / A_MIN) + "m";
  if (d < A_DAY) return Math.floor(d / A_HOUR) + "h";
  if (d < 7 * A_DAY) return Math.floor(d / A_DAY) + "d";
  return new Date(t).toLocaleDateString(undefined, { month: "short", day: "numeric" });
}
function a_absTime(t) {
  return new Date(t).toLocaleString(undefined, { month: "short", day: "numeric", hour: "numeric", minute: "2-digit" });
}

Object.assign(window, {
  AGENTS, ME_AGENT, ORGS, CUSTOMERS, GROUPS, TAGS_POOL, A_TICKETS, ACTIVITY, MACROS,
  agentById, custById, orgById, personById, a_relTime, a_absTime,
});

// Pill metadata (shared with ui.jsx)
if (!window.STATE_META) {
  window.STATE_META = {
    open:     { label: "Open",     dot: "var(--st-open)",     fg: "var(--st-open-fg)",     bg: "var(--st-open-bg)" },
    pending:  { label: "Pending",  dot: "var(--st-pend)",     fg: "var(--st-pend-fg)",     bg: "var(--st-pend-bg)" },
    resolved: { label: "Resolved", dot: "var(--st-res)",      fg: "var(--st-res-fg)",      bg: "var(--st-res-bg)" },
    closed:   { label: "Closed",   dot: "var(--st-closed)",   fg: "var(--st-closed-fg)",   bg: "var(--st-closed-bg)" },
  };
}
if (!window.PRIORITY_META) {
  window.PRIORITY_META = {
    low:    { label: "Low",    fg: "var(--pri-low-fg)",  bg: "var(--pri-low-bg)" },
    normal: { label: "Normal", fg: "var(--pri-norm-fg)", bg: "var(--pri-norm-bg)" },
    high:   { label: "High",   fg: "var(--pri-high-fg)", bg: "var(--pri-high-bg)" },
  };
}
