class App.Store
  _instance = undefined # Must be declared here to force the closure on the class
  @renew: ->
    _instance = new _Singleton

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

  @clear: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.clear()

  @list: () ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.list()

# The actual Singleton class
class _Singleton
  store: {}
  constructor: ->
    @support = true
    if !window.localStorage
      @support = false
#    @support = false

  # write to local storage
  write: (key, value) ->
    @store[key] = value
    return if !@support
    try
      localStorage.setItem( key, JSON.stringify( value ) )
    catch e
      if e is QUOTA_EXCEEDED_ERR
        # do something nice to notify your users
        App.Log.log 'App.Store', 'error', 'Local storage quote exceeded, please relogin!'

  # get item
  get: (key) ->
    return @store[key] if !@support
    value = localStorage.getItem( key )
    return if !value
    object = JSON.parse( value )
    return object

  # delete item
  delete: (key) ->
    @store.delete key
    return if !@support
    localStorage.removeItem( key )

  # clear local storage
  clear: ->
    @store = {}
    localStorage.clear()

  # return list of all keys
  list: ->
    list = []
    if !@support
      for key of @store
        list.push key
      return list

#    logLength = localStorage.length-1;
#    for count in [0..logLength]
#      key = localStorage.key( count )
#      if key
#        list.push key
    for key of window.localStorage
      list.push key
    list