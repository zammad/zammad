class App.Collection
  _instance = undefined

  @init: ->
    _instance = new _collectionSingleton

  @load: ( args ) ->
    if _instance == undefined
      _instance ?= new _collectionSingleton
    _instance.load( args )

  @reset: ( args ) ->
    if _instance == undefined
      _instance ?= new _collectionSingleton
    _instance.reset( args )

class _collectionSingleton extends Spine.Module
  @include App.LogInclude

  constructor: (@args) ->

    # add trigger - bind new events
    App.Event.bind 'loadAssets', (data) =>
      if data
        for type, collections of data
          if type is 'users'
            type = 'User'
          if type is 'tickets'
            type = 'Ticket'
          if type is 'ticket_article'
            type = 'TicketArticle'
          if type is 'organization'
            type = 'Organization'
          if type is 'history_object'
            type = 'HistoryObject'
          if type is 'history_type'
            type = 'HistoryType'
          if type is 'history_attribute'
            type = 'HistoryAttribute'

          @log 'debug', 'loadCollection:trigger', type, collections
          @load( localStorage: data.localStorage, type: type, data: collections )

    # add trigger - bind new events
    App.Event.bind 'loadCollection', (data) =>

      # load collections
      if data.collections
        for type of data.collections

          @log 'debug', 'loadCollection:trigger', type, data.collections[type]
          @load( localStorage: data.localStorage, type: type, data: data.collections[type] )

    # add trigger - bind new events
    App.Event.bind 'resetCollection', (data) =>

      # load collections
      if data.collections
        for type of data.collections

          @log 'debug', 'resetCollection:trigger', type, data.collections[type]
          @reset( localStorage: data.localStorage, type: type, data: data.collections[type] )

    # find collections to load
    @_loadCollectionAll()

  _loadCollectionAll: ->
    list = App.Store.list()
    for key in list
      parts = key.split('::')
      if parts[0] is 'collection'
        data = App.Store.get( key )
        if data && data.localStorage
          @log 'debug', 'load INIT', data
          @load( data )

  reset: (params) ->
    if !App[ params.type ]
      @log 'error', 'reset', 'no such collection', params
      return
    @log 'debug', 'reset', params

    # empty in-memory
    App[ params.type ].refresh( [], { clear: true } )

    # remove permanent storage
    list = App.Store.list()
    for key in list
      parts = key.split('::')
      if parts[0] is 'collection' && parts[1] is params.type
        App.Store.delete(key)

    # load with new data
    @load(params)

  load: (params) ->
    @log 'debug', 'load', params

    return if _.isEmpty( params.data )

    localStorage = params.localStorage

    # load full array once
    if _.isArray( params.data )
      if !params.refresh && App[ params.type ]
        App[ params.type ].refresh( params.data )

      # remember in store if not already requested from local storage
      if !localStorage
        for object in params.data
          App.Store.write( 'collection::' + params.type + '::' + object.id, { type: params.type, localStorage: true, data: [ object ] } )
      return

    # load data from object
#    if _.isObject( params.data )
    for key, object of params.data
      if !params.refresh && App[ params.type ]
        App[ params.type ].refresh( object )

      # remember in store if not already requested from local storage
      if !localStorage
        App.Store.write( 'collection::' + params.type + '::' + object.id, { type: params.type, localStorage: true, data: [ object ] } )

