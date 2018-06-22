class App.Collection
  _instance = undefined

  @init: ->
    _instance = new _collectionSingleton

  @load: (args) ->
    if _instance == undefined
      _instance ?= new _collectionSingleton
    _instance.load(args)

  @loadAssets: (args, params) ->
    if _instance == undefined
      _instance ?= new _collectionSingleton
    _instance.loadAssets(args, params)

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

  loadAssets: (assets, params = {}) ->
    return if _.isEmpty(assets)

    # process not existing assets first / to avoid not exising ref errors
    loadAssetsLater = {}
    for type, collections of assets
      if !params.targetModel || params.targetModel isnt type
        later = @load(type: type, data: collections, later: true)
        if !_.isEmpty(later)
          loadAssetsLater[type] = later

    # process existing assets
    for type, collections of loadAssetsLater
      App[type].refresh(collections)

    if params.targetModel
      for type, collections of assets
        if params.targetModel is type
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
      @log 'debug', 'refresh', params.data
      appObject.refresh(params.data)
      return

    # load data from object
    listToRefresh = []
    listToRefreshLater = []
    for key, object of params.data
      if !params.refresh && appObject
        @log 'debug', 'refresh try', params.type, key

        # check if new object is newer, just load newer objects
        if object.updated_at
          currentUpdatedAt = appObject.updatedAt(key)
          if currentUpdatedAt
            if currentUpdatedAt < object.updated_at
              if params.later
                listToRefreshLater.push object
                @log 'debug', 'refresh newer later', params.type, key
              else
                listToRefresh.push object
                @log 'debug', 'refresh newer', params.type, key

          else
            listToRefresh.push object
            @log 'debug', 'refresh new no current updated_at', params.type, key
        else
          listToRefresh.push object
          @log 'debug', 'refresh new', params.type, key
    return listToRefreshLater if _.isEmpty(listToRefresh)
    appObject.refresh(listToRefresh)
    listToRefreshLater
