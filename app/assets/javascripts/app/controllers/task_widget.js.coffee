class App.TaskWidget extends App.Controller
  events:
    'click    [data-type="close"]': 'remove'

  constructor: ->
    super
    @render()

    # rerender view
    App.Event.bind 'ui:rerender', (data) =>
      @render()

    # rebuild chat widget
    App.Event.bind 'auth', (user) =>
      App.TaskManager.reset()
      @el.html('')

    App.TaskManager.syncInitial()

    sync = =>
      App.TaskManager.sync()
      @delay( sync, 3000, 'task-widget' )

    @delay( sync, 5000, 'task-widget' )

  render: ->

    return if _.isEmpty( @Session.all() )

    tasks = App.TaskManager.all()
    item_list = []
    for key, task of tasks
      data =
        url:   '#'
        id:    false
        title: App.i18n.translateInline('Loading...')
        head:  App.i18n.translateInline('Loading...')
      if task.worker
        meta = task.worker.meta()
        if meta
          data = meta
      data.title = App.i18n.escape( data.title )
      data.head  = App.i18n.escape( data.head )
      item = {}
      item.key  = key
      item.task = task
      item.data = data
      item_list.push item

    @html App.view('task_widget')(
      item_list:      item_list
      taskBarActions: @_getTaskActions()
    )

  remove: (e) =>
    e.preventDefault()
    key = $(e.target).parent().data('id')

    # check if input has changed
    task = App.TaskManager.get( key )
    if task.worker && task.worker.changed
      if task.worker.changed()
        return if !window.confirm( App.i18n.translateInline('Tab has changed, you really want to close it?') )

    # check if active task is closed
    task_last = undefined
    tasks_all = App.TaskManager.all()
    active_is_closed = false
    for task_key, task of tasks_all
      if task.active && task_key.toString() is key.toString()
        active_is_closed = true

    # remove task
    App.TaskManager.remove( key )
    @render()

    # navigate to next task if needed
    if active_is_closed && !_.isEmpty( tasks_all )
      for key, task of tasks_all
        task_last = task
      if task_last
        @navigate task_last.worker.url()
        return
    if _.isEmpty( tasks_all ) 
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


App.Config.set( 'task', App.TaskWidget, 'Widgets' )
