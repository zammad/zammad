class _Singleton extends App._CollectionSingletonBase
  event: 'ticket_overview_attributes'
  restEndpoint: '/ticket_overview'

class App.TicketOverviewCollection
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
