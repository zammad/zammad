class SidebarAwork extends App.Controller
  provider: 'Awork'

  constructor: ->
    super
    @taskLinks         = []
    @taskLinkData      = []
    @providerIdentifier = @provider.toLowerCase()

  sidebarItem: =>
    return if !@Config.get("#{@providerIdentifier}_integration")
    @item = {
      name: @providerIdentifier
      badgeCallback: @badgeRender
      sidebarHead: @provider
      sidebarCallback: @reloadTasks
      sidebarActions: [
        {
          title:    __('Link task')
          name:     'link-task'
          callback: @linkTask
        },
        {
          title:    __('Create task')
          name:     'create-task'
          callback: @createTask
        },
      ]
    }
    @item

  metaBadge: =>
    counter = ''
    counter = @taskLinks.length

    {
      name: 'customer'
      icon: "#{@providerIdentifier}-logo"
      counterPossible: true
      counter: counter
    }

  badgeRender: (el) =>
    @badgeEl = el
    @badgeRenderLocal()

  badgeRenderLocal: =>
    return if !@badgeEl
    @badgeEl.html(App.view('generic/sidebar_tabs_item')(@metaBadge()))

  linkTask: =>
    new App.AworkTaskLinkModal(
      head: @provider
      container: @el.closest('.content')
    )

  createTask: =>
    new App.AworkTaskCreateModal(
      head: @provider
      container: @el.closest('.content')
    )

  reloadTasks: (el) =>
    if el
      @el = el

    return @renderTasks() if !@ticket

    ticketLinks = @ticket?.preferences?[@providerIdentifier]?.task_links || []
    return @renderTasks() if _.isEqual(@taskLinks, ticketLinks)

    @taskLinks = ticketLinks
    @listTasks(true)

  renderTasks: =>
    if _.isEmpty(@taskLinkData)
      @showEmpty()
      return

    list = $(App.view('ticket_zoom/sidebar_awork_task')(
      tasks: @taskLinkData
    ))
    list.on('click', '.js-delete', (e) =>
      e.preventDefault()
      taskLink = $(e.currentTarget).attr 'data-task-id'
      @deleteTask(taskLink)
    )
    @html(list)
    @badgeRenderLocal()

  listTasks: (force = false) =>
    return @renderTasks() if !force && @fetchFullActive && @fetchFullActive > new Date().getTime() - 5000
    @fetchFullActive = new Date().getTime()

    return @renderTasks() if _.isEmpty(@taskLinks)

    @getTasks(
      links: @taskLinks
      success: (result) =>
        @taskLinks    = result.map((element) -> element.url)
        @taskLinkData = result
        @renderTasks()
      error: =>
        @showError(App.i18n.translateInline('Loading failed.'))
    )

  getTasks: (params) ->
    @ajax(
      id:    "#{@providerIdentifier}-#{@taskKey}"
      type:  'GET'
      url:   "#{@apiPath}/integration/#{@providerIdentifier}tasks/#{@ticket.id}"
      success: (data, status, xhr) ->
        if data.response
          params.success(data.response)
        else
          params.error(data.message)
      error: (xhr, status, error) ->
        return if status is 'abort'

        params.error()
    )

  saveTasks: (params) ->
    App.Ajax.request(
      id:    "#{@providerIdentifier}-update-#{params.ticket_id}"
      type:  'POST'
      url:   "#{@apiPath}/integration/#{@providerIdentifier}/tasks/update"
      data:  JSON.stringify(ticket_id: params.ticket_id, linked_tasks: params.links)
      success: (data, status, xhr) ->
        params.success(data)
      error: (xhr, status, details) ->
        return if status is 'abort'

        params.error()
    )

  deleteTask: (link) ->
    @taskLinks    = _.filter(@taskLinks, (element) -> element isnt link)
    @taskLinkData = _.filter(@taskLinkData, (element) -> element.url isnt link)

    if @ticket && @ticket.id
      @saveTasks(
        ticket_id: @ticket.id
        links: @taskLinks
        success: =>
          @renderTasks()
        error: (message = __('The task could not be saved.')) =>
          @showError(App.i18n.translateInline(message))
      )
    else
      @renderTasks()

  showEmpty: ->
    @html("<div>#{App.i18n.translateInline('No linked tasks')}</div>")
    @badgeRenderLocal()

  showError: (message) =>
    @html App.i18n.translateInline(message)

  reload: =>
    @reloadTasks()

  postParams: (args) =>
    return if !args.ticket
    return if args.ticket.created_at
    return if !@taskLinks
    return if _.isEmpty(@taskLinks)
    args.ticket.preferences ||= {}
    args.ticket.preferences[@providerIdentifier] ||= {}
    args.ticket.preferences[@providerIdentifier].task_links = @taskLinks

App.Config.set('500-Awork', SidebarAwork, 'TicketCreateSidebar')
App.Config.set('500-Awork', SidebarAwork, 'TicketZoomSidebar')