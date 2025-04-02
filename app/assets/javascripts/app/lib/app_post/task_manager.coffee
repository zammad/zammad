class App.TaskManager
  _instance = undefined

  @init: (params = {}) ->
    if params.force
      _instance = new _taskManagerSingleton(params)
      return
    _instance ?= new _taskManagerSingleton(params)

  @all: ->
    return [] if !_instance
    _instance.all()

  @allWithMeta: ->
    return [] if !_instance
    _instance.allWithMeta()

  @execute: (params) ->
    return if !_instance
    _instance.execute(params)

  @get: (key) ->
    return if !_instance
    _instance.get(key)

  @update: (key, params) ->
    return if !_instance
    _instance.update(key, params)

  @remove: (key) ->
    return if !_instance
    _instance.remove(key)

  @notify: (key) ->
    return if !_instance
    _instance.notify(key)

  @mute: (key) ->
    return if !_instance
    _instance.mute(key)

  @reorder: (order) ->
    return if !_instance
    _instance.reorder(order)

  @touch: (key) ->
    return if !_instance
    _instance.touch(key)

  @reset: ->
    return if !_instance
    _instance.reset()

  @tasksInitial: ->
    if _instance == undefined
      _instance ?= new _taskManagerSingleton
    _instance.tasksInitial()

  @worker: (key) ->
    return if !_instance
    _instance.worker(key)

  @ensureWorker: (key, callback) ->
    return if !_instance
    _instance.ensureWorker(key, callback)

  @nextTaskUrl: ->
    return if !_instance
    _instance.nextTaskUrl()

  @TaskbarId: ->
    return if !_instance
    _instance.TaskbarId()

  @hideAll: ->
    return if !_instance
    _instance.showControllerHideOthers()

  @preferencesSubscribe: (key, callback) ->
    return if !_instance
    _instance.preferencesSubscribe(key, callback)

  @preferencesUnsubscribe: (id) ->
    return if !_instance
    _instance.preferencesUnsubscribe(id)

  @preferencesTrigger: (key) ->
    return if !_instance
    _instance.preferencesTrigger(key)

  @tasksAutoCleanupDelayTime: (key) ->
    return if !_instance
    if !key
      return _instance.tasksAutoCleanupDelayTime
    _instance.tasksAutoCleanupDelayTime = key

class _taskManagerSingleton extends App.Controller
  @extend App.PopoverProvidable
  @include App.LogInclude

  constructor: (params = {}) ->
    super
    if params.el
      @el = params.el
    else
      @el = $('#app')
    @offlineModus = params.offlineModus
    @tasksInitial()

    @controllerBind('taskbar:preferences', (data) =>
      @tasksPreferences[data.key] = data.preferences
      @preferencesTrigger(data.key)
    )

  init: ->
    @domStore                  = {}
    @shownStore                = {}
    @workers                   = {}
    @allTasksByKey             = {}
    @tasksToUpdate             = {}
    @tasksPreferences          = {}
    @tasksPreferencesCallbacks = {}
    @tasksAutoCleanupDelayTime = 12000
    @activeTaskHistory         = []
    @queue                     = []
    @queueRunning              = false

  all: ->

    # sort by prio
    byPrios = []
    for key, task of @allTasksByKey
      byPrios.push task
    _.sortBy(byPrios, (task) ->
      return task.prio
    )

  allWithMeta: ->
    all = @all()
    for task in all
      task = @getMeta(task)
    all

  getMeta: (task) ->

    # collect meta data of task for task bar item
    meta =
      url:       '#'
      id:        false
      iconClass: 'loading'
      title:     App.i18n.translateInline('Loading…')
      head:      App.i18n.translateInline('Loading…')
    worker = App.TaskManager.worker(task.key)
    if worker && worker.meta
      data = worker.meta(task)

      # apply meta data of controller
      if data
        for key, value of data
          meta[key] = value

    task.meta = meta
    task

  newPrio: ->
    prio = 1
    for task in @all()
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

  ensureWorker: (key, callback) =>
    if worker = @worker(key)
      callback(worker)
      return

    @one "TaskManager::#{key}::WorkerStarted", =>
      @ensureWorker(key, callback)
      true

  execute: (params) ->
    @queue.push params
    @run()

  run: ->
    return if !@queue[0]
    return if @queueRunning
    @queueRunning = true
    loop
      param = @queue.shift()
      try
        @executeSingel(param)
      catch e
        @log 'error', 'executeSingel task:', param.key, e
      if !@queue[0]
        @queueRunning = false
        break

  executeSingel: (params) ->

    # input validation
    params.key = App.Utils.htmlAttributeCleanup(params.key)

    # in case an init execute arrives later but is aleady executed, ignore it
    if params.init && @workers[params.key]
      return

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

    # create new online task if not exists and if not persistent
    if !task && !@workers[params.key] && !params.persistent
      task = new App.Taskbar
      task.load(
        key:       params.key
        params:    params.params
        callback:  params.controller
        prio:      @newPrio()
        notify:    false
        active:    params.show
      )
      @allTasksByKey[params.key] = task.attributes()

      @touch(params.key)

      # save new task and update task collection
      ui = @
      @tasksToUpdate[params.key] = 'inCreate'
      task.save(
        done: ->
          if ui.tasksToUpdate[params.key] is 'inCreate'
            delete ui.tasksToUpdate[params.key]
          ui.allTasksByKey[params.key] = @attributes()
          ui.tasksPreferences[params.key] = clone(@preferences)
          ui.preferencesTrigger(params.key)
          for taskPosition of ui.allTasks
            if ui.allTasks[taskPosition] && ui.allTasks[taskPosition]['key'] is @key
              task = @attributes()
              ui.allTasks[taskPosition] = task
        fail: ->
          if ui.tasksToUpdate[params.key] is 'inCreate'
            delete ui.tasksToUpdate[params.key]
      )

    # empty static content if task is shown
    if params.show
      @$('#content').remove()

    # set all tasks to active false, only new/selected one to active
    if params.show
      for key, task of @allTasksByKey
        if key isnt params.key
          if task.active
            task.active = false
            @taskUpdate(task)
        else
          changed = false
          if !task.active
            changed = true
            task.active = true
          if task.notify
            changed = true
            task.notify = false
          if changed
            @taskUpdate(task)

    # start worker for task if not exists
    @startController(params)

  startController: (params) =>
    @log 'debug', 'controller start try...', params

    # create clean params
    params_app = _.clone(params.params)
    domKey = @domID(params.key)
    domStoreItem = @domStore[domKey]
    if domStoreItem
      el = domStoreItem.el
    else
      el = $("<div id=\"#{domKey}\" class=\"content horizontal flex\"></div>")
      @domStore[domKey] = { el: el }
    params_app['el'] = el
    params_app['appEl'] = @el
    params_app['taskKey'] = params.key
    if !params.show
      params_app['doNotLog'] = 1

    # start controller if not already started
    if !@workers[params.key]
      @workers[params.key] = new App[params.controller](params_app)
      App.Event.trigger "TaskManager::#{params.key}::WorkerStarted"

    # if controller is started hidden, call hide of controller
    if !params.show
      @hide(params.key)

    # hide all other controller / show current controller
    else
      @showControllerHideOthers(params.key, params_app)

    @tasksAutoCleanupDelay()

  showControllerHideOthers: (thisKey, params_app) =>
    for key of @workers
      if key isnt thisKey
        if @shownStore[key] isnt false
          @hide(key)
    @$('#content').addClass('hide')

    for key of @workers
      if key is thisKey
        @show(key, params_app)

  # show task content
  show: (key, params_app) =>
    controller = @workers[key]
    @shownStore[key] = true

    @preferencesTrigger(key)

    domKey = @domID(key)
    domStoreItem = @domStore[domKey]
    if !@$("##{domKey}").get(0) && domStoreItem && domStoreItem.el

      # update shown times
      @frontendTimeUpdateElement(domStoreItem.el)

      # append to dom
      @el.append(domStoreItem.el)
      @$("##{domKey}").removeClass('hide').addClass('active')

      if controller

        # set position of view
        if domStoreItem.position
          controller.setPosition(domStoreItem.position)

    else
      @$("##{domKey}").removeClass('hide').addClass('active')

    if controller

      # set controller state to active
      if controller.active && _.isFunction(controller.active)
        controller.active(true)

      # execute controllers show
      if controller.show && _.isFunction(controller.show)
        controller.show(params_app)

    true

  # hide task content
  hide: (key) =>
    controller = @workers[key]
    @shownStore[key] = false

    element = @$("##{@domID(key)}")
    if element.get(0)
      domKey = @domID(key)
      domStoreItem = @domStore[domKey]

      if controller && _.isFunction(controller.currentPosition)
        position = controller.currentPosition()
        domStoreItem.position = position
        element.addClass('hide').removeClass('active')
        domStoreItem.el = element.detach()
      else
        element.addClass('hide').removeClass('active')

    return false if !controller

    # set controller state to active
    if controller.active && _.isFunction(controller.active)
      controller.active(false)

    # execute controllers hide
    if controller.hide && _.isFunction(controller.hide)
      controller.hide()

    @delayedRemoveAnyPopover()

    true

  # get task
  get: (key) =>
    @allTasksByKey[key]

  # get task
  getWithMeta: (key) =>
    task = @get(key)
    return if !task
    @getMeta(task)

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
  remove: (key) =>
    task = @allTasksByKey[key]
    delete @allTasksByKey[key]
    return if !task

    # rerender taskbar
    App.Event.trigger('taskRemove', [task])

    # destroy in backend storage
    @taskDestroy(task)

    # release task from dom and destroy controller
    @release(key)

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
    App.Event.trigger('taskCollectionOrderSet', order)

  # release one task
  release: (key) =>
    domKey = @domID(key)
    localDomStore = @domStore[domKey]
    if localDomStore
      if localDomStore.el
        $('#app').append("<div id=\"#{domKey}_trash\" class=\"hide\"></div>")
        $("#app ##{domKey}_trash").append(localDomStore.el).remove()
        localDomStore.el = undefined
      localDomStore = undefined
    delete @domStore[@domID(key)]
    worker = @workers[key]
    if worker
      worker = undefined
    delete @workers[key]
    delete @tasksPreferences[key]
    try
      element = @$("##{@domID(key)}")
      element.html('')
      element.remove()
    catch
      @log 'notice', "invalid key '#{key}'"

  # reset while tasks
  reset: =>
    # clear loading tasks
    App.Delay.clearLevel('task')

    # release touch tasks
    for key, task of @allTasksByKey
      @release(key)

    # release persistent tasks
    for key, controller of @workers
      @release(key)

    # clear instance vars
    @init()

    # clear in mem tasks
    App.Taskbar.deleteAll()

    # rerender task bar
    App.Event.trigger('taskInit')

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
    return if @tasksToUpdate[task.key] is 'inCreate'
    @tasksToUpdate[task.key] = 'toUpdate'
    @taskUpdateTrigger()
    return if mute
    @touch(task.key)

  touch: (key) ->
    delay = =>
      task = @getWithMeta(key)
      return if !task
      #  throw "No such task with '#{key}' to touch"

      # update title
      if task.active && task.meta
        @title task.meta.title

      App.Event.trigger('taskUpdate', [task])
    App.Delay.set(delay, 20, "task-#{key}", undefined)

  taskUpdateTrigger: =>

    # send updates to server
    App.Delay.set(@taskUpdateLoop, 2000, 'check_update_to_server_pending', 'task', true)

  taskUpdateLoop: =>
    return if @offlineModus
    for key of @tasksToUpdate
      continue if !key
      task = @get(key)
      continue if !task
      if @tasksToUpdate[task.key] is 'toUpdate'
        @tasksToUpdate[task.key] = 'inProgress'
        taskUpdate = App.Taskbar.findByAttribute('key', task.key)
        if !taskUpdate
          delete ui.tasksToUpdate[@key]
          continue
        taskUpdate.load(task)
        if taskUpdate.isOnline()
          ui = @
          taskUpdate.save(
            done: ->
              if ui.tasksToUpdate[@key] is 'inProgress'
                delete ui.tasksToUpdate[@key]
            fail: ->
              ui.log 'error', "can't update task", @
              if ui.tasksToUpdate[@key] is 'inProgress'
                delete ui.tasksToUpdate[@key]
          )

  taskDestroy: (task) ->

    # check if update is still in process
    if @tasksToUpdate[task.key] is 'inProgress' || @tasksToUpdate[task.key] is 'inCreate'
      App.Delay.set(
        => @taskDestroy(task)
        800
        undefined
        'task'
        true
      )
      return

    # destroy task in backend
    delete @tasksToUpdate[task.key]
    delete @tasksPreferences[task.key]

    # if task isnt already stored on backend
    return if !task.id
    return if !App.Taskbar.exists(task.id)
    App.Taskbar.destroy(task.id)

  tasksAutoCleanupDelay: =>
    delay = =>
      @tasksAutoCleanup()
    App.Delay.set(delay, @tasksAutoCleanupDelayTime, 'task-autocleanup', undefined, true)

  tasksAutoCleanup: =>
    maxTaskCount = App.Config.get('ui_task_mananger_max_task_count')

    # auto cleanup of old tasks
    currentTaskCount = =>
      Object.keys(@allTasksByKey).length

    if currentTaskCount() > maxTaskCount
      if @offlineModus
        tasks = @all()
      else
        tasks = App.Taskbar.search(sortBy:'updated_at', order:'ASC')
      for task in tasks
        if currentTaskCount() > maxTaskCount
          if !task.active
            worker = App.TaskManager.worker(task.key)
            if worker
              if worker.changed && worker.changed()
                continue
              @log 'notice', "More than the allowed maximum #{maxTaskCount} tasks are open, closing the oldest untouched task #{task.key} now."
              @remove(task.key)

  tasksInitial: =>
    @init()

    isCustomer = App.Session.get().permission('ticket.customer') && !App.Session.get().permission('ticket.agent')

    # set taskbar collection stored in database
    tasks = App.Taskbar.all()
    for task in tasks
      continue if task.callback is 'TicketCreate' && isCustomer

      task.active = false
      @allTasksByKey[task.key] = task.attributes()
      @tasksPreferences[task.key] = task.preferences

    # reopen tasks
    App.Event.trigger 'taskbar:init'

    # initial load of permanent tasks
    permanentTask  = App.Config.get('permanentTask')
    taskCount     = 0
    if permanentTask
      for key, config of permanentTask
        if !config.permission || @permissionCheck(config.permission)
          taskCount += 1
          do (key, config, taskCount) =>
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
              taskCount * 50
              undefined
              'task'
              true
            )

    # initial load of taskbar collection
    for key, task of @allTasksByKey
      continue if task.callback is 'TicketCreate' && isCustomer

      taskCount += 1
      do (task, taskCount) =>
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
          taskCount * 50
          undefined
          'task'
          true
        )

    App.Event.trigger 'taskbar:ready'

  preferencesSubscribe: (key, callback) =>
    if !@tasksPreferencesCallbacks[key]
      @tasksPreferencesCallbacks[key] = {}
    subscribeId = "#{key}#{Math.floor(Math.random() * 999999)}"
    @tasksPreferencesCallbacks[key][subscribeId] = callback
    subscribeId

  preferencesUnsubscribe: (id) =>
    return if !@tasksPreferencesCallbacks
    for key, value of @tasksPreferencesCallbacks
      for subscribeId, callback of value
        if subscribeId == id
          delete value[subscribeId]
    for key, value of @tasksPreferencesCallbacks
      if _.isEmpty(value)
        delete @tasksPreferencesCallbacks[key]

  preferencesTrigger: (key) =>
    return if !@tasksPreferencesCallbacks[key]
    return if !@tasksPreferences[key]
    for subscribeId, callback of @tasksPreferencesCallbacks[key]
      callback(@tasksPreferences[key])
