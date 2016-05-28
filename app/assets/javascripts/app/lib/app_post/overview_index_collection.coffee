class _Singleton extends App._CollectionSingletonBase
  event: 'ticket_overview_index'
  restEndpoint: '/ticket_overviews'

class App.OverviewIndexCollection
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
