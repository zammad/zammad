# Faithful Customer TicketList — matches docs/ui-references/customer-portal/.
# Dispatched from TicketOverviewRouter (in ticket_overview.coffee) when the
# current user is a customer viewing #ticket/view/my_tickets.
class App.CustomerTicketList extends App.ControllerAppContent
  @requiredPermission: 'ticket.customer'

  elements:
    '.js-search':    'searchInput'
    '.js-sort':      'sortSelect'
    '.js-tab':       'tabs'

  events:
    'input .js-search':    'onSearchInput'
    'change .js-sort':     'onSortChange'
    'click .js-tab':       'onTabClick'

  constructor: ->
    super
    @title __('My Tickets'), true
    @navupdate '#ticket/view/my_tickets'

    @query    = ''
    @sort     = 'updated'
    @stateTab = 'all'

    @collectionBindId = App.OverviewListCollection.bind('my_tickets', @onCollection)
    App.OverviewListCollection.fetch('my_tickets')

    @render()

  release: =>
    if @collectionBindId
      App.OverviewListCollection.unbindById(@collectionBindId)
    super

  onCollection: (data) =>
    @data = data
    @render()

  onSearchInput: (e) =>
    @query = e.target.value
    @rerenderRows()

  onSortChange: (e) =>
    @sort = e.target.value
    @rerenderRows()

  onTabClick: (e) =>
    e.preventDefault()
    @stateTab = $(e.currentTarget).data('tab')
    @render()

  decoratedTickets: ->
    raw = @data?.tickets or []
    rows = []
    for ref in raw
      ticket = App.Ticket.find(ref.id)
      continue if !ticket
      state    = App.TicketState.find(ticket.state_id)
      priority = App.TicketPriority.find(ticket.priority_id)
      group    = App.Group.find(ticket.group_id)
      stateType = if state then App.TicketStateType.find(state.state_type_id) else null
      bucket = @bucketFor(ticket, state, stateType)

      rows.push
        id:           ticket.id
        number:       ticket.number
        title:        ticket.title or '(no title)'
        category:     group?.name or ''
        priority:     priority?.name or 'normal'
        state:        state?.name or ''
        stateBucket:  bucket
        updatedAt:    ticket.updated_at
        createdAt:    ticket.created_at
        articleCount: ticket.article_count or 0
    rows

  bucketFor: (ticket, state, stateType) ->
    return 'closed' if state?.name in ['closed', 'merged']
    if stateType?.name in ['pending reminder', 'pending action']
      return 'pending'
    if stateType?.name is 'closed'
      return 'resolved'
    return 'open'

  applyFilter: (rows) ->
    filtered = rows
    if @stateTab and @stateTab isnt 'all'
      filtered = filtered.filter (r) => r.stateBucket is @stateTab
    if @query.trim()
      q = @query.toLowerCase()
      filtered = filtered.filter (r) ->
        (r.title or '').toLowerCase().indexOf(q) isnt -1 or
        String(r.number).indexOf(q) isnt -1 or
        (r.category or '').toLowerCase().indexOf(q) isnt -1
    filtered.slice().sort (a, b) =>
      switch @sort
        when 'created'  then (new Date(b.createdAt)) - (new Date(a.createdAt))
        when 'priority' then @priorityRank(a.priority) - @priorityRank(b.priority)
        else                 (new Date(b.updatedAt)) - (new Date(a.updatedAt))

  priorityRank: (name) ->
    return 0 if /high|3/i.test(name or '')
    return 2 if /low|1/i.test(name or '')
    1

  tabCounts: (rows) ->
    buckets = all: rows.length, open: 0, pending: 0, resolved: 0, closed: 0
    buckets[r.stateBucket] += 1 for r in rows when buckets[r.stateBucket]?
    buckets

  relTime: (iso) ->
    return '' if !iso
    diff = Date.now() - new Date(iso).getTime()
    minute = 60 * 1000
    hour = 60 * minute
    day = 24 * hour
    if diff < minute then __('just now')
    else if diff < hour then "#{Math.round(diff / minute)}m"
    else if diff < day then "#{Math.round(diff / hour)}h"
    else "#{Math.round(diff / day)}d"

  pillClass: (bucket) -> "cp-pill cp-pill--#{bucket}"
  priorityClass: (name) ->
    return 'cp-pri cp-pri--high'   if /high|3/i.test(name or '')
    return 'cp-pri cp-pri--low'    if /low|1/i.test(name or '')
    'cp-pri cp-pri--normal'

  render: =>
    rows = @decoratedTickets()
    @html App.view('customer_ticket_list')(
      rows:           @applyFilter(rows)
      counts:         @tabCounts(rows)
      query:          @query
      sort:           @sort
      activeTab:      @stateTab
      pillClass:      (b) => @pillClass(b)
      priorityClass:  (p) => @priorityClass(p)
      relTime:        (iso) => @relTime(iso)
    )

  rerenderRows: =>
    @render()

App.Config.set('CustomerTicketList', { controller: 'CustomerTicketList', permission: ['ticket.customer'] }, 'permanentTask')
