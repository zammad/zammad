class App.Session
  _instance = undefined

  @init: ->
    _instance ?= new _Singleton
    _instance.clear()

  @get: ( key ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.get( key )

  @set: ( key, value ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.set( key, value )

  @all: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.all()

class _Singleton extends Spine.Module
  @include App.Log

  constructor: ->
    @clear()

  clear: ->
    @data = {}

  get: ( key ) ->
    @log 'Session', 'debug', key, @data[key]
    return @data[key]

  set: ( key, value ) ->
    @log 'Session', 'debug', 'set', key, value
    @data[key] = value

  all: ->
    @data
