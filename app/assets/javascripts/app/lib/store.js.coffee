class App.Store
  _instance = undefined # Must be declared here to force the closure on the class
  @renew: ->
    _instance = new _Singleton

  @load: ->
    if _instance == undefined
      _instance ?= new _Singleton

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

  @clear: (args) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.clear(args)

  @list: () ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.list()

# The actual Singleton class
class _Singleton
  store: {}

  constructor: (@args) ->

    # find collections to load
    @_loadCollectionAll()
    @_loadCollectionType('TicketPriority')
    @_loadCollectionType('TicketStateType')
    @_loadCollectionType('TicketState')
    @_loadCollectionType('TicketArticleSender')
    @_loadCollectionType('TicketArticleType')
    @_loadCollectionType('Group')
    @_loadCollectionType('Role')
    @_loadCollectionType('Organization')
    @_loadCollectionType('User')
    @_loadCollectionType()

  _loadCollectionAll: ->
    @all = {}
    @rest = {}
    logLength = localStorage.length-1;
    for count in [0..logLength]
      key = localStorage.key( count )
      if key
        value = localStorage.getItem( key )
        data = JSON.parse( value )
        @all[key] = data

  _loadCollectionType: (type) ->
#    console.log('STORE NEW' + logLength)
    toGo = @all
    if !_.isEmpty( @rest )
      toGo = _.clone( @rest )
      @rest = {}
    for key, data of toGo
#        console.log('STORE NEW' + count + '-' + key, data)
      if data['collections']
        data['localStorage'] = true

        if type
          if data['type'] is type
            @_loadCollection(data)
          else
            @rest[key] = data
        else
            @_loadCollection(data)

  _loadCollection: (data) ->
    console.log('fire', 'loadCollection', data )
    Spine.trigger( 'loadCollection', data )

  write: (key, value) ->

    # write to instance
    @store[ key ] = value

    # write to local storage
    localStorage.setItem( key, JSON.stringify( value ) )

  get: (key) ->

    # return from instance
    return @store[ key ] if @store[ key ]

    # if not, return from local storage
    value = localStorage.getItem( key )
    object = JSON.parse( value )
    return object if object

    # return undefined if not in storage
    return undefined

  delete: (key) ->
    delete @store[ key ]

  clear: (action) ->

    console.log 'Store:clear', action

    # clear instance data
    @store = {}

    # clear local storage
    if action is 'all'
      localStorage.clear()

  list: () ->
    list = []
    for key of @store
      list.push key
    list