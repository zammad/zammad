class App.Config
  _instance = undefined

  @init: ->
    _instance ?= new _Singleton

  @get: ( key, group ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.get( key, group )

  @set: ( key, value, group ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.set( key, value, group )

  @_all: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance._all()

class _Singleton
  constructor: ->
    @config = {}

  get: ( key, group ) ->
    if group
      return undefined if !group of @config
      return @config[group][key]
    return @config[key]

  set: ( key, value, group ) ->
    if group
      if !@config[group]
        @config[group] = {}
      @config[group][key] = value
    else
      @config[key] = value

  _all: ->
    @config
