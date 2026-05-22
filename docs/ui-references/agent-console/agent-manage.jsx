// Manage screens: Users, Channels, Branding, Manage index

const { useState: useSM, useMemo: useMM } = React;

const MANAGE_SECTIONS = [
  { group: "Manage", items: [
    { key: "users", label: "Users" },
    { key: "groups", label: "Groups" },
    { key: "roles", label: "Roles" },
    { key: "orgs", label: "Organizations" },
    { key: "macros", label: "Macros" },
    { key: "templates", label: "Templates" },
    { key: "tags", label: "Tags" },
    { key: "slas", label: "SLAs" },
    { key: "triggers", label: "Triggers" },
  ]},
  { group: "Channels", items: [
    { key: "ch_web", label: "Web" },
    { key: "ch_form", label: "Form" },
    { key: "ch_email", label: "Email" },
    { key: "ch_sms", label: "SMS" },
    { key: "ch_chat", label: "Chat" },
  ]},
  { group: "Settings", items: [
    { key: "branding", label: "Branding" },
    { key: "system", label: "System" },
    { key: "security", label: "Security" },
    { key: "api", label: "API" },
  ]},
];

function ManageSidebar({ active, onPick }) {
  return (
    <aside className="split-side">
      {MANAGE_SECTIONS.map(sec => (
        <React.Fragment key={sec.group}>
          <div className="split-side-group">{sec.group}</div>
          {sec.items.map(it => (
            <div key={it.key}
                 className={"split-side-item" + (active === it.key ? " split-side-item--on" : "")}
                 onClick={() => onPick(it.key)}>
              {it.label}
            </div>
          ))}
        </React.Fragment>
      ))}
    </aside>
  );
}

// ---- Users ----
function UsersPanel() {
  const [filter, setFilter] = useSM("all");
  const [query, setQuery] = useSM("");

  // Combine agents + customers into a "users" list
  const all = useMM(() => {
    const agents = AGENTS.map(a => ({ ...a, kind: a.role.toLowerCase(), org: null }));
    const cust = CUSTOMERS.map(c => ({ ...c, kind: "customer", role: "Customer", org: orgById(c.orgId)?.name || "—" }));
    return [...agents, ...cust];
  }, []);

  let list = all;
  if (filter !== "all") list = list.filter(u => u.kind === filter);
  if (query.trim()) {
    const q = query.toLowerCase();
    list = list.filter(u => u.name.toLowerCase().includes(q) || u.email.toLowerCase().includes(q));
  }

  return (
    <div style={{ padding: "20px 24px" }}>
      <header className="screen-head" style={{ borderBottom: 0, padding: "0 0 12px" }}>
        <div>
          <div className="kicker">Manage</div>
          <h1 className="screen-title">Users <span className="muted" style={{ fontSize: 14, fontWeight: 500 }}>· {list.length}</span></h1>
        </div>
        <div className="screen-actions">
          <div className="search">
            <Icon name="search" size={14}/>
            <input placeholder="Search by name or email…" value={query} onChange={e => setQuery(e.target.value)}/>
          </div>
          <button className="btn btn--ghost">Import</button>
          <button className="btn btn--primary"><Icon name="plus" size={14}/> New user</button>
        </div>
      </header>

      <div className="tabs" style={{ paddingLeft: 0, paddingRight: 0, marginBottom: 12 }}>
        {[
          { k: "all", l: "All" },
          { k: "admin", l: "Admins" },
          { k: "agent", l: "Agents" },
          { k: "customer", l: "Customers" },
        ].map(t => (
          <button key={t.k} className={"tab" + (filter === t.k ? " tab--active" : "")} onClick={() => setFilter(t.k)}>
            {t.l}
            <span className="tab-count">{all.filter(u => t.k === "all" ? true : u.kind === t.k).length}</span>
          </button>
        ))}
      </div>

      <table className="user-table">
        <thead>
          <tr>
            <th>Name</th>
            <th style={{ width: 240 }}>Email</th>
            <th style={{ width: 100 }}>Role</th>
            <th style={{ width: 180 }}>Organization</th>
            <th style={{ width: 100 }}>Status</th>
            <th style={{ width: 40 }}></th>
          </tr>
        </thead>
        <tbody>
          {list.map(u => (
            <tr key={u.id} style={{ cursor: "pointer" }}>
              <td>
                <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                  <Avatar name={u.name} size={26} tone={u.tone || "neutral"}/>
                  <span style={{ fontWeight: 500 }}>{u.name}</span>
                </div>
              </td>
              <td className="muted" style={{ fontSize: 13 }}>{u.email}</td>
              <td>
                <span className={"role-chip role-chip--" + u.kind}>{u.role}</span>
              </td>
              <td className="muted" style={{ fontSize: 13 }}>{u.org || "—"}</td>
              <td>
                <span style={{ fontSize: 12, color: "oklch(45% 0.12 155)" }}>● Active</span>
              </td>
              <td>
                <button className="icon-btn"><Icon name="settings" size={14}/></button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// ---- Channels ----
function ChannelsPanel({ which }) {
  const channels = [
    { key: "ch_web",   label: "Web widget", on: true,  desc: "Embed a help widget on any page" },
    { key: "ch_form",  label: "Form",       on: false, desc: "Drop a ticket form into your site" },
    { key: "ch_email", label: "Email",      on: true,  desc: "Inbound + outbound email channels" },
    { key: "ch_sms",   label: "SMS",        on: false, desc: "Tickets from text messages" },
    { key: "ch_chat",  label: "Live chat",  on: true,  desc: "Real-time chat with customers" },
  ];

  return (
    <div style={{ padding: "20px 24px" }}>
      <header className="screen-head" style={{ borderBottom: 0, padding: "0 0 12px" }}>
        <div>
          <div className="kicker">Channels</div>
          <h1 className="screen-title">{which === "ch_form" ? "Form channel" : "Channels"}</h1>
        </div>
      </header>

      {which !== "ch_form" ? (
        <div className="channel-grid">
          {channels.map(c => (
            <div key={c.key} className="channel-card">
              <div className="channel-card-head">
                <div className="channel-card-icon">
                  <Icon name={c.key === "ch_email" ? "inbox" : c.key === "ch_chat" ? "tickets" : "dashboard"} size={16}/>
                </div>
                <span className={"channel-status " + (c.on ? "channel-status--on" : "channel-status--off")}>
                  {c.on ? "Connected" : "Off"}
                </span>
              </div>
              <div className="channel-card-name">{c.label}</div>
              <div className="channel-card-sub">{c.desc}</div>
            </div>
          ))}
        </div>
      ) : (
        <FormChannel/>
      )}
    </div>
  );
}

function FormChannel() {
  const [on, setOn] = useSM(false);
  return (
    <>
      <div className="settings-section">
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <div>
            <h3>Embeddable form</h3>
            <p>Drop a form on your site and tickets flow straight into the inbox.</p>
          </div>
          <button onClick={() => setOn(!on)}
                  style={{
                    width: 44, height: 24, borderRadius: 999,
                    background: on ? "var(--accent)" : "var(--surface-3)",
                    position: "relative", transition: "background .15s",
                  }}>
            <span style={{
              position: "absolute", top: 2, left: on ? 22 : 2,
              width: 20, height: 20, borderRadius: "50%",
              background: "var(--surface)", transition: "left .15s",
              boxShadow: "0 1px 3px rgba(0,0,0,0.2)",
            }}/>
          </button>
        </div>
      </div>

      <div className="settings-section">
        <h3>Designer</h3>
        <p>Settings for the embeddable form.</p>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14, marginTop: 8 }}>
          <label className="field">
            <span className="field-lbl">Title of the form</span>
            <input defaultValue="Get in touch"/>
          </label>
          <label className="field">
            <span className="field-lbl">Submit button label</span>
            <input defaultValue="Send message"/>
          </label>
          <label className="field" style={{ gridColumn: "1 / -1" }}>
            <span className="field-lbl">Message after sending</span>
            <input defaultValue="Thanks — we'll be in touch shortly."/>
          </label>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 8, marginTop: 14 }}>
          {[
            "Show title in form",
            "Open as modal dialog",
            "Allow file attachments",
            "Require agreement before submit",
          ].map(o => (
            <label key={o} style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 13 }}>
              <input type="checkbox" defaultChecked={o === "Show title in form"}/>
              {o}
            </label>
          ))}
        </div>
      </div>
    </>
  );
}

// ---- Branding settings ----
function BrandingPanel() {
  return (
    <div style={{ padding: "20px 24px", maxWidth: 800 }}>
      <header className="screen-head" style={{ borderBottom: 0, padding: "0 0 12px" }}>
        <div>
          <div className="kicker">Settings</div>
          <h1 className="screen-title">Branding</h1>
        </div>
      </header>

      <div className="settings-section">
        <h3>Product name</h3>
        <p>Shown in the title bar and emails. Keep it short.</p>
        <div className="settings-row">
          <input defaultValue="Cenports Helpdesk"/>
          <button className="btn btn--primary">Save</button>
        </div>
      </div>

      <div className="settings-section">
        <h3>Organization</h3>
        <p>Included in email footers and shown to customers.</p>
        <div className="settings-row">
          <input defaultValue="Cenports"/>
          <button className="btn btn--primary">Save</button>
        </div>
      </div>

      <div className="settings-section">
        <h3>Logo</h3>
        <p>SVG or PNG. Used in customer-facing emails and the portal header.</p>
        <div style={{
          marginTop: 8,
          background: "var(--ink)", borderRadius: 8, padding: 40,
          display: "grid", placeItems: "center",
        }}>
          <div style={{
            width: 200, background: "var(--surface)", borderRadius: 8, padding: 24,
            display: "grid", placeItems: "center",
          }}>
            <LogoMark/>
          </div>
        </div>
        <div className="settings-row">
          <button className="btn btn--ghost">Upload new logo</button>
          <button className="btn btn--ghost">Reset to default</button>
        </div>
      </div>

      <div className="settings-section">
        <h3>Default color</h3>
        <p>Applied to buttons, links, and brand accents across the customer portal.</p>
        <div className="settings-row" style={{ flexWrap: "wrap", gap: 8 }}>
          {[
            { name: "Indigo", c: "oklch(55% 0.17 264)" },
            { name: "Teal",   c: "oklch(54% 0.11 195)" },
            { name: "Rose",   c: "oklch(58% 0.17 18)" },
            { name: "Slate",  c: "oklch(34% 0.03 260)" },
          ].map(s => (
            <button key={s.name} style={{
              display: "flex", alignItems: "center", gap: 8,
              padding: "6px 10px", borderRadius: 6,
              border: "1px solid var(--border)", background: "var(--surface)",
              fontSize: 13,
            }}>
              <span style={{ width: 14, height: 14, borderRadius: "50%", background: s.c, display: "inline-block" }}/>
              {s.name}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

// ---- Generic placeholder for sections we haven't fully built ----
function GenericManagePanel({ title, kicker }) {
  return (
    <div style={{ padding: "20px 24px" }}>
      <header className="screen-head" style={{ borderBottom: 0, padding: "0 0 12px" }}>
        <div>
          <div className="kicker">{kicker}</div>
          <h1 className="screen-title">{title}</h1>
        </div>
        <div className="screen-actions">
          <button className="btn btn--primary"><Icon name="plus" size={14}/> New</button>
        </div>
      </header>
      <div className="settings-section">
        <h3>Configure {title.toLowerCase()}</h3>
        <p>This section uses the same patterns as the rest of the console — list table, edit modal, save bar.</p>
        <div style={{
          display: "grid", gap: 0,
          border: "1px solid var(--border)", borderRadius: 8, overflow: "hidden",
          background: "var(--surface)",
        }}>
          {[1, 2, 3, 4].map(i => (
            <div key={i} style={{
              display: "grid", gridTemplateColumns: "1fr auto auto",
              alignItems: "center", gap: 12,
              padding: "10px 14px", borderBottom: i < 4 ? "1px solid var(--border)" : 0,
              fontSize: 13.5,
            }}>
              <div>
                <strong style={{ fontWeight: 500 }}>{title} item {i}</strong>
                <div className="muted" style={{ fontSize: 12 }}>Sample row · last updated {i}d ago</div>
              </div>
              <span className="role-chip" style={{ background: "var(--surface-3)" }}>Active</span>
              <button className="icon-btn"><Icon name="settings" size={13}/></button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function ManageScreen({ section, onPickSection }) {
  let panel;
  if (section === "users") panel = <UsersPanel/>;
  else if (section?.startsWith("ch_")) panel = <ChannelsPanel which={section}/>;
  else if (section === "branding") panel = <BrandingPanel/>;
  else {
    const label = MANAGE_SECTIONS.flatMap(s => s.items).find(i => i.key === section)?.label || "Settings";
    const group = MANAGE_SECTIONS.find(s => s.items.some(i => i.key === section))?.group || "Manage";
    panel = <GenericManagePanel title={label} kicker={group}/>;
  }
  return (
    <div className="split-layout">
      <ManageSidebar active={section} onPick={onPickSection}/>
      <div className="split-main">{panel}</div>
    </div>
  );
}

Object.assign(window, { ManageScreen });
