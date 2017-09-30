class _Singleton
  constructor: ->
    @overview = {}
    @callbacks = {}
    @fetchActive = {}
    @counter = 0

    App.Event.bind 'ticket_overview_list', (data) =>
      if data.assets
        App.Collection.loadAssets(data.assets)
        delete data.assets
      if !@overview[data.overview.view]
        @overview[data.overview.view] = {}
      @overview[data.overview.view] = data
      @callback(data.overview.view, data)

    App.Event.bind 'auth:logout', (data) =>
      @clear(data)

  get: (view) ->
    @overview[view]

  bind: (view, callback, init = true) ->
    @counter += 1
    @callbacks[@counter] =
      view: view
      callback: callback

    # start init call if needed
    if init
      if @overview[view] is undefined
        @fetch(view)
      else
        @callback(view, @overview[view])

    @counter

  unbind: (counter) ->
    delete @callbacks[counter]

  fetch: (view) =>
    #if App.WebSocket.support() && App.WebSocket.channel()
    #  App.WebSocket.send(
    #    event: 'ticket_overview_list'
    #    view: view
    #  )
    #  return
    throw 'No view to fetch list!' if !view
    App.OverviewIndexCollection.fetch()
    return if @fetchActive[view]
    @fetchActive[view] = true
    App.Ajax.request(
      id:   "ticket_overview_#{view}"
      type: 'GET'
      url:  "#{App.Config.get('api_path')}/ticket_overviews"
      data:
        view: view
      processData: true,
      success: (data) =>
        @fetchActive[view] = false
        if data.assets
          App.Collection.loadAssets(data.assets)
          delete data.assets
        if data.index && data.index.overview
          @overview[data.index.overview.view] = data.index
        @callback(view, data.index)
      error: =>
        @fetchActive[view] = false
    )

  trigger: (view) =>
    @callback(view, @get(view))

  callback: (view, data) =>
    for counter, meta of @callbacks
      if meta.view is view
        callback = ->
          meta.callback(data)
        App.QueueManager.add('ticket_overviews', callback)
        App.QueueManager.run('ticket_overviews')

  clear: =>
    @overview = {}
    @callbacks = {}
    @fetchActive = {}
    @counter = 0

class App.OverviewListCollection
  _instance = new _Singleton

  @get: (view) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.get(view)

  @bind: (view, callback, init) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.bind(view, callback, init)

  @unbind: (counter) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.unbind(counter)

  @fetch: (view) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.fetch(view)

  @trigger: (view) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.trigger(view)
