class App.TaskManager
  _instance = undefined

  @init: (params = {}) ->
    if params.force
      _instance = new App.TaskManagerSingleton(params)
      return
    _instance ?= new App.TaskManagerSingleton(params)

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
      _instance ?= new App.TaskManagerSingleton
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

