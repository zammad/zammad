class App.Session
  _instance = undefined

  @init: ->
    _instance ?= new _sessionSingleton
    _instance.clear()

  @get: ( key ) ->
    if _instance == undefined
      _instance ?= new _sessionSingleton
    _instance.get( key )

  @set: ( key, value ) ->
    if _instance == undefined
      _instance ?= new _sessionSingleton
    _instance.set( key, value )

  @all: ->
    if _instance == undefined
      _instance ?= new _sessionSingleton
    _instance.all()

class _sessionSingleton extends Spine.Module
  @include App.LogInclude

  constructor: ->
    @clear()

  clear: ->
    @data = {}

  get: ( key ) ->
    @log 'debug', key, @data[key]
    @data[key]

  set: ( key, value ) ->
    @log 'debug', 'set', key, value
    @data[key] = value

  all: ->
    @data
