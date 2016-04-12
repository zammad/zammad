class App.Collection
  _instance = undefined

  @init: ->
    _instance = new _collectionSingleton

  @load: (args) ->
    if _instance == undefined
      _instance ?= new _collectionSingleton
    _instance.load(args)

  @loadAssets: (args) ->
    if _instance == undefined
      _instance ?= new _collectionSingleton
    _instance.loadAssets(args)

  @reset: (args) ->
    if _instance == undefined
      _instance ?= new _collectionSingleton
    _instance.reset(args)

  @resetCollections: (args) ->
    if _instance == undefined
      _instance ?= new _collectionSingleton
    _instance.resetCollections(args)

class _collectionSingleton extends Spine.Module
  @include App.LogInclude

  constructor: (@args) ->

    # add trigger - bind new events
    App.Event.bind 'loadAssets', (data) =>
      if !data
        @log 'error', 'loadAssets:trigger, got no data, cant load assets'
        return

      @loadAssets(data)

    # add trigger - bind new events
    App.Event.bind 'resetCollection', (data) =>
      if !data
        @log 'error', 'resetCollection:trigger, got no data, cant for collections'
        return

      @resetCollections(data)

  resetCollections: (data) ->

    # load collection
    for type, collection of data
      @log 'debug', 'resetCollection:trigger', type, collection
      @reset(type: type, data: collection)

  reset: (params) ->

    # check if collection exists
    appObject = App[ params.type ]
    if !appObject
      @log 'error', 'reset', "no such collection #{params.type}", params
      return

    # reset in-memory
    appObject.refresh(params.data, clear: true)

  loadAssets: (assets) ->
    @log 'debug', 'loadAssets', assets
    for type, collections of assets
      @load(type: type, data: collections)

  load: (params) ->

    # no data to load
    return if _.isEmpty(params.data)

    # check if collection exists
    appObject = App[params.type]
    if !appObject
      @log 'error', 'reset', "no such collection #{params.type}", params
      return

    # load full array once
    if _.isArray(params.data)
      appObject.refresh(params.data)
      return

    # load data from object
    listToRefresh = []
    for key, object of params.data
      if !params.refresh && appObject
        @log 'debug', 'refrest try', params.type, key

        # check if new object is newer, just load newer objects
        if object.updated_at && appObject.exists(key)
          exists = appObject.find(key)
          if exists.updated_at
            if exists.updated_at < object.updated_at
              listToRefresh.push object
              @log 'debug', 'refrest newser', params.type, key
          else
            listToRefresh.push object
            @log 'debug', 'refrest try no updated_at', params.type, key
        else
          listToRefresh.push object
          @log 'debug', 'refrest new', params.type, key
    return if _.isEmpty(listToRefresh)
    appObject.refresh(listToRefresh)
