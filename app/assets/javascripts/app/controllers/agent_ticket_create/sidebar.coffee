class App.TicketCreateSidebar extends App.Controller
  constructor: ->
    super
    @render()

  reload: (args) =>
    for key, backend of @sidebarBackends
      if backend && backend.reload
        backend.reload(args)

  commit: (args) =>
    for key, backend of @sidebarBackends
      if backend && backend.commit
        backend.commit(args)

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
          params:  @params
          query:   @query
          taskGet: @taskGet
        )
      else
        @sidebarBackends[key].reload(
          params:  @params
          query:   @query
        )
      item = @sidebarBackends[key].sidebarItem()
      if item
        @sidebarItems.push item

    new App.Sidebar(
      el:           @el
      sidebarState: @sidebarState
      items:        @sidebarItems
    )
