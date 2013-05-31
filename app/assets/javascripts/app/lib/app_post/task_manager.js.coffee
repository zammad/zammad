class App.TaskManager
  _instance = undefined

  @init: ->
    _instance ?= new _Singleton

  @all: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.all()

  @add: ( type, type_id, callback, params, to_not_show, state ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.add( type, type_id, callback, params, to_not_show, state )

  @get: ( type, type_id ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.get( type, type_id )

  @update: ( type, type_id, params ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.update( type, type_id, params )

  @remove: ( type, type_id ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.remove( type, type_id )

  @notify: ( type, type_id ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.notify( type, type_id )

  @reset: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.reset()

  @worker: ( type, type_id ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.worker( type, type_id )

  @workerAll: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.workerAll()

class _Singleton extends App.Controller
  @include App.Log

  constructor: ->
    @workers        = {}
    @workersStarted = {}
    @activeTask = undefined
    @tasksInitial()
    
  all: ->
    App.Taskbar.all()

  worker: ( type, type_id ) ->
    key = @keyGenerate(type, type_id)
    return @workers[ key ] if @workers[ key ]
    return

  workerAll: ->
    @workers

  add: ( type, type_id, callback, params, to_not_show = false, state ) ->
    active = true
    if to_not_show
      active = false

    # create new task if not exists
    task = @get( type, type_id )
#    console.log('add', type, type_id, callback, params, to_not_show, state, task)
    if !task
      task = new App.Taskbar
      task.load(
        type:     type
        type_id:  type_id
        params:   params
        callback: callback
        notify:   false
        active:   active
      )
      task.save()
    
    tasks = @all()

    # empty static content if task is shown
    key = @keyGenerate(type, type_id)
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
        task_key = @keyGenerate(task.type, task.type_id)
        if task_key isnt key 
          task.active = false
        else
          task.active = true
        task.save()
    else
      for task in tasks
        task_key = @keyGenerate(task.type, task.type_id)
        if @activeTask isnt task_key
          if task.active
            task.active = false
            task.save()

    # start worker for task if not exists
    @startController(type, type_id, callback, params, state, key, to_not_show)

    App.Event.trigger 'ui:rerender'
    App.Event.trigger 'ui:rerender:content'
    return key

  startController: (type, type_id, callback, params, state, key, to_not_show) =>

#    console.log('controller started...', callback, type, type_id, params, state)

    # activate controller
    worker = @worker( type, type_id  )
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
      oldTask = @get( type, type_id )
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

  get: ( type, type_id ) =>
    tasks = App.Taskbar.all()
    for task in tasks
      return task if task.type is type && task.type_id.toString() is type_id.toString()
    return
#    throw "No such task with '#{type}' and '#{type_id}'"

  update: ( type, type_id, params ) =>
    task = @get( type, type_id )
    if !task
      throw "No such task with '#{type}' and '#{type_id}' to update"
    for item, value of params
      task.updateAttribute(item, value)
#    task.save()

  remove: ( type, type_id, to_not_show = false ) =>
    task = @get( type, type_id )
    if !task
      throw "No such task with '#{type}' and '#{type_id}' to remove"

    worker = @worker( type, type_id  )
    if worker && worker.release
      worker.release()
    @workersStarted[ @keyGenerate(type, type_id) ] = false
    task.destroy()
    App.Event.trigger 'ui:rerender'

  notify: ( type, type_id ) =>
    task = @get( type, type_id )
    if !task
      throw "No such task with '#{type}' and '#{type_id}' to notify"
    task.notify = true

  reset: =>
    App.Taskbar.deleteAll()
    App.Event.trigger 'ui:rerender'

  tasksInitial: =>
    # reopen tasks
    App.Taskbar.fetch()
    tasks = @all()
    return if !tasks
    task_count = 0
    for task in tasks
      task_count += 1
      @delay(
        =>
          task = tasks.shift()
          @add(task.type, task.type_id, task.callback, task.params, true, task.state)
        task_count * 500
      )

  keyGenerate: ( type, type_id )->
    "#{type}_#{type_id}"
