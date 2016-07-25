class App.SessionStorage
  _instance = undefined # Must be declared here to force the closure on the class

  @set: (key, value) ->
    if _instance == undefined
      _instance ?= new _storeSingleton
    _instance.set(key, value)

  @get: (key) ->
    if _instance == undefined
      _instance ?= new _storeSingleton
    _instance.get(key)

  @delete: (key) ->
    if _instance == undefined
      _instance ?= new _storeSingleton
    _instance.delete(key)

  @clear: ->
    if _instance == undefined
      _instance ?= new _storeSingleton
    _instance.clear()

  @list: ->
    if _instance == undefined
      _instance ?= new _storeSingleton
    _instance.list()

  @usage: ->
    if _instance == undefined
      _instance ?= new _storeSingleton
    _instance.usage()

# The actual Singleton class
class _storeSingleton
  constructor: ->

    App.Event.bind 'clearStore', =>
      @clear()

  # write to local storage
  set: (key, value) ->
    try
      sessionStorage.setItem(key, JSON.stringify(value))
    catch e
      @clear()
      App.Log.error 'App.SessionStorage', 'Session storage error!', e
      sessionStorage.setItem(key, JSON.stringify(value))

  # get item
  get: (key) ->
    value = sessionStorage.getItem(key)
    return if !value
    JSON.parse(value)

  # delete item
  delete: (key) ->
    sessionStorage.removeItem(key)

  # clear local storage
  clear: ->
    sessionStorage.clear()

  # return list of all keys
  list: ->
    window.sessionStorage

  # get usage
  usage: ->
    total = ''
    for key of window.sessionStorage
      value = sessionStorage.getItem(key)
      if _.isString(value)
        total += value
    byteLength(total)
