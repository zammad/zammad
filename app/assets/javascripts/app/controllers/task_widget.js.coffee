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

    @delay( sync, 3000, 'task-widget' )

  render: ->

    return if _.isEmpty( @Session.all() )

    tasks = App.TaskManager.all()
    item_list = []
    for key, task of tasks
      item = {}
      item.key  = key
      item.task = task
      item.data = App[task.type].find( task.type_id )
      item_list.push item

    @html App.view('task_widget')(
      item_list: item_list
    )

  remove: (e) =>
    e.preventDefault()
    key = $(e.target).parent().data('id')

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

App.Config.set( 'task', App.TaskWidget, 'Widgets' )
