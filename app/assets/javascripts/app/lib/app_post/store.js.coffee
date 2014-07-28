class App.Store
  _instance = undefined # Must be declared here to force the closure on the class
  @renew: ->
    _instance = new _storeSingleton

  @write: (key, value) ->
    if _instance == undefined
      _instance ?= new _storeSingleton
    _instance.write(key, value)

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

  @list: () ->
    if _instance == undefined
      _instance ?= new _storeSingleton
    _instance.list()

# The actual Singleton class
class _storeSingleton
  store: {}
  constructor: ->
    @support = true
    if !window.sessionStorage
      @support = false
#    @support = false

    # clear store on every login/logout
    if @support
      App.Event.bind 'clearStore', =>
        @clear('all')

  # write to local storage
  write: (key, value) ->
    @store[key] = value
    return if !@support
    return if !App.Config.get('ui_client_storage')
    try
      sessionStorage.setItem( key, JSON.stringify( value ) )
    catch e
      if e is QUOTA_EXCEEDED_ERR
        # do something nice to notify your users
        App.Log.error 'App.Store', 'Local storage quote exceeded, please relogin!'

  # get item
  get: (key) ->
    return @store[key] if !@support
    return @store[key] if !App.Config.get('ui_client_storage')
    value = sessionStorage.getItem( key )
    return if !value
    object = JSON.parse( value )
    return object

  # delete item
  delete: (key) ->
    delete @store[key]
    return if !@support
    return if !App.Config.get('ui_client_storage')
    sessionStorage.removeItem( key )

  # clear local storage
  clear: ->
    @store = {}
    sessionStorage.clear()

  # return list of all keys
  list: ->
    list = []
    if !@support || !App.Config.get('ui_client_storage')
      for key of @store
        list.push key
      return list

#    logLength = sessionStorage.length-1;
#    for count in [0..logLength]
#      key = sessionStorage.key( count )
#      if key
#        list.push key
    for key of window.sessionStorage
      list.push key
    list
