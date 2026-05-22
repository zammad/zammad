class App.CustomerDashboard extends App.Controller
  @requiredPermission: 'ticket.customer'

  constructor: ->
    super
    @title __('Dashboard'), true
    @navupdate '#dashboard'

    @collectionBindId = App.OverviewListCollection.bind('my_tickets', @onCollection)
    App.OverviewListCollection.fetch('my_tickets')

    # OnlineNotification fires the global controllerBind event
    # 'OnlineNotification::changed' when unread counts change.
    @controllerBind('OnlineNotification::changed', @render)

    @render()

  release: =>
    if @collectionBindId
      App.OverviewListCollection.unbindById(@collectionBindId)

  onCollection: (data) =>
    @data = data
    @render()

  computeCounts: (tickets) ->
    counts = open: 0, pending: 0, resolved: 0, closed: 0, awaiting: 0
    return counts if !tickets

    for t in tickets
      ticket = App.Ticket.find(t.id)
      state  = App.TicketState.find(ticket.state_id)
      next   = App.TicketStateType.find(state.state_type_id)
      category = next?.name or state.name

      switch category
        when 'new', 'open'
          counts.open += 1
        when 'pending reminder', 'pending action'
          counts.pending += 1
        when 'closed'
          # 'closed' state type covers Zammad's 'closed', 'merged' etc.
          if state.name is 'closed' or state.name is 'merged'
            counts.closed += 1
          else
            counts.resolved += 1

      if ticket.last_contact_agent_at and ticket.last_contact_customer_at
        if new Date(ticket.last_contact_agent_at) > new Date(ticket.last_contact_customer_at)
          counts.awaiting += 1
      else if ticket.last_contact_agent_at
        counts.awaiting += 1

    counts

  topRecent: (tickets, limit = 5) ->
    return [] if !tickets
    sorted = tickets.slice().sort (a, b) ->
      ta = new Date(App.Ticket.find(a.id)?.updated_at or 0)
      tb = new Date(App.Ticket.find(b.id)?.updated_at or 0)
      tb - ta
    sorted.slice(0, limit)

  awaitingTickets: (tickets, limit = 5) ->
    return [] if !tickets
    filtered = tickets.filter (t) ->
      ticket = App.Ticket.find(t.id)
      return false if !ticket
      agent_at    = if ticket.last_contact_agent_at then new Date(ticket.last_contact_agent_at) else null
      customer_at = if ticket.last_contact_customer_at then new Date(ticket.last_contact_customer_at) else null
      if agent_at and customer_at
        return agent_at > customer_at
      return !!agent_at
    filtered.slice(0, limit)

  unreadCount: ->
    App.OnlineNotification.all().filter((n) -> !n.seen).length

  relTime: (iso) ->
    return '' if !iso
    diff = Date.now() - new Date(iso).getTime()
    minute = 60 * 1000
    hour = 60 * minute
    day = 24 * hour
    if diff < minute then 'just now'
    else if diff < hour then "#{Math.round(diff / minute)}m ago"
    else if diff < day then "#{Math.round(diff / hour)}h ago"
    else "#{Math.round(diff / day)}d ago"

  initialsFor: (name) ->
    return '?' if !name
    parts = (name + '').trim().split(/\s+/).slice(0, 2)
    (parts.map (p) -> (p[0] or '').toUpperCase()).join('') or '?'

  # Best-guess "who last spoke" on a ticket using the fields that come back
  # with the overview list. Without per-ticket articles we can't show the
  # actual agent name, so we use the contact-at timestamps to infer whether
  # the agent or the customer was last.
  lastAuthor: (ticketId) =>
    ticket = App.Ticket.find(ticketId)
    return { name: __('You'), initials: 'YOU', isAgent: false } if !ticket

    agentAt    = if ticket.last_contact_agent_at then new Date(ticket.last_contact_agent_at) else null
    customerAt = if ticket.last_contact_customer_at then new Date(ticket.last_contact_customer_at) else null
    isAgent = agentAt and (!customerAt or agentAt > customerAt)

    if isAgent
      ownerUser = if ticket.owner_id and ticket.owner_id isnt 1 then App.User.find(ticket.owner_id) else null
      name = ownerUser?.fullname or __('Support')
      { name: name, initials: @initialsFor(name), isAgent: true }
    else
      me = App.User.current()
      name = me?.fullname or me?.login or __('You')
      { name: __('You'), initials: @initialsFor(name), isAgent: false }

  render: =>
    tickets = @data?.tickets or []
    counts = @computeCounts(tickets)
    counts.unread = @unreadCount()
    recent = @topRecent(tickets)
    awaiting = @awaitingTickets(tickets)

    user = App.User.current()
    greeting = @greetingFor(new Date(), user)

    @html App.view('customer_dashboard')(
      greeting:    greeting
      counts:      counts
      recent:      recent
      awaiting:    awaiting
      ticketState: (id) -> App.TicketState.find(App.Ticket.find(id)?.state_id)?.name or ''
      ticketTitle: (id) -> App.Ticket.find(id)?.title or '(no title)'
      ticketUpdatedAt: (id) -> App.Ticket.find(id)?.updated_at
      relTime:     (iso) => @relTime(iso)
      lastAuthor:  (id) => @lastAuthor(id)
    )

  greetingFor: (now, user) ->
    hour = now.getHours()
    salute =
      if hour < 12 then __('Good morning')
      else if hour < 18 then __('Good afternoon')
      else __('Good evening')
    name = user?.firstname or user?.login or ''
    if name then "#{salute}, #{name}" else salute

# Route is shared with the agent dashboard; DashboardRouter in
# dashboard.coffee dispatches to CustomerDashboard or Dashboard based on
# user permissions.
App.Config.set('CustomerDashboard', { controller: 'CustomerDashboard', permission: ['ticket.customer'] }, 'permanentTask')

# NavBar entry for customers only — agents already see the 'Dashboard'
# entry registered in dashboard.coffee with permission ['ticket.agent'].
App.Config.set('CustomerDashboardNav', { prio: 900, parent: '', name: __('Dashboard'), target: '#dashboard', key: 'CustomerDashboardNav', permission: (navigation) ->
  return false if navigation.permissionCheck('ticket.agent')
  return navigation.permissionCheck('ticket.customer')
, class: 'dashboard', hideIcon: false }, 'NavBar')
