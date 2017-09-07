class App.QueueManager
  _instance = undefined

  @init: ->
    _instance ?= new _queueSingleton

  @add: (key, data) ->
    if _instance == undefined
      _instance ?= new _queueSingleton
    _instance.add(key, data)

  @pull: (key) ->
    if _instance == undefined
      _instance ?= new _queueSingleton
    _instance.pull(key)

  @all: (key) ->
    if _instance == undefined
      _instance ?= new _queueSingleton
    _instance.all(key)

  @run: (key, callback) ->
    if _instance == undefined
      _instance ?= new _queueSingleton
    _instance.run(key, callback)

class _queueSingleton
  constructor: ->
    @queues = {}
    @queueRunning = {}

  add: (key, data) ->
    if !@queues[key]
      @queues[key] = []
    @queues[key].push data
    true

  pull: (key) ->
    return if !@queues[key]
    @queues[key].shift()

  all: (key) ->
    @queues[key]

  run: (key, callback) ->
    return if !@queues[key]
    return if @queueRunning[key]
    localQueue = @queues[key]
    return if _.isEmpty(localQueue)
    @queueRunning[key] = true
    loop
      callback = localQueue.shift()
      callback()
      if !localQueue[0]
        @queueRunning[key] = false
        break
    true
