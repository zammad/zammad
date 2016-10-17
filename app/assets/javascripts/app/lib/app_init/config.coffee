class App.Config
  _instance = undefined

  @init: ->
    _instance ?= new _configSingleton

  @get: (key, group) ->
    if _instance == undefined
      _instance ?= new _configSingleton
    _instance.get(key, group)

  @set: (key, value, group) ->
    if _instance == undefined
      _instance ?= new _configSingleton
    _instance.set(key, value, group)

  @all: ->
    if _instance == undefined
      _instance ?= new _configSingleton
    _instance.all()

class _configSingleton
  constructor: ->
    @config = {}

  get: (key, group) ->
    if group
      return undefined if !group of @config
      return undefined if @config[group] is undefined
      return @config[group][key]
    return @config[key]

  set: (key, value, group) ->
    if group
      if !@config[group]
        @config[group] = {}
      @config[group][key] = value
    else
      @config[key] = value

  all: ->
    @config
