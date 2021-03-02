class App.TicketCreateSidebar
  constructor: (options) ->
    for key, value of options
      @[key] = value

    @render()

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

  render: (params) =>
    if params
      @params = params
    @sidebarBackends ||= {}
    @sidebarItems = []
    sidebarBackends = App.Config.get('TicketCreateSidebar')
    keys = _.keys(sidebarBackends).sort()
    for key in keys
      if !@sidebarBackends[key] || !@sidebarBackends[key].reload
        @sidebarBackends[key] = new sidebarBackends[key](
          params:   @params
          query:    @query
          taskGet:  @taskGet
          taskKey:  @taskKey
        )
      else
        @sidebarBackends[key].reload(
          params:  @params
          query:   @query
        )
      @sidebarItems.push @sidebarBackends[key]

    if @sidebar
      @sidebar.releaseController()

    @sidebar = new App.Sidebar(
      el:           @el
      sidebarState: @sidebarState
      items:        @sidebarItems
    )
