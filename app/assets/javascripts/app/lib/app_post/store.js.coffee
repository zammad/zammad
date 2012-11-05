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

  # write to local storage
  write: (key, value) ->
    localStorage.setItem( key, JSON.stringify( value ) )

  # get item
  get: (key) ->
    value = localStorage.getItem( key )
    return if !value
    object = JSON.parse( value )
    return object

  # delete item
  delete: (key) ->
    localStorage.removeItem( key )

  # clear local storage
  clear: ->
    localStorage.clear()

  # return list of all keys
  list: ->
    list = []
    logLength = localStorage.length-1;
    for count in [0..logLength]
      key = localStorage.key( count )
      if key
        list.push key
    list