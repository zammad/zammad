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

  @fetch: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.fetch()

# The actual Singleton class
class _Singleton
  constructor: ->
    @callbacks = {}
    @counter = 0
    App.Event.bind 'ticket_overview_index', (data) =>
      @overview_index = data

  get: ->
    @overview_index

  bind: (callback) ->
    @counter += 1
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
        for counter, callback of @callbacks
          callback(data)
      error: =>
        @fetchActive = false
    )
