// Agent Console main app

const { useState: useSA, useEffect: useEA, useMemo: useMA } = React;

const A_TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "indigo",
  "density": "comfy",
  "darkMode": false,
  "overviewsLayout": "tabs"
}/*EDITMODE-END*/;

function applyAgentTweaks(t) {
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
    cozy:    { row: "30px", pad: "10px", font: "13px", title: "20px" },
    comfy:   { row: "40px", pad: "13px", font: "14px", title: "22px" },
    relaxed: { row: "52px", pad: "16px", font: "15px", title: "26px" },
  };
  const d = densities[t.density] || densities.comfy;
  root.style.setProperty("--row-h", d.row);
  root.style.setProperty("--pad", d.pad);
  root.style.setProperty("--font", d.font);
  root.style.setProperty("--title", d.title);

  if (t.darkMode) root.setAttribute("data-theme", "dark");
  else root.removeAttribute("data-theme");
}

function AgentSidebar({ route, onNav, counts }) {
  const items = [
    { key: "dashboard", label: "Dashboard",  icon: "dashboard" },
    { key: "overviews", label: "Overviews",  icon: "inbox", badge: counts.openMine },
  ];
  return (
    <aside className="sidebar">
      <div className="brand">
        <LogoMark/>
        <div>
          <div className="brand-name">Helpdesk</div>
          <div className="brand-sub">Agent console</div>
        </div>
      </div>

      <button className="new-btn"><Icon name="plus" size={14}/> New ticket</button>

      <nav className="nav">
        {items.map(it => {
          const active = route.name === it.key || (it.key === "overviews" && route.name === "detail");
          return (
            <button key={it.key} className={"nav-item" + (active ? " nav-item--on" : "")}
                    onClick={() => onNav(it.key)}>
              <Icon name={it.icon} size={16}/><span>{it.label}</span>
              {it.badge ? <span className="nav-badge">{it.badge}</span> : null}
            </button>
          );
        })}
      </nav>

      <div className="nav-section">Queues</div>
      <nav className="nav">
        <button className="nav-item nav-item--quiet" onClick={() => onNav("overviews", { view: "my_assigned" })}>
          <span className="dot" style={{ background: "var(--accent)" }}/> My assigned
          <span className="nav-icon-count">{counts.assignedMe}</span>
        </button>
        <button className="nav-item nav-item--quiet" onClick={() => onNav("overviews", { view: "unassigned_open" })}>
          <span className="dot" style={{ background: "var(--st-open)" }}/> Unassigned
          <span className="nav-icon-count">{counts.unassigned}</span>
        </button>
        <button className="nav-item nav-item--quiet" onClick={() => onNav("overviews", { view: "pending" })}>
          <span className="dot" style={{ background: "var(--st-pend)" }}/> Pending
          <span className="nav-icon-count">{counts.pending}</span>
        </button>
        <button className="nav-item nav-item--quiet" onClick={() => onNav("overviews", { view: "escalated" })}>
          <span className="dot" style={{ background: "var(--pri-high-fg)" }}/> Escalated
          <span className="nav-icon-count">{counts.escalated}</span>
        </button>
      </nav>

      <div className="nav-section">Admin</div>
      <nav className="nav">
        <button className={"nav-item" + (route.name === "manage" ? " nav-item--on" : "")}
                onClick={() => onNav("manage", { section: "users" })}>
          <Icon name="user" size={16}/><span>Users</span>
        </button>
        <button className={"nav-item" + (route.name === "manage" && route.section?.startsWith("ch_") ? " nav-item--on" : "")}
                onClick={() => onNav("manage", { section: "ch_web" })}>
          <Icon name="inbox" size={16}/><span>Channels</span>
        </button>
        <button className={"nav-item" + (route.name === "manage" && ["branding","system","security","api"].includes(route.section) ? " nav-item--on" : "")}
                onClick={() => onNav("manage", { section: "branding" })}>
          <Icon name="settings" size={16}/><span>Settings</span>
        </button>
      </nav>

      <div className="sidebar-spacer"/>

      <div className="user-card">
        <Avatar name={ME_AGENT.name} size={32} tone={ME_AGENT.tone}/>
        <div className="user-meta">
          <div className="user-name">{ME_AGENT.name}</div>
          <div className="user-email">{ME_AGENT.role} · {ME_AGENT.email}</div>
        </div>
        <button className="icon-btn" title="Sign out"><Icon name="logout" size={14}/></button>
      </div>
    </aside>
  );
}

function Toast({ msg, onDone }) {
  useEA(() => {
    if (!msg) return;
    const id = setTimeout(onDone, 2400);
    return () => clearTimeout(id);
  }, [msg]);
  if (!msg) return null;
  return <div className="toast"><Icon name="check" size={14}/> {msg}</div>;
}

function AgentApp() {
  const [tickets, setTickets] = useSA(A_TICKETS);
  const [route, setRoute] = useSA({ name: "dashboard" });
  const [overviewView, setOverviewView] = useSA("my_assigned");
  const [toast, setToast] = useSA("");
  const [tweaks, setTweak] = window.useTweaks(A_TWEAK_DEFAULTS);

  useEA(() => { applyAgentTweaks(tweaks); }, [tweaks]);

  const counts = useMA(() => ({
    openMine:    tickets.filter(t => t.assigneeId === ME_AGENT.id && (t.state === "open" || t.state === "pending")).length,
    assignedMe:  tickets.filter(t => t.assigneeId === ME_AGENT.id && t.state !== "closed" && t.state !== "resolved").length,
    unassigned:  tickets.filter(t => !t.assigneeId && t.state === "open").length,
    pending:     tickets.filter(t => t.state === "pending").length,
    escalated:   tickets.filter(t => t.priority === "high" && t.state !== "closed" && t.state !== "resolved").length,
  }), [tickets]);

  const nav = (name, opts = {}) => {
    if (name === "overviews" && opts.view) setOverviewView(opts.view);
    setRoute({ name, ...opts });
  };
  const openTicket = (id) => {
    setTickets(arr => arr.map(t => t.id === id ? { ...t, unread: 0 } : t));
    setRoute({ name: "detail", id });
  };
  const updateTicket = (id, patch) => {
    setTickets(arr => arr.map(t => t.id === id ? { ...t, ...patch, updatedAt: Date.now() } : t));
    if (patch.state) setToast("State updated to " + patch.state);
    else if (patch.priority) setToast("Priority set to " + patch.priority);
    else if (patch.group) setToast("Moved to " + patch.group);
    else if ("assigneeId" in patch) setToast(patch.assigneeId ? "Assigned" : "Unassigned");
  };
  const replyTicket = (id, m) => {
    setTickets(arr => arr.map(t => t.id === id
      ? { ...t, updatedAt: Date.now(),
          messages: [...t.messages, { ...m, at: Date.now() }] }
      : t));
    setToast(m.from === "internal" ? "Internal note posted" : "Reply sent");
  };

  let screen = null;
  if (route.name === "dashboard")
    screen = <AgentDashboard tickets={tickets} onOpen={openTicket} onNav={nav}/>;
  else if (route.name === "overviews")
    screen = <OverviewsScreen tickets={tickets} onOpen={openTicket}
                              view={overviewView} setView={setOverviewView}
                              layout={tweaks.overviewsLayout}
                              onNew={() => setToast("New ticket flow goes here")}/>;
  else if (route.name === "detail")
    screen = <AgentTicketDetail tickets={tickets} ticketId={route.id}
                                onOpen={openTicket} onReply={replyTicket}
                                onUpdate={updateTicket} onBack={() => nav("overviews")}/>;
  else if (route.name === "manage")
    screen = <ManageScreen section={route.section || "users"}
                           onPickSection={(s) => nav("manage", { section: s })}/>;

  return (
    <div className="app-agent">
      <AgentSidebar route={route} onNav={nav} counts={counts}/>
      <main className="main">{screen}</main>
      <Toast msg={toast} onDone={() => setToast("")}/>

      <window.TweaksPanel title="Tweaks">
        <window.TweakSection label="Appearance">
          <window.TweakToggle label="Dark mode" value={tweaks.darkMode}
            onChange={v => setTweak("darkMode", v)}/>
          <window.TweakRadio label="Density" options={["cozy", "comfy", "relaxed"]}
            value={tweaks.density} onChange={v => setTweak("density", v)}/>
          <window.TweakSelect label="Accent" options={["indigo", "teal", "rose", "slate"]}
            value={tweaks.accent} onChange={v => setTweak("accent", v)}/>
        </window.TweakSection>
        <window.TweakSection label="Layouts">
          <window.TweakRadio label="Overviews" options={["tabs", "sidebar"]}
            value={tweaks.overviewsLayout} onChange={v => setTweak("overviewsLayout", v)}/>
        </window.TweakSection>
      </window.TweaksPanel>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<AgentApp/>);
