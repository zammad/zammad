// App shell + sidebar + router

const { useState: useStateApp, useEffect: useEffectApp } = React;

function Sidebar({ route, onNav, unread, onNew }) {
  const items = [
    { key: "dashboard", label: "Dashboard", icon: "dashboard" },
    { key: "tickets",   label: "My tickets", icon: "tickets", badge: unread },
  ];
  return (
    <aside className="sidebar">
      <div className="brand">
        <LogoMark/>
        <div>
          <div className="brand-name">Helpdesk</div>
          <div className="brand-sub">Cenports portal</div>
        </div>
      </div>

      <button className="new-btn" onClick={onNew}>
        <Icon name="plus" size={14}/> New ticket
      </button>

      <nav className="nav">
        {items.map(it => {
          const active = route.name === it.key || (it.key === "tickets" && route.name === "detail");
          return (
            <button key={it.key}
                    className={"nav-item" + (active ? " nav-item--on" : "")}
                    onClick={() => onNav(it.key)}>
              <Icon name={it.icon} size={16}/>
              <span>{it.label}</span>
              {it.badge ? <span className="nav-badge">{it.badge}</span> : null}
            </button>
          );
        })}
      </nav>

      <div className="nav-section">Filters</div>
      <nav className="nav">
        <button className="nav-item nav-item--quiet" onClick={() => onNav("tickets", { state: "open" })}>
          <span className="dot" style={{ background: "var(--st-open)" }}/> Open
        </button>
        <button className="nav-item nav-item--quiet" onClick={() => onNav("tickets", { state: "pending" })}>
          <span className="dot" style={{ background: "var(--st-pend)" }}/> Awaiting you
        </button>
        <button className="nav-item nav-item--quiet" onClick={() => onNav("tickets", { state: "resolved" })}>
          <span className="dot" style={{ background: "var(--st-res)" }}/> Resolved
        </button>
        <button className="nav-item nav-item--quiet" onClick={() => onNav("tickets", { state: "closed" })}>
          <span className="dot" style={{ background: "var(--st-closed)" }}/> Closed
        </button>
      </nav>

      <div className="sidebar-spacer"/>

      <div className="user-card">
        <Avatar name="Wayne T." size={32}/>
        <div className="user-meta">
          <div className="user-name">Wayne Test</div>
          <div className="user-email">wayne@cenports.com</div>
        </div>
        <button className="icon-btn" title="Sign out"><Icon name="logout" size={14}/></button>
      </div>
    </aside>
  );
}

function Toast({ msg, onDone }) {
  useEffectApp(() => {
    if (!msg) return;
    const id = setTimeout(onDone, 2400);
    return () => clearTimeout(id);
  }, [msg]);
  if (!msg) return null;
  return <div className="toast"><Icon name="check" size={14}/> {msg}</div>;
}

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "indigo",
  "density": "comfy"
}/*EDITMODE-END*/;

function applyTweaks(t) {
  const root = document.documentElement;
  const palettes = {
    indigo: { accent: "oklch(55% 0.17 264)", soft: "oklch(94% 0.03 264)", ring: "oklch(55% 0.17 264 / 0.18)" },
    teal:   { accent: "oklch(54% 0.11 195)", soft: "oklch(94% 0.03 195)", ring: "oklch(54% 0.11 195 / 0.18)" },
    rose:   { accent: "oklch(58% 0.17 18)",  soft: "oklch(94% 0.03 18)",  ring: "oklch(58% 0.17 18 / 0.18)" },
    slate:  { accent: "oklch(34% 0.03 260)", soft: "oklch(92% 0.01 260)", ring: "oklch(34% 0.03 260 / 0.20)" },
  };
  const p = palettes[t.accent] || palettes.indigo;
  root.style.setProperty("--accent", p.accent);
  root.style.setProperty("--accent-soft", p.soft);
  root.style.setProperty("--accent-ring", p.ring);

  const densities = {
    cozy:    { row: "32px", pad: "10px", font: "13px", title: "20px" },
    comfy:   { row: "44px", pad: "14px", font: "14px", title: "22px" },
    relaxed: { row: "56px", pad: "18px", font: "15px", title: "26px" },
  };
  const d = densities[t.density] || densities.comfy;
  root.style.setProperty("--row-h", d.row);
  root.style.setProperty("--pad", d.pad);
  root.style.setProperty("--font", d.font);
  root.style.setProperty("--title", d.title);
}

function App() {
  const [tickets, setTickets] = useStateApp(INITIAL_TICKETS);
  const [route, setRoute] = useStateApp({ name: "dashboard" });
  const [filter, setFilter] = useStateApp({ state: "all", category: null });
  const [toast, setToast] = useStateApp("");
  const [tweaks, setTweak] = window.useTweaks(TWEAK_DEFAULTS);

  useEffectApp(() => { applyTweaks(tweaks); }, [tweaks]);

  const unread = tickets.reduce((n, t) => n + (t.unread || 0), 0);

  const nav = (name, opts = {}) => {
    if (name === "tickets" && opts.state) setFilter(f => ({ ...f, state: opts.state }));
    setRoute({ name, ...opts });
  };
  const openT = (id) => {
    setTickets(arr => arr.map(t => t.id === id ? { ...t, unread: 0 } : t));
    setRoute({ name: "detail", id });
  };
  const replyTo = (id, { body, attachments }) => {
    setTickets(arr => arr.map(t => t.id === id
      ? { ...t, updatedAt: Date.now(), state: t.state === "pending" ? "open" : t.state,
          messages: [...t.messages, { from: "me", author: "Wayne T.", body, attachments, at: Date.now() }] }
      : t));
    setToast("Reply sent");
  };
  const updateState = (id, state) => {
    setTickets(arr => arr.map(t => t.id === id ? { ...t, state, updatedAt: Date.now() } : t));
    setToast(state === "resolved" ? "Ticket marked resolved" : state === "open" ? "Ticket reopened" : "Updated");
  };
  const createTicket = ({ title, category, priority, body, attachments }) => {
    const id = Math.max(...tickets.map(t => t.id)) + 1;
    const t = {
      id, title, category, priority, state: "open",
      createdAt: Date.now(), updatedAt: Date.now(), unread: 0,
      messages: [{ from: "me", author: "Wayne T.", body, attachments, at: Date.now() }],
    };
    setTickets(arr => [t, ...arr]);
    setRoute({ name: "detail", id });
    setToast("Ticket #" + id + " submitted");
  };

  let screen = null;
  if (route.name === "dashboard")
    screen = <Dashboard tickets={tickets} onOpen={openT} onNew={() => setRoute({ name: "new" })} onNav={nav}/>;
  else if (route.name === "tickets")
    screen = <TicketList tickets={tickets} onOpen={openT} onNew={() => setRoute({ name: "new" })} filter={filter} setFilter={setFilter}/>;
  else if (route.name === "detail") {
    const t = tickets.find(x => x.id === route.id);
    screen = <TicketDetail ticket={t} onBack={() => nav("tickets")} onReply={replyTo} onUpdateState={updateState}/>;
  } else if (route.name === "new")
    screen = <NewTicket onCancel={() => nav("tickets")} onCreate={createTicket}/>;

  return (
    <div className="app">
      <Sidebar route={route} onNav={nav} unread={unread} onNew={() => setRoute({ name: "new" })}/>
      <main className="main">{screen}</main>
      <Toast msg={toast} onDone={() => setToast("")}/>

      <window.TweaksPanel title="Tweaks">
        <window.TweakSection label="Density">
          <window.TweakRadio label="Size" options={["cozy", "comfy", "relaxed"]}
            value={tweaks.density} onChange={v => setTweak("density", v)}/>
        </window.TweakSection>
        <window.TweakSection label="Accent">
          <window.TweakSelect label="Color"
            options={["indigo", "teal", "rose", "slate"]}
            value={tweaks.accent} onChange={v => setTweak("accent", v)}/>
        </window.TweakSection>
      </window.TweaksPanel>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App/>);
