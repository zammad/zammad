class App.TicketZoomSidebar extends App.ControllerObserver
  model: 'Ticket'
  observe:
    customer_id: true
    organization_id: true

  release: =>
    super
    if @sidebarBackends
      for key, value of @sidebarBackends
        @sidebarBackends[key]?.releaseController()

  get: (key) ->
    return @sidebarBackends[key]

  reload: (args) =>
    for key, backend of @sidebarBackends
      if backend && backend.reload
        backend.reload(args)

  commit: (args) =>
    for key, backend of @sidebarBackends
      if backend && backend.commit
        backend.commit(args)

  postParams: (args) =>
    for key, backend of @sidebarBackends
      if backend && backend.postParams
        backend.postParams(args)

  ticketZoomShown: =>
    for key, value of @sidebarBackends
      value.ticketZoomShown?()

  render: (ticket) =>
    @sidebarBackends ||= {}
    @sidebarItems = []
    sidebarBackends = App.Config.get('TicketZoomSidebar')
    keys = _.keys(sidebarBackends).sort()
    for key in keys
      if !@sidebarBackends[key] || !@sidebarBackends[key].reload
        @sidebarBackends[key] = new sidebarBackends[key](
          ticket:           ticket
          query:            @query
          taskGet:          @taskGet
          taskKey:          @taskKey
          formMeta:         @formMeta
          markForm:         @markForm
          tags:             @tags
          mentions:         @mentions
          time_accountings: @time_accountings
          links:            @links
          parent:           @parent
        )
      else
        @sidebarBackends[key].reload(
          params:           @params
          query:            @query
          formMeta:         @formMeta
          markForm:         @markForm
          tags:             @tags
          mentions:         @mentions
          time_accountings: @time_accountings
          links:            @links
          parent:           @parent
        )
      @sidebarItems.push @sidebarBackends[key]

    if @sidebar
      @sidebar.releaseController()

    @sidebar = new App.Sidebar(
      el:           @$('.tabsSidebar')
      sidebarState: @sidebarState
      items:        @sidebarItems
    )
