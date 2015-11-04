class App.OverviewIndexCollection
  _instance = undefined # Must be declared here to force the closure on the class

  @get: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.get()

  @bind: (callback) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.bind(callback)

  @unbind: (callback) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.unbind(callback)

  @trigger: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.trigger()

  @fetch: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.fetch()

# The actual Singleton class
class _Singleton
  constructor: ->
    @callbacks = {}
    @counter = 0

    # websocket updates
    App.Event.bind 'ticket_overview_index', (data) =>
      @overview_index = data
      @callback(data)

  get: ->
    @overview_index

  bind: (callback, init = true) ->
    @counter += 1

    # start init call if needed
    if init
      if @overview_index is undefined
        @fetch()
      else
        @callback(@overview_index)

    @callbacks[@counter] = callback

  unbind: (callback) ->
    for counter, localCallback of @callbacks
      if callback is localCallback
        delete @callbacks[counter]

  fetch: =>
    return if @fetchActive
    @fetchActive = true
    App.Ajax.request(
      id:    'ticket_overviews',
      type:  'GET',
      url:   App.Config.get('api_path') + '/ticket_overviews',
      processData: true,
      success: (data) =>
        @fetchActive = false
        @overview_index = data
        @callback(data)
      error: =>
        @fetchActive = false
    )

  trigger: =>
    @callback(@get())

  callback: (data) =>
    for counter, callback of @callbacks
      callback(data)
