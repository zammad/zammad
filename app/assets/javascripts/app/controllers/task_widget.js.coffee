class App.TaskWidget extends App.Controller

  constructor: ->
    super
    @render()

    # render on generic ui call
    @bind 'ui:rerender', => @render()

    # render on login
    @bind 'auth:login', => @render()

    # reset current tasks on logout
    @bind 'auth:logout', => @el.html('')

    # only do take over check after spool messages are finised
    App.Event.bind(
      'spool:sent'
      =>
        @spoolSent = true

        # broadcast to other browser instance
        App.WebSocket.send(
          action: 'broadcast'
          event:  'session:takeover'
          spool:  true
          recipient:
            user_id: [ App.Session.get( 'id' ) ]
          data:
            taskbar_id: App.TaskManager.TaskbarId()
        )
      'task'
    )

    # session take over message
    App.Event.bind(
      'session:takeover'
      (data) =>

        # only if spool messages are already sent
        return if !@spoolSent

        # check if error message is already shown
        if !@error

          # only if new client id isnt own client id
          if data.taskbar_id isnt App.TaskManager.TaskbarId()
            @error = new App.SessionMessage(
              title:       'Session'
              message:     'Session taken over... please reload page or work with other browser window.'
              keyboard:    false
              backdrop:    true
              close:       true
              button:      'Reload application'
              forceReload: true
            )
            @disconnectClient()
      'task'
    )

  render: ->
    return if _.isEmpty( @Session.all() )

    @html App.view('task_widget')(
      taskBarActions: @_getTaskActions()
    )
    @el.find('.taskbar-items').html('')
    new Taskbar(
      el: @el.find('.taskbar-items')
    )

  _getTaskActions: ->
    roles  = App.Session.get( 'roles' )
    navbar = _.values( @Config.get( 'TaskActions' ) )
    level1 = []

    for item in navbar
      if typeof item.callback is 'function'
        data = item.callback() || {}
        for key, value of data
          item[key] = value
      if !item.parent
        match = 0
        if !item.role
          match = 1
        if !roles && item.role
          match = _.include( item.role, 'Anybody' )
        if roles
          for role in roles
            if !match
              match = _.include( item.role, role.name )

        if match
          level1.push item
    level1

class Taskbar extends App.Controller
  events:
    'click [data-type="close"]': 'remove'

  constructor: ->
    super
    @render()

    # on window resize
    resizeTasksDelay = =>
      App.Delay.set( @resizeTasks, 60, 'resizeTasks', 'task' )
    $(window).off( 'resize.taskbar' ).on( 'resize.taskbar', resizeTasksDelay )

    # render view
    @bind 'task:render', => @render()

    # reset current tasks on logout
    @bind 'auth:logout', => @el.html('')

  render: ->
    return if _.isEmpty( @Session.all() )

    tasks = App.TaskManager.all()
    item_list = []
    for task in tasks

      # collect meta data of task for task bar item
      data =
        url:   '#'
        id:    false
        title: App.i18n.translateInline('Loading...')
        head:  App.i18n.translateInline('Loading...')
      worker = App.TaskManager.worker( task.key  )
      if worker
        meta = worker.meta()

        # apply meta data of controller
        if meta
          for key, value of meta
            data[key] = value

      # collect new task bar items
      item = {}
      item.task = task
      item.data = data
      item_list.push item

      # set title
      if task.active
        @title data.title

    @html App.view('task_widget_tasks')(
      item_list: item_list
    )

    @resizeTasks()

    dndOptions =
      tolerance:            'pointer'
      distance:             15
      opacity:              0.6
      forcePlaceholderSize: true
      items:                '> a'
      update:               =>
        items = @el.find('> a')
        order = []
        for item in items
          key = $(item).data('key')
          if !key
            throw "No such key attributes found for task item"
          order.push key
        App.TaskManager.reorder( order  )

    @el.sortable( dndOptions )

  remove: (e, key = false, force = false) =>
    e.preventDefault()
    if !key
      key = $(e.target).parent().data('key')
    if !key
      throw "No such key attributes found for task item"

    # check if input has changed
    worker = App.TaskManager.worker( key )
    if !force && worker && worker.changed
      if worker.changed()
        new Remove(
          key: key
          ui:  @
        )
        return

    # check if active task is closed
    currentTask = App.TaskManager.get( key )
    tasks = App.TaskManager.all()
    active_is_closed = false
    for task in tasks
      if currentTask.active && task.key is key
        active_is_closed = true

    # remove task
    App.TaskManager.remove( key )

    @resizeTasks()

    # navigate to next task if needed
    tasks = App.TaskManager.all()
    if active_is_closed && !_.isEmpty( tasks )
      task_last = undefined
      for task in tasks
        task_last = task
      if task_last
        worker = App.TaskManager.worker( task_last.key )
        if worker
          @navigate worker.url()
        return
    if _.isEmpty( tasks )
      @navigate '#'

  resizeTasks: ->
    width = $('#task .taskbar-items').width()# - $('#task .taskbar-new').width() - 200
    task_count = App.TaskManager.all().length
    task_size  = ( width / task_count ) - 40
    elementsOversize = 0
    elementsOversizeLeftTotal = 0
    $('#task .task').each(
      (position, element) ->
        widthTask = $(element).width()
        if widthTask > task_size
          elementsOversize++
        else
          elementsOversizeLeftTotal += task_size - widthTask
    )

    addOversize = elementsOversizeLeftTotal / elementsOversize
    task_size += addOversize
    if task_size < 40
      $('#task .task').css('max-width', '40px')
    else if task_size < 130
      $('#task .task').css('max-width', task_size + 'px')
    else
      $('#task .task').css('max-width', '130px')

class Remove extends App.ControllerModal
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('modal')(
      title:   'Confirm'
      message: 'Tab has changed, you really want to close it?'
      close:   true
      button:  'Close'
    )
    @modalShow(
      backdrop: true,
      keyboard: true,
    )

  submit: (e) =>
    @modalHide()
    @ui.remove(e, @key, true)

App.Config.set( 'task', App.TaskWidget, 'Widgets' )
