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
      if !data
        @log 'error', 'loadAssets:trigger, got no data, cant load assets'
        return

      for type, collections of data
        @log 'debug', 'loadCollection:trigger', type, collections
        @load( localStorage: data.localStorage, type: type, data: collections )

    # add trigger - bind new events
    App.Event.bind 'resetCollection', (data) =>
      if !data
        @log 'error', 'resetCollection:trigger, got no data, cant for collections'
        return

      # load collections
      for type, collection of data
        @log 'debug', 'resetCollection:trigger', type, collection
        @reset( localStorage: data.localStorage, type: type, data: collection )

    # find collections to load
    @_loadObjectsFromLocalStore()

  _loadObjectsFromLocalStore: ->
    list = App.Store.list()
    for key in list
      parts = key.split('::')
      if parts[0] is 'collection'
        data = App.Store.get( key )
        data['type']         = parts[1]
        data['localStorage'] = true

        @log 'debug', 'load INIT', data
        @load( data )

  reset: (params) ->
    if !App[ params.type ]
      @log 'error', 'reset', 'no such collection', params
      return

    @log 'debug', 'reset', params

    # remove permanent storage
    @localDelete( params.type )

    # reset in-memory
    App[ params.type ].refresh( params.data, { clear: true } )

    # remember in store if not already requested from local storage
    for object in params.data
      @localStore( params.type, object )

  load: (params) ->
    @log 'debug', 'load', params

    return if _.isEmpty( params.data )

    if !App[ params.type ]
      @log 'error', 'reset', 'no such collection', params
      return

    localStorage = params.localStorage

    # load full array once
    if _.isArray( params.data )
      App[ params.type ].refresh( params.data )

      # remember in store if not already requested from local storage
      if !localStorage
        for object in params.data
          @localStore( params.type, object )
      return

    # load data from object
    for key, object of params.data
      if !params.refresh && App[ params.type ]
        App[ params.type ].refresh( object )

      # remember in store if not already requested from local storage
      if !localStorage
        @localStore( params.type, object)

  localDelete: (type) ->
    list = App.Store.list()
    for key in list
      parts = key.split('::')
      if parts[0] is 'collection' && parts[1] is type
        App.Store.delete(key)

  localStore: (type, object) ->
    App.Store.write( 'collection::' + type + '::' + object.id, { data: [ object ] } )
