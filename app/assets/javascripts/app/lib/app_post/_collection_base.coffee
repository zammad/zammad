class App._CollectionSingletonBase
  event: 'to_be_defined'
  restEndpoint: '/to_be_defined'

  constructor: ->
    @callbacks = {}
    @counter = 0
    @key = "collection-#{@event}"

    # read from cache
    cache = App.SessionStorage.get(@key)
    if cache
      @set(cache)

    # websocket updates
    App.Event.bind @event, (data) =>
      @set(data)
      @callback(data)

    App.Event.bind 'auth:logout', (data) =>
      @clear(data)

  get: =>
    @collectionData

  set: (data) =>
    App.SessionStorage.set("collection-#{@event}", data)
    @collectionData = data

  bind: (callback, init = true, one = false) =>
    @counter += 1
    localCounter = @counter

    # start init call if needed
    if init
      if @collectionData is undefined
        @fetch()
      else
        callback(@collectionData)
        return if one

    @callbacks[localCounter] =
      callback: callback
      one: one
    localCounter

  unbind: (callback) =>
    for counter, attr of @callbacks
      if callback is attr.callback
        delete @callbacks[counter]

  unbindById: (counter) =>
    delete @callbacks[counter]

  fetch: =>
    #if App.WebSocket.support() && App.WebSocket.channel()
    #  App.WebSocket.send(event: @event)
    #  return

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
      callback = =>
        attr.callback(data)
        if attr.one
          delete @callbacks[counter]
      App.QueueManager.add(@key, callback)
      App.QueueManager.run(@key)

  clear: =>
    @collectionData = undefined
