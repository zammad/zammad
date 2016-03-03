class App._CollectionSingletonBase
  event: 'to_be_defined'
  restEndpoint: '/to_be_defined'

  constructor: ->
    @callbacks = {}
    @counter = 0

    # read from cache
    cache = App.SessionStorage.get("collection-#{@event}")
    if cache
      @set(cache)

    # websocket updates
    App.Event.bind @event, (data) =>
      @set(data)
      @callback(data)

  get: ->
    @collection_data

  set: (data) ->
    App.SessionStorage.set("collection-#{@event}", data)
    @collection_data = data

  bind: (callback, init = true, one = false) ->
    @counter += 1

    # start init call if needed
    if init
      if @collection_data is undefined
        @fetch()
      else
        callback(@collection_data)
        return if one

    @callbacks[@counter] =
      callback: callback
      one: one

  unbind: (callback) ->
    for counter, attr of @callbacks
      if callback is attr.callback
        delete @callbacks[counter]

  fetch: =>
    if App.WebSocket.support()
      App.WebSocket.send(event: @event)
      return

    return if @fetchActive
    @fetchActive = true
    App.Ajax.request(
      id:    "collection-#{@event}"
      type:  'GET'
      url:   App.Config.get('api_path') + @restEndpoint
      processData: true
      success: (data) =>
        @fetchActive = false
        @set(data)
        @callback(data)
      error: =>
        @fetchActive = false
    )

  trigger: =>
    @callback(@get())

  callback: (data) =>
    for counter, attr of @callbacks
      attr.callback(data)
      if attr.one
        delete @callbacks[counter]
