class App.Delay
  _instance = undefined

  @set: (callback, timeout, key, level, queue) ->
    if _instance == undefined
      _instance ?= new _delaySingleton
    _instance.set(callback, timeout, key, level, queue)

  @clear: (key, level) ->
    if _instance == undefined
      _instance ?= new _delaySingleton
    _instance.clear(key, level)

  @clearLevel: (level) ->
    if _instance == undefined
      _instance ?= new _delaySingleton
    _instance.clearLevel(level)

  @reset: ->
    if _instance == undefined
      _instance ?= new _delaySingleton
    _instance.reset()

  @count: ->
    if _instance == undefined
      _instance ?= new _intervalSingleton
    _instance.count()

  @_all: ->
    if _instance == undefined
      _instance ?= new _delaySingleton
    _instance._all()

class _delaySingleton extends Spine.Module
  @include App.LogInclude

  constructor: ->
    @levelStack = {}

  set: (callback, timeout, key, level, queue) =>

    if !level
      level = '_all'

    if key
      @clear(key, level)

    if !key
      key = Math.floor(Math.random() * 99999)

    # setTimeout
    @log 'debug', 'set', key, timeout, level, callback, queue
    localCallback = =>
      @clear(key, level)
      if queue
        App.QueueManager.add('delay', callback)
        App.QueueManager.run('delay')
      else
        callback()
    delay_id = setTimeout(localCallback, timeout)

    # remember all delays
    if !@levelStack[level]
      @levelStack[level] = {}
    @levelStack[ level ][ key.toString() ] = {
      delay_id: delay_id
      timeout:  timeout
      level:    level
    }

    key.toString()

  clear: (key, level) =>

    if !level
      level = '_all'

    return if !@levelStack[ level ]

    # get global delay ids
    data = @levelStack[ level ][ key.toString() ]
    return if !data

    @log 'debug', 'clear', data
    clearTimeout(data['delay_id'])

    # cleanup if needed
    delete @levelStack[ level ][ key.toString() ]
    if _.isEmpty(@levelStack[ level ])
      delete @levelStack[ level ]

  clearLevel: (level) =>
    return if !@levelStack[ level ]
    for key, data of @levelStack[ level ]
      @clear(key, level)
    delete @levelStack[level]

  reset: =>
    for level, items of @levelStack
      for key, data of items
        @clear(key, level)
      @levelStack[level] = {}
    true

  count: =>
    return 0 if !@levelStack
    count = 0
    for levelName, levelValue of @levelStack
      count += Object.keys(levelValue).length
    count

  _all: =>
    @levelStack

