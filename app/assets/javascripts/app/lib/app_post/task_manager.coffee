class App.TaskManager
  _instance = undefined

  @init: (params) ->
    _instance ?= new _taskManagerSingleton(params)

  @all: ->
    _instance.all()

  @execute: (params) ->
    _instance.execute(params)

  @get: (key) ->
    _instance.get(key)

  @update: (key, params) ->
    _instance.update(key, params)

  @remove: (key, rerender = true) ->
    _instance.remove(key, rerender)

  @notify: (key) ->
    _instance.notify(key)

  @mute: (key) ->
    _instance.mute(key)

  @reorder: (order) ->
    _instance.reorder(order)

  @reset: ->
    _instance.reset()

  @worker: (key) ->
    _instance.worker(key)

  @nextTaskUrl: ->
    _instance.nextTaskUrl()

  @TaskbarId: ->
    _instance.TaskbarId()

  @renderDelay: ->
    _instance.renderDelay()

class _taskManagerSingleton extends App.Controller
  @include App.LogInclude

  constructor: (params = {}) ->
    super
    if params.el
      @el = params.el
    else
      @el = $('#app')
    @offlineModus = params.offlineModus
    @tasksInitial()

    # render on login
    App.Event.bind('auth:login', =>
      @tasksInitial()
      'task'
    )

    # render on logout
    App.Event.bind('auth:logout', =>
      @reset()
      'task'
    )

    # send updates to server
    App.Interval.set(@taskUpdateLoop, 2500, 'check_update_to_server_pending', 'task')

  init: ->
    @workers           = {}
    @workersStarted    = {}
    @tasksStarted      = {}
    @allTasks          = []
    @tasksToUpdate     = {}
    @activeTaskHistory = []

    # speed improvements for certain browsers
    @renderInitTime = 2200
    @renderDelayTime = 3400
    data = App.Browser.detection()
    if data.browser
      if data.browser.name is 'Chrome'
        @renderInitTime = 1000
        @renderDelayTime = 1600
      else if data.browser.anem is 'Firefox'
        @renderInitTime = 1200
        @renderDelayTime = 1800

  all: ->

    # sort by prio
    @allTasks = _(@allTasks).sortBy( (task) ->
      return task.prio
    )
    return @allTasks

  newPrio: ->
    prio = 1
    for task in @allTasks
      if task.prio && task.prio > prio
        prio = task.prio
    prio++
    prio

  # generate dom id for task
  domID: (key) ->
    "content_permanent_#{key}"

  worker: (key) ->
    return @workers[ key ] if @workers[ key ]
    return

  execute: (params) ->

    # input validation
    params.key = App.Utils.htmlAttributeCleanup(params.key)

    # in case an init execute arrives later but is aleady executed, ignore it
    if params.init && @tasksStarted[params.key]
      #console.log('IGNORE LATER INIT', params)
      return

    # remember started task / prevent to open task twice
    createNewTask = true
    if @tasksStarted[params.key]
      createNewTask = false
    @tasksStarted[params.key] = true

    # if we have init task startups, let the controller know this
    if params.init
      params.params.init = true

    # modify shown param for controller
    if params.params
      if !params.show
        delete params.params.shown
      else
        params.params.shown = true

    # remember latest active controller
    if params.show
      @activeTaskHistory.push _.clone(params)

    # check if task already exists in storage / e. g. from last session
    task = @get(params.key)

    #console.log 'debug', 'execute', params, 'task', task

    # create new online task if not exists and if not persistent
    if !task && createNewTask && !params.persistent
      #console.log 'debug', 'add, create new taskbar in backend'
      task = new App.Taskbar
      task.load(
        key:      params.key
        params:   params.params
        callback: params.controller
        client_id: 123
        prio:     @newPrio()
        notify:   false
        active:   params.show
      )
      @allTasks.push task.attributes()

      # save new task and update task collection
      ui = @
      task.save(
        done: ->
          for taskPosition of ui.allTasks
            if ui.allTasks[taskPosition] && ui.allTasks[taskPosition]['key'] is @key
              task = @attributes()
              ui.allTasks[taskPosition] = task
      )

    # empty static content if task is shown
    if params.show
      @el.find('#content').empty()

      # hide all tasks
      @el.find('.content').addClass('hide').removeClass('active')

    # create div for task if not exists
    if !@el.find("##{@domID(params.key)}")[0]
      @el.append("<div id=\"#{@domID(params.key)}\" class=\"content horizontal flex\"></div>")

    # set all tasks to active false, only new/selected one to active
    if params.show
      for task in @allTasks
        if task.key isnt params.key
          if task.active
            task.active = false
            @taskUpdate(task, true)
        else
          changed = false
          if !task.active
            changed = true
            task.active = true
          if task.notify
            changed = true
            task.notify = false
          if changed
            @taskUpdate(task, true)

    # start worker for task if not exists
    @startController(params)

    # set active state
    if !params.init
      $('.nav-tab.task').each( (_index, element) =>
        localElement = $(element)
        key = localElement.data('key')
        return if !key
        task = @get(key)
        return if !task
        if task.active
          localElement.addClass('is-active')
        else
          localElement.removeClass('is-active')
      )

  startController: (params) =>

    #console.log 'debug', 'controller start try...', params

    # create clean params
    params_app             = _.clone(params.params)
    params_app['el']       = $("##{@domID(params.key)}")
    params_app['task_key'] = params.key
    if !params.show
      params_app['doNotLog'] = 1

    # start controller if not already started
    if !@workersStarted[params.key]
      @workersStarted[params.key] = true

      # create new controller instanz
      @workers[params.key] = new App[params.controller](params_app)

    # if controller is started hidden, call hide of controller
    if !params.show
      @hide(params.key)

    # hide all other controller / show current controller
    else
      @showControllerHideOthers(params.key, params_app)

  showControllerHideOthers: (thisKey, params_app) =>
    for key of @workersStarted
      if key is thisKey
        @show(key, params_app)
      else
        @hide(key)

  # show task content
  show: (key, params_app) ->
    @el.find("##{@domID(key)}").removeClass('hide').addClass('active')

    controller = @workers[ key ]
    return false if !controller

    # set controller state to active
    if controller.active && _.isFunction(controller.active)
      controller.active(true)

    # execute controllers show
    if controller.show && _.isFunction(controller.show)
      controller.show(params_app)

    # update title
    if controller.meta && _.isFunction(controller.meta)
      meta = controller.meta()
      @title meta.title

    true

  # hide task content
  hide: (key) ->
    @el.find("##{@domID(key)}").addClass('hide').removeClass('active')

    controller = @workers[ key ]
    return false if !controller

    # set controller state to active
    if controller.active && _.isFunction(controller.active)
      controller.active(false)

    # execute controllers hide
    if controller.hide && _.isFunction(controller.hide)
      controller.hide()

    true

  # get task
  get: (key) =>
    for task in @allTasks
      if task.key is key
        return task

  # update task
  update: (key, params) =>
    task = @get(key)
    if !task
      throw "No such task with '#{key}' to update"
    for item, value of params
      task[item] = value

    # mute rerender on state attribute updates
    mute = false
    if Object.keys(params).length is 1 && params.state
      mute = true
    @taskUpdate(task, mute)

  # remove task certain task from tasks
  remove: (key, rerender) =>

    # remember started task
    delete @tasksStarted[key]

    task = @get(key)
    return if !task

    # update @allTasks
    allTasks = _.filter(
      @allTasks
      (taskLocal) ->
        return task if task.key isnt taskLocal.key
        return
    )
    @allTasks = allTasks || []

    # release task from dom and destroy controller
    @release(key)

    # rerender taskbar
    if rerender
      @metaTaskUpdate()

    # destroy in backend storage
    @taskDestroy(task)

  # set notify of task
  notify: (key) =>
    task = @get(key)
    if !task
      throw "No such task with '#{key}' to notify"
    return if task.notify
    task.notify = true
    @taskUpdate(task)

  # unset notify of task
  mute: (key) =>
    task = @get(key)
    if !task
      throw "No such task with '#{key}' to mute"
    return if !task.notify
    task.notify = false
    @taskUpdate(task)

  # set new order of tasks (needed for dnd)
  reorder: (order) =>
    prio = 0
    for key in order
      task = @get(key)
      if !task
        throw "No such task with '#{key}' of order"
      prio++
      if task.prio isnt prio
        task.prio = prio
        @taskUpdate(task, true)

  # release one task
  release: (key) =>
    try
      @el.find("##{@domID(key)}").html('')
      @el.find("##{@domID(key)}").remove()
    catch
      @log 'notice', "invalid key '#{key}'"

    delete @workersStarted[ key ]
    delete @workers[ key ]
    delete @tasksStarted[ key ]

  # reset while tasks
  reset: =>

    # release touch tasks
    for task in @allTasks
      @release(key)

    # release persistent tasks
    for key, controller of @workers
      @release(key)

    # clear instance vars
    @init()

    # clear in mem tasks
    App.Taskbar.deleteAll()

    # rerender task bar
    @metaTaskUpdate()

  nextTaskUrl: =>

    # activate latest controller based on history
    loop
      controllerParams = @activeTaskHistory.pop()
      break if !controllerParams
      break if !controllerParams.key
      controller = @workers[ controllerParams.key ]
      if controller && controller.url
        return controller.url()

    # activate latest controller with highest prio
    tasks = @all()
    taskNext = tasks[tasks.length-1]
    if taskNext
      controller = @workers[ taskNext.key ]
      if controller && controller.url
        return controller.url()

    false

  TaskbarId: =>
    if !@TaskbarIdInt
      @TaskbarIdInt = Math.floor( Math.random() * 99999999 )
    @TaskbarIdInt

  taskUpdate: (task, mute = false) ->
    @log 'debug', 'UPDATE task', task, mute
    @tasksToUpdate[ task.key ] = 'toUpdate'
    if !mute
      @metaTaskUpdate()

  taskUpdateLoop: =>
    return if @offlineModus
    for key of @tasksToUpdate
      continue if !key
      task = @get(key)
      continue if !task
      if @tasksToUpdate[ task.key ] is 'toUpdate'
        @tasksToUpdate[ task.key ] = 'inProgress'
        taskUpdate = new App.Taskbar
        taskUpdate.load(task)
        if taskUpdate.isOnline()
          ui = @
          taskUpdate.save(
            done: ->
              if ui.tasksToUpdate[ @key ] is 'inProgress'
                delete ui.tasksToUpdate[ @key ]
            fail: ->
              ui.log 'error', "can't update task", @
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

    # if task isnt already stored on backend
    return if !task.id
    App.Taskbar.destroy(task.id)

  tasksInitial: =>
    @init()

    # set taskbar collection stored in database
    tasks = App.Taskbar.all()
    for task in tasks
      @allTasks.push task.attributes()

    # reopen tasks
    App.Event.trigger 'taskbar:init'

    # initial load of permanent tasks
    authentication = App.Session.get('id')
    permanentTask  = App.Config.get('permanentTask')
    task_count     = 0
    if permanentTask
      for key, config of permanentTask
        if !config.authentication || (config.authentication && authentication)
          task_count += 1
          do (key, config, task_count) =>
            App.Delay.set(
              =>
                @execute(
                  key:        key
                  controller: config.controller
                  params:     {}
                  show:       false
                  persistent: true
                  init:       true
                )
              task_count * 450
              undefined
              'task'
            )

    # initial load of taskbar collection
    for task in @allTasks
      task_count += 1
      do (task, task_count) =>
        App.Delay.set(
          =>
            @execute(
              key:        task.key
              controller: task.callback
              params:     task.params
              show:       false
              persistent: false
              init:       true
            )
          task_count * 850
          undefined
          'task'
        )

    # handle init task rendering at loading time, prevent multible, not needed dom operations
    @initTaskRenderInterval = App.Interval.set(
      ->
        App.Event.trigger('task:render')
      @renderInitTime
    )
    App.Delay.set(
      =>
        App.Interval.clear(@initTaskRenderInterval)
        @renderDelayTime = 20
        App.Event.trigger('task:render')
      task_count * 950
    )

    App.Event.trigger 'taskbar:ready'

  renderDelay: =>
    @renderDelayTime
