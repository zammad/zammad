class App.Session
  _instance = undefined

  @init: ->
    _instance ?= new _sessionSingleton
    _instance.clear()

  @get: ( key ) ->
    if _instance == undefined
      _instance ?= new _sessionSingleton
    _instance.get(key)

  @set: ( user ) ->
    if _instance == undefined
      _instance ?= new _sessionSingleton
    _instance.set(user)

class _sessionSingleton extends Spine.Module
  @include App.LogInclude

  constructor: ->
    @clear()

  clear: ->
    @user = undefined

  get: ( key ) ->
    return if !@user
    if key
      return @user[key]
    @user

  set: ( user ) ->
    @user = user