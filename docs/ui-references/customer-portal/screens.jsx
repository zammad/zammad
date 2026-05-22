// Screen components: Dashboard, TicketList, TicketDetail, NewTicket

const { useState, useMemo, useEffect, useRef } = React;

// -------- Dashboard --------
function Dashboard({ tickets, onOpen, onNew, onNav }) {
  const counts = useMemo(() => {
    const c = { open: 0, pending: 0, resolved: 0, closed: 0, unread: 0 };
    tickets.forEach(t => { c[t.state] = (c[t.state] || 0) + 1; if (t.unread) c.unread += t.unread; });
    return c;
  }, [tickets]);

  const recent = useMemo(
    () => [...tickets].sort((a, b) => b.updatedAt - a.updatedAt).slice(0, 6),
    [tickets]
  );
  const awaitingMe = tickets.filter(t => t.state === "open" && t.messages.at(-1)?.from === "agent");

  return (
    <div className="screen">
      <header className="screen-head">
        <div>
          <div className="kicker">Support portal</div>
          <h1 className="screen-title">Good afternoon, Wayne</h1>
        </div>
        <div className="screen-actions">
          <button className="btn btn--ghost" onClick={() => onNav("tickets")}>
            View all tickets
          </button>
          <button className="btn btn--primary" onClick={onNew}>
            <Icon name="plus" size={14}/> New ticket
          </button>
        </div>
      </header>

      <section className="stat-row">
        <button className="stat" onClick={() => onNav("tickets", { state: "open" })}>
          <div className="stat-val">{counts.open || 0}</div>
          <div className="stat-lbl"><span className="dot" style={{ background: "var(--st-open)" }}/> Open</div>
        </button>
        <button className="stat" onClick={() => onNav("tickets", { state: "pending" })}>
          <div className="stat-val">{counts.pending || 0}</div>
          <div className="stat-lbl"><span className="dot" style={{ background: "var(--st-pend)" }}/> Awaiting you</div>
        </button>
        <button className="stat" onClick={() => onNav("tickets", { state: "resolved" })}>
          <div className="stat-val">{counts.resolved || 0}</div>
          <div className="stat-lbl"><span className="dot" style={{ background: "var(--st-res)" }}/> Resolved</div>
        </button>
        <button className="stat" onClick={() => onNav("tickets", { state: "closed" })}>
          <div className="stat-val">{counts.closed || 0}</div>
          <div className="stat-lbl"><span className="dot" style={{ background: "var(--st-closed)" }}/> Closed</div>
        </button>
        <div className="stat stat--accent">
          <div className="stat-val">{counts.unread || 0}</div>
          <div className="stat-lbl">Unread replies</div>
        </div>
      </section>

      <div className="dash-grid">
        <section className="card">
          <div className="card-head">
            <h2>Needs your reply</h2>
            <span className="muted">{awaitingMe.length} ticket{awaitingMe.length === 1 ? "" : "s"}</span>
          </div>
          {awaitingMe.length === 0 ? (
            <div className="empty"><Icon name="check" size={18}/> You're all caught up.</div>
          ) : (
            <ul className="awaiting">
              {awaitingMe.map(t => (
                <li key={t.id} onClick={() => onOpen(t.id)}>
                  <div className="awaiting-meta">
                    <span className="tid">#{t.id}</span>
                    <StatePill state={t.state}/>
                    <span className="muted">{relTime(t.updatedAt)}</span>
                  </div>
                  <div className="awaiting-title">{t.title}</div>
                  <div className="awaiting-snippet">
                    <Avatar name={t.messages.at(-1).author} size={20}/>
                    <span className="awaiting-snippet-text">{t.messages.at(-1).body}</span>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </section>

        <section className="card">
          <div className="card-head">
            <h2>Recent activity</h2>
            <button className="link" onClick={() => onNav("tickets")}>See all →</button>
          </div>
          <ul className="activity">
            {recent.map(t => {
              const m = t.messages.at(-1);
              return (
                <li key={t.id} onClick={() => onOpen(t.id)}>
                  <Avatar name={m.author} size={26} tone={m.from === "me" ? "accent" : "neutral"}/>
                  <div className="activity-body">
                    <div className="activity-line">
                      <strong>{m.from === "me" ? "You" : m.author}</strong>
                      <span className="muted"> on </span>
                      <span className="tid">#{t.id}</span>
                      <span className="muted"> · {relTime(m.at)}</span>
                    </div>
                    <div className="activity-snippet">{m.body}</div>
                  </div>
                  <StatePill state={t.state}/>
                </li>
              );
            })}
          </ul>
        </section>
      </div>
    </div>
  );
}

// -------- Ticket List --------
function TicketList({ tickets, onOpen, onNew, filter, setFilter }) {
  const [query, setQuery] = useState("");
  const [sort, setSort] = useState("updated");

  const filtered = useMemo(() => {
    let list = tickets;
    if (filter.state && filter.state !== "all") list = list.filter(t => t.state === filter.state);
    if (filter.category) list = list.filter(t => t.category === filter.category);
    if (query.trim()) {
      const q = query.toLowerCase();
      list = list.filter(t =>
        t.title.toLowerCase().includes(q) ||
        String(t.id).includes(q) ||
        t.category.toLowerCase().includes(q)
      );
    }
    list = [...list].sort((a, b) => {
      if (sort === "updated") return b.updatedAt - a.updatedAt;
      if (sort === "created") return b.createdAt - a.createdAt;
      if (sort === "priority") {
        const p = { high: 0, normal: 1, low: 2 };
        return p[a.priority] - p[b.priority];
      }
      return 0;
    });
    return list;
  }, [tickets, filter, query, sort]);

  const tabs = [
    { key: "all", label: "All" },
    { key: "open", label: "Open" },
    { key: "pending", label: "Awaiting you" },
    { key: "resolved", label: "Resolved" },
    { key: "closed", label: "Closed" },
  ];

  return (
    <div className="screen">
      <header className="screen-head">
        <div>
          <div className="kicker">Support portal</div>
          <h1 className="screen-title">My tickets</h1>
        </div>
        <div className="screen-actions">
          <div className="search">
            <Icon name="search" size={14}/>
            <input
              type="text" placeholder="Search title, #id, category…"
              value={query} onChange={e => setQuery(e.target.value)}
            />
          </div>
          <button className="btn btn--primary" onClick={onNew}>
            <Icon name="plus" size={14}/> New ticket
          </button>
        </div>
      </header>

      <div className="tabs">
        {tabs.map(t => (
          <button key={t.key}
                  className={"tab" + (filter.state === t.key ? " tab--active" : "")}
                  onClick={() => setFilter({ ...filter, state: t.key })}>
            {t.label}
            <span className="tab-count">
              {t.key === "all" ? tickets.length : tickets.filter(x => x.state === t.key).length}
            </span>
          </button>
        ))}
        <div className="tabs-spacer"/>
        <label className="sort">
          <span>Sort</span>
          <select value={sort} onChange={e => setSort(e.target.value)}>
            <option value="updated">Last update</option>
            <option value="created">Date created</option>
            <option value="priority">Priority</option>
          </select>
        </label>
      </div>

      <div className="table-wrap">
        <table className="ticket-table">
          <thead>
            <tr>
              <th style={{ width: 78 }}>#</th>
              <th>Subject</th>
              <th style={{ width: 140 }}>Category</th>
              <th style={{ width: 100 }}>Priority</th>
              <th style={{ width: 130 }}>Status</th>
              <th style={{ width: 140 }}>Last update</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(t => (
              <tr key={t.id} className={t.unread ? "row--unread" : ""} onClick={() => onOpen(t.id)}>
                <td className="mono muted">#{t.id}</td>
                <td>
                  <div className="ticket-subject">
                    <span>{t.title}</span>
                    {t.unread > 0 && <span className="badge">{t.unread} new</span>}
                  </div>
                  <div className="ticket-sub">
                    {t.messages.length} message{t.messages.length === 1 ? "" : "s"} · created {relTime(t.createdAt)}
                  </div>
                </td>
                <td className="muted">{t.category}</td>
                <td><PriorityPill priority={t.priority}/></td>
                <td><StatePill state={t.state}/></td>
                <td className="muted">{relTime(t.updatedAt)}</td>
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr><td colSpan={6} className="empty-row">No tickets match these filters.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// -------- Ticket Detail --------
function TicketDetail({ ticket, onBack, onReply, onUpdateState }) {
  const [draft, setDraft] = useState("");
  const [attachments, setAttachments] = useState([]);
  const [sending, setSending] = useState(false);
  const fileRef = useRef(null);
  const threadRef = useRef(null);

  useEffect(() => {
    if (threadRef.current) threadRef.current.scrollTop = threadRef.current.scrollHeight;
  }, [ticket?.messages.length]);

  if (!ticket) return null;

  const handleFiles = (files) => {
    const next = Array.from(files).map(f => ({
      name: f.name,
      size: (f.size / 1024).toFixed(0) + " KB",
      kind: f.type.startsWith("image/") ? "image" : "file",
      url: f.type.startsWith("image/") ? URL.createObjectURL(f) : null,
    }));
    setAttachments(a => [...a, ...next]);
  };

  const send = () => {
    if (!draft.trim() && attachments.length === 0) return;
    setSending(true);
    setTimeout(() => {
      onReply(ticket.id, { body: draft.trim(), attachments });
      setDraft(""); setAttachments([]); setSending(false);
    }, 350);
  };

  const isClosed = ticket.state === "closed";

  return (
    <div className="screen screen--detail">
      <header className="screen-head detail-head">
        <button className="btn btn--ghost btn--icon" onClick={onBack} title="Back">
          <Icon name="chevronLeft" size={16}/>
        </button>
        <div className="detail-head-main">
          <div className="kicker">
            <span className="tid mono">#{ticket.id}</span>
            <span> · {ticket.category} · created {absTime(ticket.createdAt)}</span>
          </div>
          <h1 className="screen-title">{ticket.title}</h1>
        </div>
        <div className="screen-actions">
          <StatePill state={ticket.state}/>
          <PriorityPill priority={ticket.priority}/>
          {!isClosed && ticket.state !== "resolved" && (
            <button className="btn btn--ghost" onClick={() => onUpdateState(ticket.id, "resolved")}>
              <Icon name="check" size={14}/> Mark resolved
            </button>
          )}
          {ticket.state === "resolved" && (
            <button className="btn btn--ghost" onClick={() => onUpdateState(ticket.id, "open")}>
              Reopen
            </button>
          )}
        </div>
      </header>

      <div className="detail-body">
        <div className="thread" ref={threadRef}>
          {ticket.messages.map((m, i) => (
            <div key={i} className={"msg msg--" + (m.from === "me" ? "me" : "agent")}>
              <Avatar name={m.author} size={32} tone={m.from === "me" ? "accent" : "neutral"}/>
              <div className="msg-body">
                <div className="msg-meta">
                  <strong>{m.author}</strong>
                  <span className="muted"> · {absTime(m.at)}</span>
                  {m.from === "agent" && <span className="tag tag--agent">Support</span>}
                </div>
                <div className="msg-text">{m.body}</div>
                {m.attachments && m.attachments.length > 0 && (
                  <div className="msg-attach">
                    {m.attachments.map((a, j) => (
                      <div key={j} className="attach-chip">
                        <Icon name={a.kind === "image" ? "image" : "paperclip"} size={14}/>
                        <span>{a.name}</span>
                        <span className="muted">{a.size}</span>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>

        {isClosed ? (
          <div className="reply-closed">
            This ticket is closed.{" "}
            <button className="link" onClick={() => onUpdateState(ticket.id, "open")}>Reopen ticket</button>
            {" "}to continue the conversation.
          </div>
        ) : (
          <div className="reply"
               onDragOver={e => { e.preventDefault(); e.currentTarget.classList.add("reply--drag"); }}
               onDragLeave={e => e.currentTarget.classList.remove("reply--drag")}
               onDrop={e => { e.preventDefault(); e.currentTarget.classList.remove("reply--drag"); handleFiles(e.dataTransfer.files); }}>
            <textarea
              placeholder="Type your reply… (drag images here or use the paperclip)"
              value={draft}
              onChange={e => setDraft(e.target.value)}
              rows={3}
            />
            {attachments.length > 0 && (
              <div className="reply-attach">
                {attachments.map((a, i) => (
                  <div key={i} className="attach-chip">
                    {a.kind === "image" && a.url
                      ? <img src={a.url} alt=""/>
                      : <Icon name="paperclip" size={14}/>}
                    <span>{a.name}</span>
                    <span className="muted">{a.size}</span>
                    <button className="attach-x" onClick={() => setAttachments(arr => arr.filter((_, j) => j !== i))} title="Remove">
                      <Icon name="x" size={12}/>
                    </button>
                  </div>
                ))}
              </div>
            )}
            <div className="reply-bar">
              <div className="reply-bar-left">
                <button className="btn btn--ghost btn--icon" onClick={() => fileRef.current?.click()} title="Attach">
                  <Icon name="paperclip" size={15}/>
                </button>
                <input ref={fileRef} type="file" multiple hidden onChange={e => handleFiles(e.target.files)}/>
                <span className="hint muted">Drag images here, or click the paperclip</span>
              </div>
              <div className="reply-bar-right">
                <button className="btn btn--ghost" onClick={() => { setDraft(""); setAttachments([]); }}>
                  Discard
                </button>
                <button className="btn btn--primary" disabled={sending || (!draft.trim() && attachments.length === 0)} onClick={send}>
                  {sending ? <Spinner size={14}/> : <Icon name="send" size={14}/>}
                  {sending ? " Sending…" : " Send reply"}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// -------- New Ticket --------
function NewTicket({ onCancel, onCreate }) {
  const [title, setTitle] = useState("");
  const [category, setCategory] = useState(CATEGORIES[0]);
  const [priority, setPriority] = useState("normal");
  const [body, setBody] = useState("");
  const [attachments, setAttachments] = useState([]);
  const [submitting, setSubmitting] = useState(false);
  const [errors, setErrors] = useState({});
  const fileRef = useRef(null);

  const handleFiles = (files) => {
    const next = Array.from(files).map(f => ({
      name: f.name,
      size: (f.size / 1024).toFixed(0) + " KB",
      kind: f.type.startsWith("image/") ? "image" : "file",
      url: f.type.startsWith("image/") ? URL.createObjectURL(f) : null,
    }));
    setAttachments(a => [...a, ...next]);
  };

  const submit = () => {
    const e = {};
    if (!title.trim()) e.title = "Give your ticket a short title.";
    if (!body.trim()) e.body = "Describe what's happening so we can help.";
    setErrors(e);
    if (Object.keys(e).length) return;
    setSubmitting(true);
    setTimeout(() => onCreate({ title, category, priority, body, attachments }), 450);
  };

  return (
    <div className="screen">
      <header className="screen-head">
        <div className="head-left">
          <button className="btn btn--ghost btn--icon" onClick={onCancel} title="Back">
            <Icon name="chevronLeft" size={16}/>
          </button>
          <div>
            <div className="kicker">Support portal</div>
            <h1 className="screen-title">Submit a new ticket</h1>
          </div>
        </div>
      </header>

      <div className="form-wrap">
        <div className="form-grid">
          <label className="field field--full">
            <span className="field-lbl">Subject</span>
            <input
              type="text" value={title}
              placeholder="Short summary, e.g. 'Order #A-7821 went to wrong address'"
              onChange={e => setTitle(e.target.value)}
              className={errors.title ? "input--err" : ""}
            />
            {errors.title && <span className="field-err">{errors.title}</span>}
          </label>

          <label className="field">
            <span className="field-lbl">Category</span>
            <select value={category} onChange={e => setCategory(e.target.value)}>
              {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
            </select>
          </label>

          <div className="field">
            <span className="field-lbl">Priority</span>
            <div className="seg">
              {["low", "normal", "high"].map(p => (
                <button key={p} type="button"
                        className={"seg-btn" + (priority === p ? " seg-btn--on" : "")}
                        onClick={() => setPriority(p)}>
                  {p[0].toUpperCase() + p.slice(1)}
                </button>
              ))}
            </div>
          </div>

          <label className="field field--full">
            <span className="field-lbl">Description</span>
            <textarea
              rows={7} value={body}
              placeholder="What were you trying to do? What happened instead? Include any steps to reproduce."
              onChange={e => setBody(e.target.value)}
              className={errors.body ? "input--err" : ""}
            />
            {errors.body && <span className="field-err">{errors.body}</span>}
          </label>

          <div className="field field--full">
            <span className="field-lbl">Attachments <span className="muted">(optional)</span></span>
            <div className="drop"
                 onClick={() => fileRef.current?.click()}
                 onDragOver={e => { e.preventDefault(); e.currentTarget.classList.add("drop--over"); }}
                 onDragLeave={e => e.currentTarget.classList.remove("drop--over")}
                 onDrop={e => { e.preventDefault(); e.currentTarget.classList.remove("drop--over"); handleFiles(e.dataTransfer.files); }}>
              <Icon name="image" size={18}/>
              <div>
                <strong>Drag images or files here,</strong> or <span className="link">browse</span>
                <div className="muted">PNG, JPG, PDF up to 10MB each</div>
              </div>
              <input ref={fileRef} type="file" multiple hidden onChange={e => handleFiles(e.target.files)}/>
            </div>
            {attachments.length > 0 && (
              <div className="attach-grid">
                {attachments.map((a, i) => (
                  <div key={i} className="attach-tile">
                    {a.kind === "image" && a.url
                      ? <img src={a.url} alt=""/>
                      : <div className="attach-tile-icon"><Icon name="paperclip" size={20}/></div>}
                    <div className="attach-tile-meta">
                      <div className="attach-tile-name">{a.name}</div>
                      <div className="muted">{a.size}</div>
                    </div>
                    <button className="attach-x" onClick={() => setAttachments(arr => arr.filter((_, j) => j !== i))} title="Remove">
                      <Icon name="x" size={12}/>
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        <div className="form-bar">
          <span className="muted">You'll get an email when support replies.</span>
          <div className="form-bar-right">
            <button className="btn btn--ghost" onClick={onCancel}>Cancel</button>
            <button className="btn btn--primary" onClick={submit} disabled={submitting}>
              {submitting ? <Spinner size={14}/> : <Icon name="send" size={14}/>}
              {submitting ? " Submitting…" : " Submit ticket"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { Dashboard, TicketList, TicketDetail, NewTicket });
