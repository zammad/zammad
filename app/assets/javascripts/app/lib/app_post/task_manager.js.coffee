class App.TaskManager
  _instance = undefined

  @init: ->
    _instance ?= new _Singleton

  @all: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.all()

  @add: ( type, type_id, callback, params, to_not_show ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.add( type, type_id, callback, params, to_not_show )

  @remove: ( key ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.remove( key )

  @reset: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.reset()

class _Singleton extends Spine.Module
  @include App.Log

  constructor: ->
    @tasks      = {}
    @task_count = 0

    # reopen tasks
    cache = App.Store.get( 'tasks' )
    if cache
      task_count = 0
      for task in cache
        task_count += 1
        setTimeout(
          ->
            task = cache.shift()
            App.TaskManager.add(task.type, task.type_id, task.callback, task.params, true)
          task_count * 500
        )

  all: ->
    @tasks

  add: ( type, type_id, callback, params, to_not_show = false ) ->
    for key, task of @tasks
      if task.type is type && task.type_id is type_id
        console.log('STOP TASK, already exists', task)
        return key if to_not_show
        $('#content').empty()
        $('.content_permanent').hide()
        $('#content_permanent_' + key ).show()
        @tasks[key].worker.activate()
        for task_key, task of @tasks
          if task_key isnt key 
            task.active = false
          else
            task.active = true
        App.Event.trigger 'ui:rerender'
        @syncTasks()
        return key

    @task_count++
    if !to_not_show
      for task_key, task of @tasks
        task.active = false
    active = true
    if to_not_show
      active = false
    console.log('start...', type, type_id, callback, params, @task_count )
    if active
      $('#content').empty()

    $('#content_permanent').append('<div id="content_permanent_' + @task_count + '" class="content_permanent"></div>')

    if active
      $('.content_permanent').hide()
      $('#content_permanent_' + @task_count ).show()
    params_app = _.clone(params)
    params_app['el']       = $('#content_permanent_' + @task_count )
    params_app['task_key'] = @task_count
    a = new App[callback]( params_app )
    task = 
      type:     type
      type_id:  type_id
      params:   params
      callback: callback
      worker:   a
      active:   active
    @tasks[@task_count] = task
    App.Event.trigger 'ui:rerender'
    @syncTasks()

    @task_count

  remove: ( key ) =>
    if @tasks[key]
      @tasks[key].worker.release()
    delete @tasks[key]
    App.Event.trigger 'ui:rerender'
    @syncTasks()

  reset: =>
    @tasks = {}
    App.Event.trigger 'ui:rerender'

  syncTasks: =>
    store = []
    for task_key, task of @tasks
      item =
        type:     task.type
        type_id:  task.type_id
        params:   task.params
        callback: task.callback
        active:   task.active
      store.push item

    console.log('to write', store)
    App.Store.write( 'tasks', store )

