class App.SessionStorage
  _instance = undefined # Must be declared here to force the closure on the class

  @set: (key, value) ->
    if _instance == undefined
      _instance ?= new _storeSingleton
    _instance.set(key, value)

  @get: (args) ->
    if _instance == undefined
      _instance ?= new _storeSingleton
    _instance.get(args)

  @delete: (args) ->
    if _instance == undefined
      _instance ?= new _storeSingleton
    _instance.delete(args)

  @clear: ->
    if _instance == undefined
      _instance ?= new _storeSingleton
    _instance.clear()

  @list: ->
    if _instance == undefined
      _instance ?= new _storeSingleton
    _instance.list()

# The actual Singleton class
class _storeSingleton
  constructor: ->

    App.Event.bind 'clearStore', =>
      @clear()

  # write to local storage
  set: (key, value) ->
    try
      sessionStorage.setItem(key, JSON.stringify( value ))
    catch e
      if e is QUOTA_EXCEEDED_ERR
        # do something nice to notify your users
        App.Log.error 'App.LocalStore', 'Local storage quote exceeded!'

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
    for key of window.sessionStorage
      list.push key
    list
