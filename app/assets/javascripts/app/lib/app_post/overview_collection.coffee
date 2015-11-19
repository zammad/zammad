class App.OverviewCollection
  _instance = undefined # Must be declared here to force the closure on the class

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

# The actual Singleton class
class _Singleton
  constructor: ->
    @overview = {}
    @callbacks = {}
    @fetchActive = {}
    @counter = 0

    # websocket updates
    App.Event.bind 'ticket_overview_rebuild', (data) =>
      if !@overview[data.view]
        @overview[data.view] = {}

      # proccess assets, delete them later
      if data.assets
        App.Collection.loadAssets( data.assets )
      delete data.assets

      @overview[data.view] = data

      @callback(data.view, data)

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
    return if @fetchActive[view]
    @fetchActive[view] = true
    App.Ajax.request(
      id:   'ticket_overview_' + view
      type:  'GET',
      url:   App.Config.get('api_path') + '/ticket_overviews',
      data:
        view: view
      processData: true,
      success: (data) =>
        @fetchActive[view] = false

        # proccess assets, delete them later
        if data.assets
          App.Collection.loadAssets( data.assets )
        delete data.assets

        @overview[data.view] = data

        @callback(view, data)
      error: =>
        @fetchActive[view] = false
    )

  trigger: (view) =>
    @callback(view, @get(view))

  callback: (view, data) =>
    for counter, meta of @callbacks
      if meta.view is view
        meta.callback(data)
