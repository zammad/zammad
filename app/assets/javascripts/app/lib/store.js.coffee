class App.Store
  _instance = undefined # Must be declared here to force the closure on the class
  @write: (key, value) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.write(key, value)

  @get: (args) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.get(args)

  @delete: (args) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.delete(args)

  @list: () ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.list()

# The actual Singleton class
class _Singleton
  store: {}

  constructor: (@args) ->

  write: (key, value) ->
    @store[ key ] = value

  get: (key) ->
    @store[ key ]

  delete: (key) ->
    delete @store[ key ]

  list: () ->
    list = []
    for key of @store
      list.push key
    list