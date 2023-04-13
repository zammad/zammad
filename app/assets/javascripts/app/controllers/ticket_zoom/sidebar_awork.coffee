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
    @badgeEl.html(App.view('integration/awork/sidebar_tabs_item')(@metaBadge()))

  linkTask: =>
    new App.AworkTaskLinkModal(
      head: @provider
      ticket_id: @ticket.id
      taskLinks: @taskLinks
      container: @el.closest('.content')
      callback: (taskLinks) =>
        @taskLinks = taskLinks
        @getTasks()
    )

  createTask: =>
    new App.AworkTaskCreateModal(
      head: @provider
      ticket_id: @ticket.id
      container: @el.closest('.content')
      callback: (taskLinks) =>
        @taskLinks = taskLinks
        @getTasks()
    )

  reloadTasks: (el) =>
    if el
      @el = el

    return @renderTasks() if !@ticket

    ticketLinks = @ticket?.preferences?[@providerIdentifier]?.task_ids || []
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
      taskId = $(e.currentTarget).attr 'data-task-id'
      @deleteTask(taskId)
      @renderTasks()
    )
    @html(list)
    @badgeRenderLocal()

  listTasks: (force = false) =>
    return @renderTasks() if !force && @fetchFullActive && @fetchFullActive > new Date().getTime() - 5000
    @fetchFullActive = new Date().getTime()

    return @renderTasks() if _.isEmpty(@taskLinks)

    @getTasks()

  getTasks: =>
    @ajax(
      id:    "#{@providerIdentifier}-get-tasks-#{@ticket.id}"
      type:  'GET'
      url:   "#{@apiPath}/integration/#{@providerIdentifier}/tasks/#{@ticket.id}"
      success: (data, status, xhr) =>
        if data.response
          @taskLinks    = data.response.map((task) -> task.id)
          @taskLinkData = data.response
          @renderTasks()
        else
          @showError(data.message)
      error: (xhr, status, error) ->
        return if status is 'abort'

        @showError(App.i18n.translateInline('Loading failed.'))
    )

  saveTasks: =>
    App.Ajax.request(
      id:    "#{@providerIdentifier}-update-#{@ticket.id}"
      type:  'POST'
      url:   "#{@apiPath}/integration/#{@providerIdentifier}/tasks/update"
      data:  JSON.stringify(
        ticket_id: @ticket.id,
        linked_tasks: @taskLinks
      )
      success: (data, status, xhr) =>
        if data.result is 'failed'
          new App.ControllerErrorModal(
            message: data.message
            container: @el.closest('.content')
          )
          return

        App.Event.trigger 'notify', {
          type: 'success'
          msg:  App.i18n.translateContent('Update successful.')
        }
    )

  deleteTask: (id) =>
    @taskLinks    = _.filter(@taskLinks, (element) -> element isnt id)
    @taskLinkData = _.filter(@taskLinkData, (element) -> element.id isnt id)

    @saveTasks()
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
    args.ticket.preferences[@providerIdentifier].task_ids = @taskLinks

App.Config.set('500-Awork', SidebarAwork, 'TicketCreateSidebar')
App.Config.set('500-Awork', SidebarAwork, 'TicketZoomSidebar')