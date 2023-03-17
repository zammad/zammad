class App.Session
  _instance = undefined

  @init: ->
    _instance ?= new _sessionSingleton
    _instance.clear()

  # Do NOT modify the return value of this method!
  # It is a direct reference to a value in the App.User.irecords object.
  @get: (key) ->
    if _instance == undefined
      _instance ?= new _sessionSingleton
    _instance.get(key)

  @set: (user_id) ->
    if _instance == undefined
      _instance ?= new _sessionSingleton
    _instance.set(user_id)

class _sessionSingleton extends Spine.Module
  @include App.LogInclude

  constructor: ->
    @clear()

  clear: ->
    @user = undefined

  get: (key) ->
    if key
      return @user?[key]
    @user

  set: (user_id) ->
    @user = App.User.findNative(user_id)
