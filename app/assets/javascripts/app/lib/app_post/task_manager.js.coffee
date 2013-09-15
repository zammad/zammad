class App.TaskManager
  _instance = undefined

  @init: ->
    _instance ?= new _taskManagerSingleton

  @all: ->
    if _instance == undefined
      _instance ?= new _taskManagerSingleton
    _instance.all()

  @add: ( key, callback, params, to_not_show ) ->
    if _instance == undefined
      _instance ?= new _taskManagerSingleton
    _instance.add( key, callback, params, to_not_show )

  @get: ( key ) ->
    if _instance == undefined
      _instance ?= new _taskManagerSingleton
    _instance.get( key )

  @update: ( key, params ) ->
    if _instance == undefined
      _instance ?= new _taskManagerSingleton
    _instance.update( key, params )

  @remove: ( key ) ->
    if _instance == undefined
      _instance ?= new _taskManagerSingleton
    _instance.remove( key )

  @notify: ( key ) ->
    if _instance == undefined
      _instance ?= new _taskManagerSingleton
    _instance.notify( key )

  @reorder: ( order ) ->
    if _instance == undefined
      _instance ?= new _taskManagerSingleton
    _instance.reorder( order )

  @reset: ->
    if _instance == undefined
      _instance ?= new _taskManagerSingleton
    _instance.reset()

  @worker: ( key ) ->
    if _instance == undefined
      _instance ?= new _taskManagerSingleton
    _instance.worker( key )

  @workerAll: ->
    if _instance == undefined
      _instance ?= new _taskManagerSingleton
    _instance.workerAll()

  @TaskbarId: ->
    if _instance == undefined
      _instance ?= new _taskManagerSingleton
    _instance.TaskbarId()

class _taskManagerSingleton extends App.Controller
  @include App.LogInclude

  constructor: ->
    super
    @workers           = {}
    @workersStarted    = {}
    @allTasks          = []
    @tasksToUpdate     = {}
    @activeTask        = undefined
    @tasksInitial()

    # render on login
    App.Event.bind(
      'auth:login'
      =>
        @tasksInitial()
      'task'
    )

    # render on logout
    App.Event.bind(
      'auth:logout'
      =>
        @reset()
      'task'
    )

    # send updates to server
    App.Interval.set( @taskUpdateLoop, 2500, 'check_update_to_server_pending', 'task' )

  all: ->

    # sort by prio
    @allTasks = _(@allTasks).sortBy( (task) ->
      return task.prio;
    )
    return @allTasks

  newPrio: ->
    prio = 1
    for task in @allTasks
      if task.prio && task.prio > prio
        prio = task.prio
    prio++
    prio

  worker: ( key ) ->
    return @workers[ key ] if @workers[ key ]
    return

  workerAll: ->
    @workers

  add: ( key, callback, params, to_not_show = false ) ->
    active = true
    if to_not_show
      active = false

    # create new task if not exists
    task = @get( key )
    console.log('add', key, callback, params, to_not_show, task)
    if !task
      console.log('add, create new taskbar in backend')
      task = new App.Taskbar
      task.load(
        key:      key
        params:   params
        callback: callback
        client_id: 123
        prio:     @newPrio()
        notify:   false
        active:   active
      )
      @allTasks.push task.attributes()

      # save new task and update task collection
      ui = @
      task.save(
        success: ->
          for taskPosition of ui.allTasks
            if ui.allTasks[taskPosition] && ui.allTasks[taskPosition]['key'] is @key
              task = @attributes()
              ui.allTasks[taskPosition] = task
      )

    # create div for permanent content
    if !$("#content_permanent")[0]
      $('#app section').append('<div id="content_permanent" class="content"></div>')

    # empty static content if task is shown
    if active
      @activeTask = key
      $('#content').empty()

      # hide all tasks
      $('.content_permanent').hide()
      $('.content_permanent').removeClass('active')

    # create div for task if not exists
    if !$("#content_permanent_#{key}")[0]
      $('#content_permanent').append('<div id="content_permanent_' + key + '" class="content_permanent"></div>')

    # set task to shown and active
    if @activeTask is key
      $('#content_permanent_' + key ).show()
      $('#content_permanent_' + key ).addClass('active')
    else
      $('#content_permanent_' + key ).hide()
      $('#content_permanent_' + key ).removeClass('active')

    # set all tasks to active false, only new/selected one to active
    if active
      for task in @allTasks
        if task.key isnt key
          if task.active
            task.active = false
            @taskUpdate( task )
        else
          changed = false
          if !task.active
            changed = true
            task.active = true
          if task.notify
            changed = true
            task.notify = false
          if changed
            @taskUpdate( task )
    else
      for task in @allTasks
        if @activeTask isnt task.key
          if task.active
            task.active = false
            @taskUpdate( task )

    # start worker for task if not exists
    @startController(key, callback, params, to_not_show)

    App.Event.trigger 'task:render'
    return key

  startController: (key, callback, params, to_not_show) =>

    console.log('controller start try...', callback, key)

    # activate controller
    worker = @worker( key )
    if worker && worker.activate
      worker.activate()

    # return if controller is already started
    return if @workersStarted[key]
    @workersStarted[key] = true
    console.log('controller start now...', callback, key)

    # create new controller instanz
    params_app = _.clone(params)
    params_app['el']       = $('#content_permanent_' + key )
    params_app['task_key'] = key

    if to_not_show
      params_app['doNotLog'] = 1
    a = new App[callback]( params_app )
    @workers[ key ] = a
    console.log('controller start now 2...', callback, key)

    # activate controller
    if !to_not_show
      console.log('controller start now 2 activate...', callback, key)
      a.activate()

    console.log('controller start now 2 return...', callback, key)
    return a

  get: ( key ) =>
    for task in @allTasks
      if task.key is key
        return task
#      return task if task.key is key
    return
#    throw "No such task with '#{key}'"

  update: ( key, params ) =>
    task = @get( key )
    if !task
      throw "No such task with '#{key}' to update"
    for item, value of params
      task[item] = value
    @taskUpdate( task )

  remove: ( key, to_not_show = false ) =>
    task = @get( key )
    if !task
      throw "No such task with '#{key}' to remove"

    allTasks = _.filter(
      @allTasks
      (taskLocal) ->
        return task if task.key isnt taskLocal.key
        return
    )
    @allTasks = allTasks || []

    $('#content_permanent_' + key ).html('')
    $('#content_permanent_' + key ).remove()

    delete @workersStarted[ key ]
    delete @workers[ key ]

    App.Event.trigger 'task:render'

    # destroy in backend
    @taskDestroy(task)

  notify: ( key ) =>
    task = @get( key )
    if !task
      throw "No such task with '#{key}' to notify"
    task.notify = true
    @taskUpdate( task )

  reorder: ( order ) =>
    prio = 0
    for key in order
      task = @get( key )
      if !task
        throw "No such task with '#{key}' of order"
      prio++
      if task.prio isnt prio
        task.prio = prio
        @taskUpdate( task )

  reset: =>

    # release tasks
    for task in @allTasks
      $('#content_permanent_' + task.key ).html('')
      $('#content_permanent_' + task.key ).remove()

      delete @workersStarted[ task.key ]
      delete @workers[ task.key ]

    # clear instance vars
    @tasksToUpdate = {}
    @allTasks      = []
    @activeTask    = undefined

    # clear in mem tasks
    App.Taskbar.deleteAll()

    # rerender task bar
    App.Event.trigger 'task:render'

  TaskbarId: =>
    if !@TaskbarIdInt
      @TaskbarIdInt = Math.floor( Math.random() * 99999999 )
    @TaskbarIdInt

  taskUpdate: (task) ->
    @log 'notice', "UPDATE task #{task.id}", task
    @tasksToUpdate[ task.key ] = 'toUpdate'
    App.Event.trigger 'task:render'

  taskUpdateLoop: =>
    for key of @tasksToUpdate
      continue if !key
      task = @get( key )
      continue if !task
      if @tasksToUpdate[ task.key ] is 'toUpdate'
        @tasksToUpdate[ task.key ] = 'inProgress'
        taskUpdate = new App.Taskbar
        taskUpdate.load( task )
        if taskUpdate.isOnline()
          ui = @
          taskUpdate.save(
            success: ->
              if ui.tasksToUpdate[ @key ] is 'inProgress'
                delete ui.tasksToUpdate[ @key ]
            error: (task) =>
              ui.log 'error', "can't update task '#{task.id}'"
              if ui.tasksToUpdate[ @key ] is 'inProgress'
                delete ui.tasksToUpdate[ @key ]
          )

  taskDestroy: (task) ->

    # check if update is still in process
    if @tasksToUpdate[ task.key ] is 'inProgress'
      App.Delay.set(
        => @taskDestroy(task)
        800
        undefined
        'task'
      )
      return

    # destory task in backend
    delete @tasksToUpdate[ task.key ]
    App.Taskbar.destroy(task.id)
    return

  tasksInitial: =>

    # initial load of taskbar collection
    tasks     = App.Taskbar.all()
    @allTasks = []
    for task in tasks
      @allTasks.push task.attributes()

    # reopen tasks
    App.Event.trigger 'taskbar:init'

    task_count = 0
    for task in @allTasks
      task_count += 1
      console.log('START', task)
      do (task) =>
        App.Delay.set(
          =>
            @add(task.key, task.callback, task.params, true)
          task_count * 600
          undefined
          'task'
        )

    App.Event.trigger 'taskbar:ready'

