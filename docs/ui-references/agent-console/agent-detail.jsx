// Agent Ticket Detail — 3 column (queue / conversation / properties)

const { useState: useSD, useEffect: useED, useMemo: useMD, useRef: useRD } = React;

function AgentTicketDetail({ tickets, ticketId, onOpen, onUpdate, onReply, onBack }) {
  const ticket = tickets.find(t => t.id === ticketId);
  const customer = ticket && custById(ticket.customerId);
  const org = customer && orgById(customer.orgId);
  const assignee = ticket && agentById(ticket.assigneeId);

  const [mode, setMode] = useSD("reply"); // 'reply' | 'internal'
  const [draft, setDraft] = useSD("");
  const [attachments, setAttachments] = useSD([]);
  const [macrosOpen, setMacrosOpen] = useSD(false);
  const [sending, setSending] = useSD(false);
  const fileRef = useRD(null);
  const threadRef = useRD(null);
  const macroRef = useRD(null);

  // Queue (sorted by updatedAt)
  const queue = useMD(() => {
    return [...tickets]
      .filter(t => t.state !== "closed")
      .sort((a, b) => b.updatedAt - a.updatedAt);
  }, [tickets]);

  useED(() => {
    if (threadRef.current) threadRef.current.scrollTop = threadRef.current.scrollHeight;
  }, [ticket?.messages.length]);

  useED(() => {
    const onClick = (e) => {
      if (macroRef.current && !macroRef.current.contains(e.target)) setMacrosOpen(false);
    };
    document.addEventListener("mousedown", onClick);
    return () => document.removeEventListener("mousedown", onClick);
  }, []);

  if (!ticket) {
    return (
      <div className="screen" style={{ padding: 40 }}>
        <p className="muted">Ticket not found.</p>
        <button className="btn btn--ghost" onClick={onBack}>← Back</button>
      </div>
    );
  }

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
      onReply(ticket.id, {
        from: mode === "internal" ? "internal" : "agent",
        authorId: ME_AGENT.id,
        body: draft.trim(), attachments,
      });
      setDraft(""); setAttachments([]); setSending(false);
    }, 300);
  };

  const applyMacro = (m) => {
    setDraft(d => (d ? d + "\n\n" : "") + m.body);
    setMacrosOpen(false);
  };

  const recentTickets = tickets.filter(t => t.customerId === ticket.customerId && t.id !== ticket.id).slice(0, 4);

  return (
    <div className="detail3">
      {/* ---- Queue pane ---- */}
      <div className="detail3-col">
        <div className="queue-pane-head">
          <button className="btn btn--ghost btn--icon" onClick={onBack} title="Back to overviews">
            <Icon name="chevronLeft" size={14}/>
          </button>
          <h3>My queue</h3>
          <span className="muted" style={{ fontSize: 12 }}>{queue.length}</span>
        </div>
        <div className="queue-search">
          <Icon name="search" size={12}/>
          <input placeholder="Filter…"/>
        </div>
        <div className="queue-list-pane">
          {queue.map(t => {
            const c = custById(t.customerId);
            const active = t.id === ticket.id;
            return (
              <div key={t.id}
                   className={"queue-item" + (active ? " queue-item--active" : "") + (t.unread ? " queue-item--unread" : "")}
                   onClick={() => onOpen(t.id)}>
                <div className="queue-item-row">
                  <Avatar name={c?.name} size={18} tone="neutral"/>
                  <span style={{ fontSize: 12, color: "var(--ink-2)", fontWeight: 500 }}>{c?.name}</span>
                  <span className="muted" style={{ marginLeft: "auto", fontSize: 11 }}>{a_relTime(t.updatedAt)}</span>
                </div>
                <div className="queue-item-title">{t.title}</div>
                <div className="queue-item-bottom">
                  <StatePill state={t.state}/>
                  {t.priority === "high" && <PriorityPill priority="high"/>}
                  <span className="muted" style={{ marginLeft: "auto", fontFamily: "ui-monospace, Menlo, monospace" }}>
                    #{t.id}
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* ---- Conversation pane ---- */}
      <div className="detail3-col conv-pane">
        <div className="conv-head">
          <div className="conv-head-row">
            <span className="conv-id">#{ticket.id}</span>
            <h2 className="conv-title">{ticket.title}</h2>
          </div>
          <div className="conv-head-row">
            <StatePill state={ticket.state}/>
            <PriorityPill priority={ticket.priority}/>
            <span className="conv-meta">
              <span>{ticket.group}</span>
              <span>·</span>
              <span>Created {a_absTime(ticket.createdAt)}</span>
              {ticket.tags.length > 0 && (
                <>
                  <span>·</span>
                  <div className="tag-list">
                    {ticket.tags.map(tg => <span key={tg} className="tag-chip">#{tg}</span>)}
                  </div>
                </>
              )}
            </span>
            <div style={{ marginLeft: "auto", display: "flex", gap: 6 }}>
              {ticket.state !== "resolved" && ticket.state !== "closed" && (
                <button className="btn btn--ghost" onClick={() => onUpdate(ticket.id, { state: "resolved" })}>
                  <Icon name="check" size={13}/> Resolve
                </button>
              )}
              {ticket.state === "resolved" && (
                <button className="btn btn--ghost" onClick={() => onUpdate(ticket.id, { state: "open" })}>
                  Reopen
                </button>
              )}
            </div>
          </div>
        </div>

        <div className="conv-thread" ref={threadRef}>
          {ticket.messages.map((m, i) => {
            const p = personById(m.authorId);
            const isCustomer = m.from === "customer";
            const isInternal = m.from === "internal";
            const rowClass = "msg-row " + (isInternal ? "msg-row--internal" : isCustomer ? "msg-row--customer" : "msg-row--agent");
            return (
              <div key={i} className={rowClass}>
                <Avatar name={p.name} size={28} tone={isCustomer ? "neutral" : (p.tone || "accent")}/>
                <div className="msg-card">
                  <div className="msg-head">
                    <strong>{p.name}</strong>
                    {!isCustomer && !isInternal && <span className="msg-tag msg-tag--agent">Agent</span>}
                    {isInternal && <span className="msg-tag msg-tag--internal">Internal note</span>}
                    <span className="msg-head-time">{a_absTime(m.at)}</span>
                  </div>
                  <div className="msg-text">{m.body}</div>
                  {m.attachments && m.attachments.length > 0 && (
                    <div className="msg-attach">
                      {m.attachments.map((a, j) => (
                        <div key={j} className="attach-chip">
                          <Icon name={a.kind === "image" ? "image" : "paperclip"} size={13}/>
                          <span>{a.name}</span>
                          <span className="muted">{a.size}</span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
                <div style={{ width: 0 }}/>
              </div>
            );
          })}
        </div>

        {/* Composer */}
        <div className={"composer" + (mode === "internal" ? " composer--internal" : "")}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 8 }}>
            <div className="composer-tabs">
              <button className={"composer-tab" + (mode === "reply" ? " composer-tab--on--reply" : "")}
                      onClick={() => setMode("reply")}>
                <Icon name="send" size={11}/> Public reply
              </button>
              <button className={"composer-tab" + (mode === "internal" ? " composer-tab--on--internal" : "")}
                      onClick={() => setMode("internal")}>
                <Icon name="flag" size={11}/> Internal note
              </button>
            </div>
            <div className="macro-wrap" ref={macroRef}>
              <button className="btn btn--ghost" style={{ fontSize: 12, padding: "5px 10px" }}
                      onClick={() => setMacrosOpen(o => !o)}>
                Macros <Icon name="chevronDown" size={11}/>
              </button>
              {macrosOpen && (
                <div className="macro-pop">
                  {MACROS.map(m => (
                    <button key={m.id} className="macro-item" onClick={() => applyMacro(m)}>
                      <div className="macro-title">{m.title}</div>
                      <div className="macro-body">{m.body}</div>
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>
          <textarea
            className="composer-text"
            rows={3}
            placeholder={mode === "internal"
              ? "Internal note — only visible to your team."
              : "Reply to " + (customer?.name || "customer") + "…"}
            value={draft}
            onChange={e => setDraft(e.target.value)}
          />
          {attachments.length > 0 && (
            <div className="reply-attach" style={{ marginTop: 0 }}>
              {attachments.map((a, i) => (
                <div key={i} className="attach-chip">
                  {a.kind === "image" && a.url ? <img src={a.url} alt=""/> : <Icon name="paperclip" size={13}/>}
                  <span>{a.name}</span>
                  <span className="muted">{a.size}</span>
                  <button className="attach-x" onClick={() => setAttachments(arr => arr.filter((_, j) => j !== i))}>
                    <Icon name="x" size={11}/>
                  </button>
                </div>
              ))}
            </div>
          )}
          <div className="composer-bar">
            <div className="composer-bar-left">
              <button className="btn btn--ghost btn--icon" onClick={() => fileRef.current?.click()} title="Attach">
                <Icon name="paperclip" size={14}/>
              </button>
              <input ref={fileRef} hidden type="file" multiple onChange={e => handleFiles(e.target.files)}/>
              <span className="muted" style={{ fontSize: 12 }}>
                Press ⌘↵ to send · drag images to attach
              </span>
            </div>
            <div className="composer-bar-right">
              <select value={ticket.state} onChange={e => onUpdate(ticket.id, { state: e.target.value })}
                      style={{ padding: "5px 8px", fontSize: 12 }}>
                <option value="open">Set: Open</option>
                <option value="pending">Set: Pending</option>
                <option value="resolved">Set: Resolved</option>
                <option value="closed">Set: Closed</option>
              </select>
              <button className="btn btn--primary" disabled={sending || (!draft.trim() && attachments.length === 0)}
                      onClick={send}>
                {sending ? <Spinner size={13}/> : <Icon name="send" size={13}/>}
                {sending ? " Sending…" : (mode === "internal" ? " Post note" : " Send reply")}
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* ---- Properties pane ---- */}
      <div className="detail3-col props-pane">
        <div className="props-section">
          <h4>Customer</h4>
          <div className="cust-head">
            <Avatar name={customer?.name} size={36} tone="neutral"/>
            <div>
              <div className="cust-name">{customer?.name}</div>
              <div className="cust-email">{customer?.email}</div>
            </div>
          </div>
          <dl className="cust-meta">
            <dt>Org</dt>
            <dd>{org ? org.name : <span className="muted">—</span>}</dd>
            {org && (<>
              <dt>Plan</dt>
              <dd>{org.plan}</dd>
              <dt>Members</dt>
              <dd>{org.members}</dd>
            </>)}
          </dl>
        </div>

        <div className="props-section">
          <h4>Properties</h4>
          <div className="prop-row">
            <span className="lbl">State</span>
            <select value={ticket.state} onChange={e => onUpdate(ticket.id, { state: e.target.value })}>
              <option value="open">Open</option>
              <option value="pending">Pending</option>
              <option value="resolved">Resolved</option>
              <option value="closed">Closed</option>
            </select>
          </div>
          <div className="prop-row">
            <span className="lbl">Priority</span>
            <select value={ticket.priority} onChange={e => onUpdate(ticket.id, { priority: e.target.value })}>
              <option value="low">Low</option>
              <option value="normal">Normal</option>
              <option value="high">High</option>
            </select>
          </div>
          <div className="prop-row">
            <span className="lbl">Group</span>
            <select value={ticket.group} onChange={e => onUpdate(ticket.id, { group: e.target.value })}>
              {GROUPS.map(g => <option key={g} value={g}>{g}</option>)}
            </select>
          </div>
          <div className="prop-row">
            <span className="lbl">Assignee</span>
            <select value={ticket.assigneeId || ""} onChange={e => onUpdate(ticket.id, { assigneeId: e.target.value || null })}>
              <option value="">Unassigned</option>
              {AGENTS.map(a => <option key={a.id} value={a.id}>{a.name}</option>)}
            </select>
          </div>
          {ticket.slaDueAt && (
            <div className="prop-row">
              <span className="lbl">SLA</span>
              <span className="prop-value" style={{ background: "var(--surface)" }}>
                <Icon name="clock" size={12}/> due in {a_relTime(ticket.slaDueAt)}
              </span>
            </div>
          )}
        </div>

        <div className="props-section">
          <h4>Tags</h4>
          <div className="tag-list">
            {ticket.tags.map(t => (
              <span key={t} className="tag-chip">#{t} <Icon name="x" size={10}/></span>
            ))}
            <button className="tag-chip" style={{ cursor: "pointer", color: "var(--ink-3)" }}>+ add</button>
          </div>
        </div>

        {recentTickets.length > 0 && (
          <div className="props-section">
            <h4>Other tickets from {customer?.name.split(" ")[0]}</h4>
            {recentTickets.map(t => (
              <div key={t.id} className="recent-ticket" onClick={() => onOpen(t.id)}>
                <StatePill state={t.state}/>
                <span className="recent-ticket-title">{t.title}</span>
                <span className="muted tid">#{t.id}</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

Object.assign(window, { AgentTicketDetail });
