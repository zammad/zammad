class _Singleton extends App._CollectionSingletonBase
  event: 'ticket_create_attributes'
  restEndpoint: '/ticket_create'

class App.TicketCreateCollection
  _instance = new _Singleton

  @get: ->
    _instance.get()

  @one: (callback, init = true) ->
    _instance.bind(callback, init, true)

  @bind: (callback, init = true) ->
    _instance.bind(callback, init, false)

  @unbind: (callback) ->
    _instance.unbind(callback)

  @unbindById: (id) ->
    _instance.unbindById(id)

  @trigger: ->
    _instance.trigger()

  @fetch: ->
    _instance.fetch()
