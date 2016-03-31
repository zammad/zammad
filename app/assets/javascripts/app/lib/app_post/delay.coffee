class App.Delay
  _instance = undefined

  @set: (callback, timeout, key, level) ->
    if _instance == undefined
      _instance ?= new _delaySingleton
    _instance.set(callback, timeout, key, level)

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

  @_all: ->
    if _instance == undefined
      _instance ?= new _delaySingleton
    _instance._all()

class _delaySingleton extends Spine.Module
  @include App.LogInclude

  constructor: ->
    @levelStack = {}

  set: (callback, timeout, key, level) =>

    if !level
      level = '_all'

    if key
      @clear(key, level)

    if !key
      key = Math.floor(Math.random() * 99999)

    # setTimeout
    @log 'debug', 'set', key, timeout, level, callback
    call = =>
      @clear(key, level)
      callback()
    delay_id = setTimeout(call, timeout)

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

  _all: =>
    @levelStack

