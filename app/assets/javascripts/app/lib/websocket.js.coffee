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

# The actual Singleton class
class _Singleton extends Spine.Controller
  queue: []
  supported: true

  constructor: (@args) ->
    @connect()

  send: (data) =>
    return if !@supported
    console.log 'ws:send trying', data, @ws, @ws.readyState

    # A value of 0 indicates that the connection has not yet been established.
    # A value of 1 indicates that the connection is established and communication is possible.
    # A value of 2 indicates that the connection is going through the closing handshake.
    # A value of 3 indicates that the connection has been closed or could not be opened.
    if @ws.readyState is 0
      @queue.push data
    else
      console.log( 'ws:send', data )
      string = JSON.stringify( data )
      @ws.send(string)

  auth: (data) =>
    return if !@supported

    # logon websocket
    data = {
      action: 'login',
      session: window.Session
    }
    @send(data)

  close: =>
    return if !@supported

    @ws.close()

  ping: =>
    return if !@supported

    console.log 'send websockend ping'
    @send( { action: 'ping' } )

    # check if ping is back within 2 min
    if @check_id
      clearTimeout(@check_id)
    check = =>
      console.log 'no websockend ping response, reconnect...'
      @close()
    @check_id = @delay check, 120000

  pong: ->
    return if !@supported

    console.log 'received websockend ping'

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
      console.log( "onopen" )

      # close error message if exists
      if @error_delay
        clearTimeout(@error_delay)
        @error_delay = undefined
      if @error
        @error.modalHide()
        @error = undefined

      @auth()

      # empty queue
      for item in @queue
        console.log( 'ws:send queue', item )
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
              Spine.trigger( event, item['data'] )
          else
            console.log( "ws:onmessage event:" + item['event'] )
            Spine.trigger( item['event'], item['data'] )

    # bind to send messages
    Spine.bind 'ws:send', (data) =>
      @send(data)

    @ws.onclose = (e) =>
      console.log( 'onclose', e )

      # show error message, first try to reconnect
      if !@error
        message = =>
          @error = new App.ErrorModal(
            message: 'No connection to websocket, trying to reconnect...'
          )
        @error_delay = @delay message, 7000

      # try reconnect after 4.5 sec.
      @delay @connect, 4500

    @ws.onerror = ->
      console.log( 'onerror' )

