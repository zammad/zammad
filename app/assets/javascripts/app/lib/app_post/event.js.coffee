class App.Event
  _instance = undefined

  @init: ->
    _instance = new _eventSingleton

  @bind: ( events, callback, level ) ->
    if _instance == undefined
      _instance ?= new _eventSingleton
    _instance.bind( events, callback, level )

  @unbind: ( events, callback, level ) ->
    if _instance == undefined
      _instance ?= new _eventSingleton
    _instance.unbind( events, callback, level )

  @trigger: ( events, data ) ->
    if _instance == undefined
      _instance ?= new _eventSingleton
    _instance.trigger( events, data )

  @unbindLevel: (level) ->
    if _instance == undefined
      _instance ?= new _eventSingleton
    _instance.unbindLevel(level)

  @_allBindings: ->
    if _instance == undefined
      _instance ?= new _eventSingleton
    _instance._allBindings()

class _eventSingleton extends Spine.Module
  @include App.LogInclude

  constructor: ->
    @eventCurrent = {}

  unbindLevel: (level) ->
    return if !@eventCurrent[level]
    for item in @eventCurrent[level]
      @unbind( item.event, item.callback, level )
    @eventCurrent[level] = []

  bind: ( events, callback, level ) ->

    if !level
      level = '_all'

    if !@eventCurrent[level]
      @eventCurrent[level] = []

    # level boundary events
    eventList = events.split(' ')
    for event in eventList

      # remember all events
      @eventCurrent[ level ].push {
        event:    event,
        callback: callback,
      }

      # bind
      @log 'debug', 'bind', event, callback
      Spine.bind( event, callback )

  unbind: ( events, callback, level ) ->

    if !level
      level = '_all'

    if !@eventCurrent[level]
      @eventCurrent[level] = []

    eventList = events.split(' ')
    for event in eventList

      # remove from
      @eventCurrent[level] = _.filter( @eventCurrent[level], (item) ->
        if callback
          return item if item.event isnt event && item.callback isnt callback
        else
          return item if item.event isnt event
      )
      @log 'debug', 'unbind', event, callback
      Spine.unbind( event, callback )

  trigger: ( events, data ) ->
    eventList = events.split(' ')
    for event in eventList
      @log 'debug', 'trigger', event, data
      Spine.trigger event, data

  _allBindings: ->
    @eventCurrent
