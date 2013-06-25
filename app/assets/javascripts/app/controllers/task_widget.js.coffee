class App.TaskWidget extends App.Controller
  events:
    'click    [data-type="close"]': 'remove'

  constructor: ->
    super
    @render()

    # render on generic ui call
    App.Event.bind 'ui:rerender', =>
      @render()

    # render view
    App.Event.bind 'task:render', =>
      @render()

    # render on login
    App.Event.bind 'auth:login', =>
      @render()

    # reset current tasks on logout
    App.Event.bind 'auth:logout', =>
      @el.html('')

    # only do take over check after spool messages are finised
    App.Event.bind 'spool:sent', =>
      @spoolSent = true

    # session take over message
    App.Event.bind 'session:takeover', (data) =>

      # only if spool messages are already sent
      return if !@spoolSent

      # check if error message is already shown
      if !@error

        # only if new client id isnt own client id
        if data.taskbar_id isnt App.TaskManager.TaskbarId()
          @error = new App.SessionReloadModal(
            title:    'Session'
            message:  'Session taken over... please reload page or work with other browser window.'
            keyboard: false
            backdrop: true
            close:    true
            button:   'Reload application'
          )

          # disable all delay's and interval's
          App.Delay.reset()
          App.Interval.reset()
          App.WebSocket.close( force: true )

  render: ->

    return if _.isEmpty( @Session.all() )

    tasks = App.TaskManager.all()
    item_list = []
    for task in tasks
      data =
        url:   '#'
        id:    false
        title: App.i18n.translateInline('Loading...')
        head:  App.i18n.translateInline('Loading...')
      worker = App.TaskManager.worker( task.key  )
      if worker
        meta = worker.meta()
        if meta
          data = meta
      item = {}
      item.task = task
      item.data = data
      item_list.push item

      # set title
      if task.active
        @title data.title

    @html App.view('task_widget')(
      item_list:      item_list
      taskBarActions: @_getTaskActions()
    )

    dndOptions =
      tolerance:            'pointer'
      distance:             15
      opacity:              0.6
      forcePlaceholderSize: true
      items:                '> a'
      update:               =>
        items = @el.find('.taskbar > a')
        order = []
        for item in items
          key = $(item).data('key')
          if !key
            throw "No such key attributes found for task item"
          order.push key
        App.TaskManager.reorder( order  )

    @el.find( '.taskbar' ).sortable( dndOptions )

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
