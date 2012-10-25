class App.Event
  _instance = undefined

  @init: ->
    _instance = new _Singleton

  @bind: (args) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.bind(args)

  @unbind: (args) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.unbind(args)


  @cleanUpLevel: (level) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.cleanUpLevel(level)

class _Singleton

  constructor: (args) ->
    super
    @eventCurrent = {}

  cleanUpLevel: (level) ->
    return if !@eventCurrent[level]
    for event of @eventCurrent[level]
      @_unbind( level, event )

  bind: (data) ->

    if !data.level
      Spine.bind( data.event, data.callback )
      return

    if !@eventCurrent[ data.level ]
      @eventCurrent[ data.level ] = {}

    # for all events
    events = data.event.split(' ')
    for event in events

      # unbind
      @_unbind( data.level, event )

    for event in events

      # remember all events
      @eventCurrent[ data.level ][ event ] = data

      # bind
      Spine.bind( event, data.callback )

  _unbind: ( level, event ) ->
    console.log '_unbind', level, event
    return if !@eventCurrent[level]

    data = @eventCurrent[ level ][ event ]
    return if !data

    Spine.unbind( event, data.callback )

    @eventCurrent[ level ][ event ] = undefined

  unbind: (data) ->

    if !data.level
      Spine.unbind( data.event, data.callback )
      return

    if !@eventCurrent[ data.level ]
      @eventCurrent[ data.level ] = {}

    # for all events
    events = data.event.split(' ')
    for event in events

      # unbind
      @_unbind( data.level, event )

