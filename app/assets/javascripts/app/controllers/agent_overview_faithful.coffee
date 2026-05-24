# Faithful agent overviews — matches docs/ui-references/agent-console/
# (OverviewsScreen in agent-screens.jsx).
#
# Renders a top page header (kicker + title + search + sort + +New ticket),
# a row of horizontal tab buttons sourced from App.OverviewIndexCollection,
# and a dense table with avatars + role/priority/state pills.
#
# Dispatched from TicketOverviewRouter when the user has ticket.agent.
class App.AgentOverviewFaithful extends App.Controller
  @requiredPermission: 'ticket.agent'

  elements:
    '.js-search':   'searchInput'
    '.js-sort':     'sortSelect'

  events:
    'input .js-search':    'onSearchInput'
    'change .js-sort':     'onSortChange'
    'click .js-otab':      'onTabClick'
    'click tbody tr.js-row': 'onRowClick'

  constructor: (params) ->
    super
    @view  = params.view or 'my_assigned'
    @query = ''
    @sort  = 'updated'

    @title @viewLabel(@view), true
    @navupdate "#ticket/view/#{@view}"

    @overviewIndexBindId = App.OverviewIndexCollection.bind(=>
      @render()
    , false)

    @subscribeView(@view)
    @render()

  release: =>
    if @overviewIndexBindId
      App.OverviewIndexCollection.unbindById(@overviewIndexBindId)
    if @collectionBindId and @collectionView
      App.OverviewListCollection.unbindById(@collectionBindId)
    super

  subscribeView: (view) =>
    if @collectionBindId
      App.OverviewListCollection.unbindById(@collectionBindId)
    @collectionView = view
    @collectionBindId = App.OverviewListCollection.bind(view, @onCollection)
    App.OverviewListCollection.fetch(view)

  onCollection: (data) =>
    @data = data
    @render()

  update: (params = {}) =>
    if params.view and params.view isnt @view
      @view = params.view
      @subscribeView(@view)
    @title @viewLabel(@view), true
    @navupdate "#ticket/view/#{@view}"
    @render()

  onSearchInput: (e) =>
    @query = e.target.value
    @renderRows()

  onSortChange: (e) =>
    @sort = e.target.value
    @renderRows()

  onTabClick: (e) =>
    e.preventDefault()
    key = $(e.currentTarget).data('view')
    return if !key
    @navigate "#ticket/view/#{key}"

  onRowClick: (e) =>
    id = $(e.currentTarget).data('id')
    @navigate "#ticket/zoom/#{id}" if id

  viewLabel: (link) ->
    o = App.Overview.findByAttribute('link', link)
    o?.name or link

  relTime: (iso) ->
    return '' if !iso
    diff = Date.now() - new Date(iso).getTime()
    minute = 60 * 1000
    hour = 60 * minute
    day = 24 * hour
    if diff < minute then 'now'
    else if diff < hour then "#{Math.round(diff / minute)}m ago"
    else if diff < day then "#{Math.round(diff / hour)}h ago"
    else "#{Math.round(diff / day)}d ago"

  priorityClass: (name) ->
    return 'cp-pri cp-pri--high'   if /high|3/i.test(name or '')
    return 'cp-pri cp-pri--low'    if /low|1/i.test(name or '')
    'cp-pri cp-pri--normal'

  stateBucket: (state, stateType) ->
    return 'closed' if state?.name in ['closed', 'merged']
    return 'pending'  if stateType?.name in ['pending reminder', 'pending action']
    return 'resolved' if stateType?.name is 'closed'
    'open'

  decoratedRows: ->
    raw = @data?.tickets or []
    rows = []
    for ref in raw
      t = App.Ticket.find(ref.id)
      continue if !t
      state    = App.TicketState.find(t.state_id)
      stType   = if state then App.TicketStateType.find(state.state_type_id) else null
      bucket   = @stateBucket(state, stType)
      priority = App.TicketPriority.find(t.priority_id)
      group    = App.Group.find(t.group_id)
      customer = if t.customer_id then App.User.find(t.customer_id) else null
      owner    = if t.owner_id and t.owner_id isnt 1 then App.User.find(t.owner_id) else null
      rows.push
        id:           t.id
        number:       t.number
        title:        t.title or '(no title)'
        customer:     customer
        customerName: customer?.fullname or customer?.email or ''
        group:        group?.name or ''
        owner:        owner
        ownerName:    owner?.firstname or owner?.fullname or ''
        priorityName: priority?.name or 'normal'
        priorityClass: @priorityClass(priority?.name)
        stateBucket:  bucket
        stateName:    state?.name or ''
        updatedAt:    t.updated_at
    rows

  filteredRows: ->
    rows = @decoratedRows()
    if @query.trim()
      q = @query.toLowerCase()
      rows = rows.filter (r) ->
        (r.title or '').toLowerCase().indexOf(q) isnt -1 or
        String(r.number).indexOf(q) isnt -1
    rows.slice().sort (a, b) =>
      switch @sort
        when 'created' then (new Date(b.createdAt or b.updatedAt or 0)) - (new Date(a.createdAt or a.updatedAt or 0))
        else                (new Date(b.updatedAt or 0)) - (new Date(a.updatedAt or 0))

  tabs: ->
    overviews = App.OverviewIndexCollection.get() or []
    keys = ['my_assigned','all_unassigned','all_open','all_pending_reached','all_escalated']
    out = []
    for k in keys
      ov = _.find(overviews, (o) -> o.link is k)
      continue if !ov
      out.push
        key:    k
        label:  ov.name
        count:  ov.count or 0
        active: k is @view
    out

  initials: (name) ->
    return '?' if !name
    parts = (name + '').trim().split(/\s+/).slice(0, 2)
    (parts.map (p) -> (p[0] or '').toUpperCase()).join('') or '?'

  render: =>
    rows = @filteredRows()
    @html App.view('agent_overview_faithful')(
      view:          @view
      viewLabel:     @viewLabel(@view)
      tabs:          @tabs()
      rows:          rows
      query:         @query
      sort:          @sort
      relTime:       (iso) => @relTime(iso)
      initials:      (n) => @initials(n)
    )

  renderRows: =>
    @render()

App.Config.set('AgentOverviewFaithful', { controller: 'AgentOverviewFaithful', permission: ['ticket.agent'] }, 'permanentTask')
