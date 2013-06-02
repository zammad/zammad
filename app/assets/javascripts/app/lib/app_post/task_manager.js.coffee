class App.TaskManager
  _instance = undefined

  @init: ->
    _instance ?= new _Singleton

  @all: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.all()

  @add: ( key, callback, params, to_not_show, state ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.add( key, callback, params, to_not_show, state )

  @get: ( key ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.get( key )

  @update: ( key, params ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.update( key, params )

  @remove: ( key ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.remove( key )

  @notify: ( key ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.notify( key )

  @reorder: ( order ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.reorder( order )

  @reset: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.reset()

  @worker: ( key ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.worker( key )

  @workerAll: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.workerAll()

  @clientId: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.clientId()

class _Singleton extends App.Controller
  @include App.Log

  constructor: ->
    @workers        = {}
    @workersStarted = {}
    @activeTask = undefined
    @tasksInitial()

  all: ->
    tasks = App.Taskbar.all()
    tasks = _(tasks).sortBy( (task) ->
      return task.prio;
    )
    return tasks

  worker: ( key ) ->
    return @workers[ key ] if @workers[ key ]
    return

  workerAll: ->
    @workers

  add: ( key, callback, params, to_not_show = false, state ) ->
    active = true
    if to_not_show
      active = false

    # create new task if not exists
    task = @get( key )
#    console.log('add', key, callback, params, to_not_show, state, task)
    if !task
      task = new App.Taskbar
      task.load(
        key:      key
        params:   params
        callback: callback
        client_id: 123
        prio:     App.Taskbar.count() + 1
        notify:   false
        active:   active
      )
      task.save()

    tasks = @all()

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
      for task in tasks
        if task.key isnt key
          if task.active
            task.active = false
            task.save()
        else
          changed = false
          if !task.active
            changed = true
            task.active = true
          if task.notify
            changed = true
            task.notify = false
          if changed
            task.save()
    else
      for task in tasks
        if @activeTask isnt task.key
          if task.active
            task.active = false
            task.save()

    # start worker for task if not exists
    @startController(key, callback, params, state, to_not_show)

    App.Event.trigger 'ui:rerender'
    App.Event.trigger 'ui:rerender:content'
    return key

  startController: (key, callback, params, state, to_not_show) =>

#    console.log('controller started...', callback, key, params, state)

    # activate controller
    worker = @worker( key )
    if worker && worker.activate
      worker.activate()

    # return if controller is alreary started
    return if @workersStarted[key]
    @workersStarted[key] = true

    # create new controller instanz
    params_app = _.clone(params)
    params_app['el']       = $('#content_permanent_' + key )
    params_app['task_key'] = key

    # check if we have old state there
    if !state
      oldTask = @get( key )
      if oldTask
        state = oldTask.state
    params_app['form_state'] = state

    if to_not_show
      params_app['doNotLog'] = 1
    a = new App[callback]( params_app )
    @workers[ key ] = a

    # activate controller
    if !to_not_show
      a.activate()

    return a

  get: ( key ) =>
    tasks = @all()
    for task in tasks
      return task if task.key is key
    return
#    throw "No such task with '#{key}'"

  update: ( key, params ) =>
    task = @get( key )
    if !task
      throw "No such task with '#{key}' to update"
    for item, value of params
      task.updateAttribute(item, value)
#    task.save()

  remove: ( key, to_not_show = false ) =>
    task = @get( key )
    if !task
      throw "No such task with '#{key}' to remove"

    worker = @worker( key )
    if worker && worker.release
      worker.release()
    @workersStarted[ key ] = false
    task.destroy()
    App.Event.trigger 'ui:rerender'

  notify: ( key ) =>
    task = @get( key )
    if !task
      throw "No such task with '#{key}' to notify"
    task.notify = true
    task.save()
    App.Event.trigger 'ui:rerender'

  reorder: ( order ) =>
    prio = 0
    for key in order
      task = @get( key )
      if !task
        throw "No such task with '#{key}' of order"
      prio++
      if task.prio isnt prio
        task.prio = prio
        task.save()

  reset: =>
    App.Taskbar.deleteAll()
    App.Event.trigger 'ui:rerender'

  clientId: =>
    if !@clientIdInt
       @clientIdInt = Math.floor( Math.random() * 99999999 )
    @clientIdInt

  tasksInitial: =>
    # reopen tasks
#    App.Taskbar.fetch()
    tasks = @all()
    return if !tasks

    # check if we have different

    # broadcast to other browser instance
    App.WebSocket.send(
      action: 'broadcast'
      event:  'session:takeover'
      spool:  true
      data:
        recipient:
          user_id: [ App.Session.get( 'id' ) ]
        client_id: @clientId()
    )

    task_count = 0
    for task in tasks
      task_count += 1
      @delay(
        =>
          task = tasks.shift()
          @add(task.key, task.callback, task.params, true, task.state)
        task_count * 500
      )

