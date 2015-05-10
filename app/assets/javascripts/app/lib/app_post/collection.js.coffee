class App.Collection
  _instance = undefined

  @init: ->
    _instance = new _collectionSingleton

  @load: ( args ) ->
    if _instance == undefined
      _instance ?= new _collectionSingleton
    _instance.load( args )

  @loadAssets: ( args ) ->
    if _instance == undefined
      _instance ?= new _collectionSingleton
    _instance.loadAssets( args )

  @reset: ( args ) ->
    if _instance == undefined
      _instance ?= new _collectionSingleton
    _instance.reset( args )

  @resetCollections: ( args ) ->
    if _instance == undefined
      _instance ?= new _collectionSingleton
    _instance.resetCollections( args )

class _collectionSingleton extends Spine.Module
  @include App.LogInclude

  constructor: (@args) ->

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

  resetCollections: (data) ->
      # load assets
      for type, collection of data
        @log 'debug', 'resetCollection:trigger', type, collection
        @reset( localStorage: data.localStorage, type: type, data: collection )

  reset: (params) ->

    # check if collection exists
    appObject = App[ params.type ]
    if !appObject
      @log 'error', 'reset', "no such collection #{params.type}", params
      return

    # remove permanent storage
    @localDelete( params.type )

    # reset in-memory
    appObject.refresh( params.data, { clear: true } )

    # remember in store if not already requested from local storage
    for object in params.data
      @localStore( params.type, object )

  loadAssets: (assets) ->
    @log 'debug', 'loadAssets', assets
    for type, collections of assets
      @load( localStorage: false, type: type, data: collections )

  load: (params) ->

    # no data to load
    return if _.isEmpty( params.data )

    # check if collection exists
    appObject = App[ params.type ]
    if !appObject
      @log 'error', 'reset', "no such collection #{params.type}", params
      return

    localStorage = params.localStorage

    # load full array once
    if _.isArray( params.data )
      appObject.refresh( params.data )

      # remember in store if not already requested from local storage
      if !localStorage
        for object in params.data
          @localStore( params.type, object )
      return

    # load data from object
    for key, object of params.data
      if !params.refresh && appObject

        # check if new object is newer, just load newer objects
        if object.updated_at && appObject.exists( key )
          exists = appObject.find( key )
          if exists.updated_at
            if exists.updated_at < object.updated_at
              appObject.refresh( object )
          else
            appObject.refresh( object )
        else
          appObject.refresh( object )

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
