class App.TaskManager
  _instance = undefined

  @init: ->
    _instance ?= new _Singleton

  @all: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.all()

  @add: ( type, type_id, callback, params ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.add( type, type_id, callback, params )

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

  all: ->
    @tasks

  add: ( type, type_id, callback, params ) ->
    for key, task of @tasks
      if task.type is type && task.type_id is type_id
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
        return key

    @task_count++
    for task_key, task of @tasks
      task.active = false

    $('#content').empty()
    $('#content_permanent').append('<div id="content_permanent_' + @task_count + '" class="content_permanent"></div>')
    $('.content_permanent').hide()
    $('#content_permanent_' + @task_count ).show()
    params['el'] = $('#content_permanent_' + @task_count )
    a = new callback( params )
    task = 
      type:    type
      type_id: type_id
      params:  params
      worker:  a
      active:  true
    @tasks[@task_count] = task
    App.Event.trigger 'ui:rerender'

    @task_count

  remove: ( key ) =>
    if @tasks[key]
      @tasks[key].worker.release()
    delete @tasks[key]
    App.Event.trigger 'ui:rerender'

  reset: =>
    @tasks = {}
    App.Event.trigger 'ui:rerender'

