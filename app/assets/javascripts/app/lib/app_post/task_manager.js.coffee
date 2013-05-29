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

  @reset: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.reset()

  @syncInitial: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.syncTasksInitial()

  @syncSave: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.syncSave()

  @sync: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.syncTasks()

class _Singleton extends App.Controller
  @include App.Log

  constructor: ->
    @tasks      = {}
    @task_count = 0
    @syncTasksInitial()

  all: ->
    @tasks

  add: ( type, type_id, callback, params, to_not_show = false, state ) ->
    for key, task of @tasks
      if task.type is type && task.type_id is type_id
        return key if to_not_show
        $('#content').empty()
        $('.content_permanent').hide()
        $('.content_permanent').removeClass('active')
        $('#content_permanent_' + key ).show()
        $('#content_permanent_' + key ).addClass('active')
        @tasks[key].worker.activate()
        @tasks[key].notify = false
        for task_key, task of @tasks
          if task_key isnt key 
            task.active = false
          else
            task.active = true
        App.Event.trigger 'ui:rerender'
        App.Event.trigger 'ui:rerender:content'
        return key

    @task_count++
    if !to_not_show
      for task_key, task of @tasks
        task.active = false
    active = true
    if to_not_show
      active = false
    if active
      $('#content').empty()

    $('#content_permanent').append('<div id="content_permanent_' + @task_count + '" class="content_permanent"></div>')

    if active
      $('.content_permanent').hide()
      $('.content_permanent').removeClass('active')
      $('#content_permanent_' + @task_count ).show()
      $('#content_permanent_' + @task_count ).addClass('active')
    else
      $('#content_permanent_' + @task_count ).removeClass('active')
      $('#content_permanent_' + @task_count ).hide()

    # create new controller instanz
    params_app = _.clone(params)
    params_app['el']       = $('#content_permanent_' + @task_count )
    params_app['task_key'] = @task_count

    # check if we have old state there
    if !state
      oldTask = @get_by_type( type, type_id )
      if oldTask
        state = oldTask.state
    params_app['form_state'] = state
    if to_not_show
      params_app['doNotLog'] = 1
    a = new App[callback]( params_app )

    # remember new controller / prepare for task storage
    task = 
      type:     type
      type_id:  type_id
      params:   params
      callback: callback
      worker:   a
      active:   active
    @tasks[@task_count] = task

    # activate controller
    if !to_not_show
      a.activate()

    App.Event.trigger 'ui:rerender'

    # add new controller to task storage
    if !to_not_show
      @syncAdd(task)

    @task_count

  get: ( key ) =>
    return @tasks[key]

  update: ( key, params ) =>
    return false if !@tasks[key]
    for item, value of params
      @tasks[key][item] = value
    @syncSave()

  remove: ( key, to_not_show = false ) =>
    if @tasks[key]
      @tasks[key].worker.release()
    if !to_not_show
      @syncRemove( @tasks[key] )
    delete @tasks[key]
    App.Event.trigger 'ui:rerender'

  notify: ( key ) =>
    @tasks[key].notify = true

  reset: =>
    @tasks = {}
    App.Event.trigger 'ui:rerender'

  get_by_type: (type, type_id) =>
    store = @syncLoad() || []
    for item in store
      return item if item.type is type && item.type_id is type_id

  syncAdd: (task) =>
    store = @syncLoad() || []
    for item in store
      return if item.type is task.type && item.type_id is task.type_id
    item =
      type:     task.type
      type_id:  task.type_id
      params:   task.params
      callback: task.callback
    store.push item
    App.Store.write( 'tasks', store )

  syncRemove: (task) =>
    store    = @syncLoad() || []
    storeNew = []
    for item in store
      if item.type isnt task.type || item.type_id isnt task.type_id
        storeNew.push item
    App.Store.write( 'tasks', storeNew )

  syncSave: =>
    store    = @syncLoad() || []
    storeNew = []
    for item in store
      for key, task of @tasks
        if task.type is item.type && task.type_id is item.type_id
          console.log('MATCH', item)
          if @tasks[key]['state']
            item['state'] = @tasks[key]['state']
          storeNew.push item
#      if @tasks[key]
#       @tasks[key].worker.release()
#     
#      storeNew.push item
#    item =
#      type:     task.type
#      type_id:  task.type_id
#      params:   task.params
#      callback: task.callback
    App.Store.write( 'tasks', storeNew )

  syncLoad: =>
    App.Store.get( 'tasks' )

  syncTasksInitial: =>
    # reopen tasks
    store = _.clone(@syncLoad())
    return if !store
    task_count = 0
    for task in store
      task_count += 1
      @delay(
        =>
          task = store.shift()
          @add(task.type, task.type_id, task.callback, task.params, true, task.state)
        task_count * 500
      )

  syncTasks: =>
    store = @syncLoad() || []

    # open tasks
    for item in store
      existsLocal = false
      for task_key, task of @tasks
        if item.type is task.type && item.type_id is task.type_id
          # also open here
          existsLocal = true
      if !existsLocal
         @add(item.type, item.type_id, item.callback, item.params, true)

    # close tasks
    for task_key, task of @tasks
      onlyLocal = true
      for item in store
        if item.type is task.type && item.type_id is task.type_id
          onlyLocal = false
      if onlyLocal
        @remove( task_key, true )
