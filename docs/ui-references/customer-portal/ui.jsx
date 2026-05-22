// Small reusable bits: icons, pills, avatar, etc.

const Icon = ({ name, size = 16, stroke = 1.6 }) => {
  const paths = {
    dashboard: <><rect x="3" y="3" width="7" height="9" rx="1.5"/><rect x="14" y="3" width="7" height="5" rx="1.5"/><rect x="14" y="12" width="7" height="9" rx="1.5"/><rect x="3" y="16" width="7" height="5" rx="1.5"/></>,
    tickets: <><path d="M3 7a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v2a2 2 0 0 0 0 4v2a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-2a2 2 0 0 0 0-4z"/><path d="M9 5v14" strokeDasharray="2 2"/></>,
    plus: <><path d="M12 5v14M5 12h14"/></>,
    search: <><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></>,
    bell: <><path d="M6 8a6 6 0 1 1 12 0c0 5 2 6 2 7H4c0-1 2-2 2-7"/><path d="M10 19a2 2 0 0 0 4 0"/></>,
    paperclip: <><path d="M21 11.5 12.5 20a5 5 0 0 1-7-7L14 4.5a3.5 3.5 0 0 1 5 5L10.5 18a2 2 0 0 1-3-3L15 7.5"/></>,
    image: <><rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="m3 17 5-5 4 4 3-3 6 6"/></>,
    send: <><path d="m4 12 16-8-6 18-2-8z"/><path d="M4 12 14 14"/></>,
    chevronDown: <><path d="m6 9 6 6 6-6"/></>,
    chevronLeft: <><path d="m14 6-6 6 6 6"/></>,
    check: <><path d="m5 12 5 5 9-11"/></>,
    x: <><path d="m6 6 12 12M18 6 6 18"/></>,
    filter: <><path d="M4 5h16M7 12h10M10 19h4"/></>,
    clock: <><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></>,
    user: <><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></>,
    inbox: <><path d="M3 13v6a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-6M3 13l3-8h12l3 8M3 13h5l2 3h4l2-3h5"/></>,
    flag: <><path d="M4 21V4h12l-2 4 2 4H4"/></>,
    settings: <><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></>,
    logout: <><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/></>,
    trash: <><path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M6 6l1 14a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-14"/></>,
  };
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor"
         strokeWidth={stroke} strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      {paths[name] || null}
    </svg>
  );
};

const StatePill = ({ state }) => {
  const m = STATE_META[state] || STATE_META.open;
  return (
    <span className="pill" style={{ color: m.fg, background: m.bg }}>
      <span className="pill-dot" style={{ background: m.dot }} />
      {m.label}
    </span>
  );
};

const PriorityPill = ({ priority }) => {
  const m = PRIORITY_META[priority] || PRIORITY_META.normal;
  return (
    <span className="pill pill--quiet" style={{ color: m.fg, background: m.bg }}>
      {m.label}
    </span>
  );
};

const Avatar = ({ name, size = 28, tone = "accent" }) => {
  const initials = (name || "?")
    .split(/\s+/).slice(0, 2).map(s => s[0]).join("").toUpperCase();
  return (
    <span className={"avatar avatar--" + tone}
          style={{ width: size, height: size, fontSize: Math.round(size * 0.42) }}>
      {initials}
    </span>
  );
};

const Spinner = ({ size = 14 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" className="spin">
    <circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" strokeOpacity=".25" strokeWidth="3"/>
    <path d="M21 12a9 9 0 0 0-9-9" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round"/>
  </svg>
);

// Tiny inline logo mark (geometric, original — not a brand)
const LogoMark = () => (
  <svg width="22" height="22" viewBox="0 0 32 32" aria-hidden="true">
    <rect x="2"  y="2"  width="13" height="13" rx="3" fill="var(--accent)"/>
    <rect x="17" y="2"  width="13" height="13" rx="3" fill="var(--accent-soft)"/>
    <rect x="2"  y="17" width="13" height="13" rx="3" fill="var(--accent-soft)"/>
    <rect x="17" y="17" width="13" height="13" rx="3" fill="var(--ink)"/>
  </svg>
);

Object.assign(window, { Icon, StatePill, PriorityPill, Avatar, Spinner, LogoMark });
