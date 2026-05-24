// Agent Console — Dashboard, Overviews, Ticket Detail (3-col), Manage screens

const { useState: useS, useEffect: useE, useMemo: useM, useRef: useR } = React;

// ============= Agent Dashboard =============
function AgentDashboard({ tickets, onOpen, onNav }) {
  const myTickets = tickets.filter(t => t.assigneeId === ME_AGENT.id);
  const mineOpen = myTickets.filter(t => t.state === "open" || t.state === "pending");
  const unassigned = tickets.filter(t => !t.assigneeId && t.state !== "closed" && t.state !== "resolved");
  const breachingSoon = tickets
    .filter(t => t.slaDueAt && t.slaDueAt > Date.now() && t.slaDueAt - Date.now() < 60 * 60 * 1000)
    .sort((a, b) => a.slaDueAt - b.slaDueAt);

  const avgHandle = "14m";
  const replyRate = 92;
  const csat = "4.7";

  // Workload by agent
  const workload = AGENTS.map(a => ({
    agent: a,
    count: tickets.filter(t => t.assigneeId === a.id && (t.state === "open" || t.state === "pending")).length,
  }));
  const maxLoad = Math.max(1, ...workload.map(w => w.count));

  // Sparkline (mock)
  const spark = [3, 5, 4, 8, 6, 9, 12, 10, 11, 14, 12, 15];
  const sw = 120, sh = 32;
  const sMax = Math.max(...spark), sMin = Math.min(...spark);
  const sPts = spark.map((v, i) =>
    [(i / (spark.length - 1)) * sw, sh - ((v - sMin) / (sMax - sMin || 1)) * sh].join(",")
  ).join(" ");
  const sFill = `M0,${sh} L${sPts.split(" ").join(" L")} L${sw},${sh} Z`;

  return (
    <div className="screen">
      <header className="screen-head">
        <div>
          <div className="kicker">Agent console</div>
          <h1 className="screen-title">Good afternoon, {ME_AGENT.name.split(" ")[0]}</h1>
        </div>
        <div className="screen-actions">
          <button className="btn btn--ghost" onClick={() => onNav("overviews")}>
            <Icon name="inbox" size={14}/> Open overviews
          </button>
          <button className="btn btn--primary">
            <Icon name="plus" size={14}/> New ticket
          </button>
        </div>
      </header>

      <div className="agent-dash">
        <div className="dash-main">
          {/* Metrics */}
          <div className="metric-grid">
            <div className="metric">
              <div className="metric-lbl">My open</div>
              <div className="metric-val">{mineOpen.length}<span className="metric-unit">tickets</span></div>
              <div className="metric-sub">
                <span className="metric-delta metric-delta--up">↑ 2</span> vs yesterday
              </div>
            </div>
            <div className="metric">
              <div className="metric-lbl">Avg handle time</div>
              <div className="metric-val">{avgHandle}</div>
              <div className="metric-sub">
                <span className="metric-delta metric-delta--down">↓ 1.2m</span> this week
              </div>
            </div>
            <div className="metric">
              <div className="metric-lbl">First-reply rate</div>
              <div className="metric-val">{replyRate}<span className="metric-unit">%</span></div>
              <svg className="spark" width={sw} height={sh} viewBox={`0 0 ${sw} ${sh}`}>
                <path className="spark-fill" d={sFill}/>
                <polyline points={sPts} fill="none" stroke="var(--accent)" strokeWidth="1.5"/>
              </svg>
            </div>
            <div className="metric">
              <div className="metric-lbl">CSAT (30d)</div>
              <div className="metric-val">{csat}<span className="metric-unit">/ 5.0</span></div>
              <div className="metric-sub">{124} responses</div>
            </div>
          </div>

          {/* My open queue */}
          <section className="card">
            <div className="card-head">
              <h2>My open tickets</h2>
              <button className="link" onClick={() => onNav("overviews")}>View all →</button>
            </div>
            <ul className="queue-list">
              {mineOpen.slice(0, 6).map(t => {
                const c = custById(t.customerId);
                const breach = t.slaDueAt && t.slaDueAt - Date.now() < 30 * 60 * 1000;
                const soon = t.slaDueAt && !breach && t.slaDueAt - Date.now() < 2 * 60 * 60 * 1000;
                return (
                  <li key={t.id} onClick={() => onOpen(t.id)}>
                    <StatePill state={t.state}/>
                    <div>
                      <div className="queue-title">{t.title}</div>
                      <div className="queue-meta">
                        <span className="tid">#{t.id}</span>
                        <span>· {c?.name}</span>
                        <span>· {t.group}</span>
                      </div>
                    </div>
                    {t.slaDueAt && (
                      <span className={"queue-sla" + (breach ? " queue-sla--breach" : soon ? " queue-sla--soon" : "")}>
                        SLA {a_relTime(t.slaDueAt).replace("just now", "now")}
                      </span>
                    )}
                    <PriorityPill priority={t.priority}/>
                  </li>
                );
              })}
              {mineOpen.length === 0 && (
                <li><div className="empty"><Icon name="check" size={18}/> Inbox zero. Nice work.</div></li>
              )}
            </ul>
          </section>

          {/* Unassigned */}
          <section className="card">
            <div className="card-head">
              <h2>Unassigned & open</h2>
              <span className="muted">{unassigned.length} total</span>
            </div>
            <ul className="queue-list">
              {unassigned.slice(0, 4).map(t => {
                const c = custById(t.customerId);
                return (
                  <li key={t.id} onClick={() => onOpen(t.id)}>
                    <Avatar name={c?.name} size={22} tone="neutral"/>
                    <div>
                      <div className="queue-title">{t.title}</div>
                      <div className="queue-meta">
                        <span className="tid">#{t.id}</span>
                        <span>· {c?.name} · {t.group} · created {a_relTime(t.createdAt)} ago</span>
                      </div>
                    </div>
                    <button className="btn btn--ghost" style={{ padding: "4px 10px", fontSize: 12 }}
                            onClick={(e) => { e.stopPropagation(); onOpen(t.id); }}>
                      Claim
                    </button>
                    <PriorityPill priority={t.priority}/>
                  </li>
                );
              })}
              {unassigned.length === 0 && (
                <li><div className="empty"><Icon name="check" size={18}/> Everything is assigned.</div></li>
              )}
            </ul>
          </section>
        </div>

        <div className="dash-aside">
          {/* SLA risk */}
          <section className="card card-tight">
            <div className="card-head">
              <h2>SLA at risk</h2>
              <span className="muted">{breachingSoon.length}</span>
            </div>
            <ul className="queue-list">
              {breachingSoon.length === 0 && (
                <li style={{ padding: 12 }}><span className="muted" style={{ fontSize: 13 }}>None within the next hour.</span></li>
              )}
              {breachingSoon.slice(0, 4).map(t => {
                const breach = t.slaDueAt - Date.now() < 30 * 60 * 1000;
                return (
                  <li key={t.id} onClick={() => onOpen(t.id)} style={{ gridTemplateColumns: "1fr auto" }}>
                    <div>
                      <div className="queue-title" style={{ fontSize: 13 }}>{t.title}</div>
                      <div className="queue-meta">
                        <span className="tid">#{t.id}</span>
                      </div>
                    </div>
                    <span className={"queue-sla" + (breach ? " queue-sla--breach" : " queue-sla--soon")}>
                      <Icon name="clock" size={11}/> {a_relTime(t.slaDueAt)}
                    </span>
                  </li>
                );
              })}
            </ul>
          </section>

          {/* Team workload */}
          <section className="card card-tight">
            <div className="card-head"><h2>Team workload</h2></div>
            <div style={{ padding: "8px 0 12px" }}>
              {workload.map(w => (
                <div key={w.agent.id} className="workload-row">
                  <div className="workload-name">
                    <Avatar name={w.agent.name} size={20} tone={w.agent.tone}/>
                    <span>{w.agent.name.split(" ")[0]}</span>
                  </div>
                  <div className="workload-bar">
                    <div style={{ width: ((w.count / maxLoad) * 100) + "%" }}/>
                  </div>
                  <span className="workload-count">{w.count}</span>
                </div>
              ))}
            </div>
          </section>

          {/* Activity */}
          <section className="card card-tight">
            <div className="card-head"><h2>Recent activity</h2></div>
            <ul className="feed">
              {ACTIVITY.slice(0, 8).map(a => {
                const p = personById(a.authorId);
                const t = a.ticketId ? tickets.find(x => x.id === a.ticketId) : null;
                let action = "did something";
                if (a.kind === "started") action = "started a session";
                else if (a.kind === "reply") action = "replied to";
                else if (a.kind === "internal") action = "left an internal note on";
                else if (a.kind === "refund") action = "issued a refund on";
                else if (a.kind === "created") action = "created";
                else if (a.kind === "resolved") action = "resolved";
                else if (a.kind === "assigned") action = "took";
                return (
                  <li key={a.id}>
                    <Avatar name={p.name} size={24} tone={p.tone || "neutral"}/>
                    <div>
                      <div className="feed-line">
                        <strong>{p.name}</strong>{" "}
                        <span className="feed-action">{action}</span>{" "}
                        {t && <a onClick={() => onOpen(t.id)} style={{ cursor: "pointer" }}>#{t.id}</a>}
                      </div>
                      <div className="feed-time">{a_relTime(a.at)} ago</div>
                    </div>
                  </li>
                );
              })}
            </ul>
          </section>
        </div>
      </div>
    </div>
  );
}

// ============= Overviews list =============
function OverviewsScreen({ tickets, onOpen, onNew, view, setView, layout }) {
  const [query, setQuery] = useS("");
  const [sort, setSort] = useS("updated");

  const views = [
    { key: "my_assigned",     label: "My assigned",     filter: t => t.assigneeId === ME_AGENT.id },
    { key: "unassigned_open", label: "Unassigned",      filter: t => !t.assigneeId && t.state === "open" },
    { key: "open",            label: "All open",        filter: t => t.state === "open" },
    { key: "pending",         label: "Pending",         filter: t => t.state === "pending" },
    { key: "escalated",       label: "Escalated",       filter: t => t.priority === "high" && t.state !== "resolved" && t.state !== "closed" },
    { key: "resolved",        label: "Resolved",        filter: t => t.state === "resolved" },
    { key: "closed",          label: "Closed",          filter: t => t.state === "closed" },
  ];
  const counts = Object.fromEntries(views.map(v => [v.key, tickets.filter(v.filter).length]));
  const current = views.find(v => v.key === view) || views[0];
  let list = tickets.filter(current.filter);
  if (query.trim()) {
    const q = query.toLowerCase();
    list = list.filter(t => t.title.toLowerCase().includes(q) || String(t.id).includes(q));
  }
  list = [...list].sort((a, b) =>
    sort === "updated" ? b.updatedAt - a.updatedAt : sort === "created" ? b.createdAt - a.createdAt : 0
  );

  const head = (
    <header className="screen-head">
      <div>
        <div className="kicker">Overviews</div>
        <h1 className="screen-title">{current.label} tickets</h1>
      </div>
      <div className="screen-actions">
        <div className="search">
          <Icon name="search" size={14}/>
          <input placeholder="Search ticket…" value={query} onChange={e => setQuery(e.target.value)}/>
        </div>
        <select value={sort} onChange={e => setSort(e.target.value)} style={{ padding: "6px 10px", fontSize: 13 }}>
          <option value="updated">Last update</option>
          <option value="created">Date created</option>
        </select>
        <button className="btn btn--primary" onClick={onNew}>
          <Icon name="plus" size={14}/> New ticket
        </button>
      </div>
    </header>
  );

  const tableEl = (
    <div className="table-wrap">
      <table className="ticket-table ticket-table--dense">
        <thead>
          <tr>
            <th style={{ width: 70 }}>#</th>
            <th>Title</th>
            <th style={{ width: 150 }}>Customer</th>
            <th style={{ width: 100 }}>Group</th>
            <th style={{ width: 120 }}>Assignee</th>
            <th style={{ width: 84 }}>Priority</th>
            <th style={{ width: 100 }}>State</th>
            <th style={{ width: 100 }}>Updated</th>
          </tr>
        </thead>
        <tbody>
          {list.map(t => {
            const c = custById(t.customerId);
            const a = agentById(t.assigneeId);
            return (
              <tr key={t.id} className={t.unread ? "row--unread" : ""} onClick={() => onOpen(t.id)}>
                <td className="mono muted">#{t.id}</td>
                <td>
                  <div className="cell-title">
                    <span className="cell-title-text">{t.title}</span>
                    {t.unread > 0 && <span className="badge">{t.unread} new</span>}
                  </div>
                </td>
                <td>
                  <div className="cell-person">
                    <Avatar name={c?.name} size={20} tone="neutral"/>
                    <span>{c?.name}</span>
                  </div>
                </td>
                <td className="muted">{t.group}</td>
                <td>
                  {a ? (
                    <div className="cell-person">
                      <Avatar name={a.name} size={20} tone={a.tone}/>
                      <span>{a.name.split(" ")[0]}</span>
                    </div>
                  ) : <span className="muted" style={{ fontSize: 12 }}>—</span>}
                </td>
                <td><PriorityPill priority={t.priority}/></td>
                <td><StatePill state={t.state}/></td>
                <td className="muted" style={{ whiteSpace: "nowrap" }}>{a_relTime(t.updatedAt)} ago</td>
              </tr>
            );
          })}
          {list.length === 0 && <tr><td colSpan={8} className="empty-row">No tickets here.</td></tr>}
        </tbody>
      </table>
    </div>
  );

  // Layout A: horizontal tabs (default) — cleaner, no sub-sidebar
  if (layout !== "sidebar") {
    return (
      <div className="screen">
        {head}
        <div className="overview-tabs">
          {views.map(v => (
            <button key={v.key}
                    className={"otab" + (view === v.key ? " otab--on" : "")}
                    onClick={() => setView(v.key)}>
              <span>{v.label}</span>
              <span className="otab-count">{counts[v.key]}</span>
            </button>
          ))}
        </div>
        {tableEl}
      </div>
    );
  }

  // Layout B: keep the side rail (original)
  return (
    <div className="split-layout">
      <aside className="split-side">
        <div className="split-side-group">Ticket overviews</div>
        {views.map(v => (
          <div key={v.key} className={"split-side-item" + (view === v.key ? " split-side-item--on" : "")}
               onClick={() => setView(v.key)}>
            <span style={{ flex: 1 }}>{v.label}</span>
            <span className="muted" style={{ fontSize: 12 }}>{counts[v.key]}</span>
          </div>
        ))}
      </aside>
      <div className="split-main">{head}{tableEl}</div>
    </div>
  );
}

Object.assign(window, { AgentDashboard, OverviewsScreen });
