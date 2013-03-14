class App.Delay
  _instance = undefined

  @set: ( callback, timeout, key, level ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.set( callback, timeout, key, level )

  @clear: ( key ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.clear( key )

  @clearLevel: ( level ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.clearLevel( level )

class _Singleton extends Spine.Module
  @include App.Log

  constructor: ->
    @levelStack = {}

  set: ( callback, timeout, key, level ) ->

    if !level
      level = '_all'

    if !@levelStack[level]
      @levelStack[level] = {}

    if key
      @clear( key )

    # setTimeout
    @log 'Delay', 'debug', 'set', key, timeout, level, callback
    call = =>
      @clear( key ) 
      callback()
    delay_id = setTimeout( call, timeout )

    # remember all delays
    @levelStack[ level ][ key ] = {
      delay_id: delay_id
      timeout:  timeout
      level:    level
    }

    return delay_id

  clear: ( key ) ->

    if !level
      level = '_all'

    if !@levelStack[ level ]
      @levelStack[ level ] = {}

    # get global delay ids
    data = @levelStack[ level ][ key ]
    return if !data

    @log 'Delay', 'debug', 'clear', data
    clearTimeout( data['delay_id'] )

  clearLevel: (level) ->
    return if !@levelStack[ level ]
    for key, data of @levelStack[ level ]
      @clear( key )
    @levelStack[level] = {}

