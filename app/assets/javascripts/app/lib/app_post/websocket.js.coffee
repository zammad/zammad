$ = jQuery.sub()

class App.WebSocket
  _instance = undefined # Must be declared here to force the closure on the class
  @connect: (args) -> # Must be a static method
    if _instance == undefined
      _instance ?= new _Singleton
    _instance

  @close: (args) -> # Must be a static method
    if _instance isnt undefined
      _instance.close()

  @send: (args) -> # Must be a static method
    @connect()
    _instance.send(args)

  @auth: (args) -> # Must be a static method
    @connect()
    _instance.auth(args)

  @_spool: ->
    _instance.spool()

# The actual Singleton class
class _Singleton extends App.Controller
  queue: []
  supported:             true
  lastSpoolMessage:      undefined
  connectionEstablished: false

  constructor: (@args) ->

    # bind to send messages
    App.Event.bind 'ws:send', (data) =>
      @send(data)

    # get spool messages after successful ws login
    App.Event.bind( 'ws:login', (data) =>
      @spool()
    )

    # inital connect
    @connect()

  send: (data) =>
    return if !@supported
#    console.log 'ws:send trying', data, @ws, @ws.readyState

    # A value of 0 indicates that the connection has not yet been established.
    # A value of 1 indicates that the connection is established and communication is possible.
    # A value of 2 indicates that the connection is going through the closing handshake.
    # A value of 3 indicates that the connection has been closed or could not be opened.
    if @ws.readyState is 0
      @queue.push data
    else
#      console.log( 'ws:send', data )
      string = JSON.stringify( data )
      @ws.send(string)

  auth: (data) =>
    return if !@supported

    # logon websocket
    data =
      action: 'login'
      session: App.Session.all()
    @send(data)

  spool: =>

    # build data to send to server
    data =
      action: 'spool'
    if @lastSpoolMessage
      data['timestamp'] = @lastSpoolMessage
    @log 'spool', data
    # ask for spool messages
    App.Event.trigger(
      'ws:send'
      data
    )

    # set timestamp to get spool messages later
    @lastSpoolMessage = Math.round( +new Date()/1000 )

  close: =>
    return if !@supported

    @ws.close()

  ping: =>
    return if !@supported

#    console.log 'send websockend ping'
    @send( { action: 'ping' } )

    # check if ping is back within 2 min
    @clearDelay('websocket-ping-check')
    check = =>
      console.log 'no websockend ping response, reconnect...'
      @close()
    @delay check, 120000, 'websocket-ping-check'

  pong: ->
    return if !@supported
#    console.log 'received websockend ping'

    # test again after 1 min
    @delay @ping, 60000

  connect: =>
#    console.log '------------ws connect....--------------'

    if !window.WebSocket
      @error = new App.ErrorModal(
        message: 'Sorry, no websocket support!'
      )
      @supported = false
      return

    protocol = 'ws://'
    if window.location.protocol is 'https:'
      protocol = 'wss://'

    @ws = new window.WebSocket( protocol + window.location.hostname + ":6042/" )

    # Set event handlers.
    @ws.onopen = =>
      console.log( 'onopen' )

      @connectionEstablished = true

      # close error message show up (because try so connect again) if exists
      @clearDelay('websocket-no-connection-try-reconnect')
      if @error
        @error.modalHide()
        @error = undefined

      @auth()

      # empty queue
      for item in @queue
#        console.log( 'ws:send queue', item )
        @send(item)
      @queue = []

      # send ping to check connection
      @delay @ping, 60000

    @ws.onmessage = (e) =>
      pipe = JSON.parse( e.data )
      console.log( 'ws:onmessage', pipe )

      # go through all blocks
      for item in pipe

        # reset reconnect loop
        if item['action'] is 'pong'
          @pong()

        # fill collection
        if item['collection']
          console.log( "ws:onmessage collection:" + item['collection'] )
          App.Store.write( item['collection'], item['data'] )

        # fire event
        if item['event']
          if typeof item['event'] is 'object'
            for event in item['event']
              console.log( "ws:onmessage event:" + event )
              App.Event.trigger( event, item['data'] )
          else
            console.log( "ws:onmessage event:" + item['event'] )
            App.Event.trigger( item['event'], item['data'] )

    @ws.onclose = (e) =>
      console.log( 'onclose', e )

      # set timestamp to get spool messages later
      if @connectionEstablished
        @lastSpoolMessage = Math.round( +new Date()/1000 )
        @connectionEstablished = false

      # show error message, first try to reconnect
      if !@error
        message = =>
          @error = new App.ErrorModal(
            message: 'No connection to websocket, trying to reconnect...'
          )
        @delay message, 7000, 'websocket-no-connection-try-reconnect'

      # try reconnect after 4.5 sec.
      @delay @connect, 4500

    @ws.onerror = ->
      console.log( 'onerror' )

