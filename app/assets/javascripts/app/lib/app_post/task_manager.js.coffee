class App.TaskManager
  _instance = undefined

  @init: ->
    _instance ?= new _Singleton

  @all: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.all()

  @add: ( type, type_id, params ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.add( type, type_id, params )

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

  add: ( type, type_id, params ) ->
    for key, task of @tasks
      if task.type is type && task.type_id is type_id
        $('#content').empty()
        $('.content_permanent').hide()
        $('#content_permanent_' + key ).show()
        return key

    @task_count++

    $('#content').empty()
    $('#content_permanent').append('<div id="content_permanent_' + @task_count + '" class="content_permanent"></div>')
    $('.content_permanent').hide()
    $('#content_permanent_' + @task_count ).show()
    a = new params.callback( el: $('#content_permanent_' + @task_count ), ticket_id: type_id )
    task = 
      type:    type
      type_id: type_id
      params:  params
      worker:  a
    @tasks[@task_count] = task
    App.Event.trigger 'ui:rerender'

    @task_count

  remove: ( key ) =>
    if @tasks[key]
      console.log('rrrelease', @tasks[key], @tasks[key].worker)
      @tasks[key].worker.release()
    delete @tasks[key]
    App.Event.trigger 'ui:rerender'

  reset: =>
    @tasks = {}
    App.Event.trigger 'ui:rerender'

