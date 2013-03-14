$ = jQuery.sub()

class App.WebSocket
  _instance = undefined # Must be declared here to force the closure on the class
  @connect: (args) -> # Must be a static method
    if _instance == undefined
      _instance ?= new _Singleton
    _instance

  @close: (args) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.close(args)

  @send: (args) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.send(args)

  @auth: (args) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.auth(args)

  @channel: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.channel()

  @_spool: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.spool()

# The actual Singleton class
class _Singleton extends App.Controller
  @include App.Log

  queue: []
  supported:                true
  lastSpoolMessage:         undefined
  connectionEstablished:    false
  connectionWasEstablished: false
  tryToConnect:             false
  backend:                  'websocket'
  client_id:                undefined

  constructor: (@args) ->
    super

    # bind to send messages
    App.Event.bind 'ws:send', (data) =>
      @send(data)

    # get spool messages after successful ws login
    App.Event.bind( 'ws:login', (data) =>
      @spool()
    )

    # inital connect
    @connect()

  channel: ->
    @backend

  send: (data) =>
    if @backend is 'ajax'
      @_ajaxSend(data)
    else

#      console.log 'ws:send trying', data, @ws, @ws.readyState
  
      # A value of 0 indicates that the connection has not yet been established.
      # A value of 1 indicates that the connection is established and communication is possible.
      # A value of 2 indicates that the connection is going through the closing handshake.
      # A value of 3 indicates that the connection has been closed or could not be opened.
      if @ws.readyState is 0
        @queue.push data
      else
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

    @log 'Websocket', 'debug', 'spool', data

    # ask for spool messages
    App.Event.trigger(
      'ws:send'
      data
    )

    # set timestamp to get spool messages later
    @lastSpoolMessage = Math.round( +new Date()/1000 )

  close: =>
    return if @backend is 'ajax'

    @ws.close()

  ping: =>
    return if @backend is 'ajax'

    @log 'Websocket', 'debug', 'send websockend ping'
    @send( { action: 'ping' } )

    # check if ping is back within 2 min
    @clearDelay('websocket-ping-check', 'ws')
    check = =>
      @log 'Websocket', 'notice', 'no websockend ping response, reconnect...'
      @close()
    @delay check, 120000, 'websocket-ping-check', 'ws'

  pong: ->
    return if @backend is 'ajax'

    @log 'Websocket', 'debug', 'received websockend ping'

    # test again after 1 min
    @delay @ping, 60000, undefined, 'ws'

  connect: =>
    return if @backend is 'ajax'

    if !window.WebSocket
      @backend = 'ajax'
      @log 'WebSocket', 'notice', 'no support of websocket, use ajax long polling'
      @_ajaxInit()
      return

    protocol = 'ws://'
    if window.location.protocol is 'https:'
      protocol = 'wss://'

    @ws = new window.WebSocket( protocol + window.location.hostname + ":6042/" )

    # Set event handlers.
    @ws.onopen = =>
      @log 'Websocket', 'notice', 'new websocket connection open'

      @connectionEstablished = true
      @connectionWasEstablished = true

      # close error message show up (because try so connect again) if exists
      @clearDelay('websocket-no-connection-try-reconnect')
      if @error
        @error.modalHide()
        @error = undefined

      @auth()

      # empty queue
      for item in @queue
        @log 'Websocket', 'debug', 'empty ws queue', item
        @send(item)
      @queue = []

      # send ping to check connection
      @delay @ping, 60000, undefined, 'ws'

    @ws.onmessage = (e) =>
      pipe = JSON.parse( e.data )
      @log 'Websocket', 'debug', 'ws:onmessage', pipe
      @_receiveMessage(pipe)

    @ws.onclose = (e) =>
      @log 'Websocket', 'debug', "ws:onclose", e

      # set timestamp to get spool messages later
      if @connectionEstablished
        @lastSpoolMessage = Math.round( +new Date()/1000 )
        @connectionEstablished = false

      return if @backend is 'ajax'

      # show error message, first try to reconnect
      if !@error
        message = =>

          # use fallback if no connection was possible
          if !@connectionWasEstablished
            @backend = 'ajax'
            @log 'WebSocket', 'notice', 'No connection to websocket, use ajax long polling as fallback'
            @_ajaxInit()
            return

          # show reconnect message
          @error = new App.ErrorModal(
            message: 'No connection to websocket, trying to reconnect...'
          )
        if !@tryToConnect
          @delay message, 7000, 'websocket-no-connection-try-reconnect', 'ws'
        @tryToConnect = true

      # try reconnect after 4.5 sec.
      @delay @connect, 4500, undefined, 'ws'

    @ws.onerror = (e) =>
      @log 'Websocket', 'debug', "ws:onerror", e

  _receiveMessage: (data = []) =>

      # go through all blocks
      for item in data

        # reset reconnect loop
        if item['action'] is 'pong'
          @pong()

        # fill collection
        if item['collection']
          @log 'Websocket', 'debug', "onmessage collection:" + item['collection']
          App.Store.write( item['collection'], item['data'] )

        # fire event
        if item['event']
          if typeof item['event'] is 'object'
            for event in item['event']
              @log 'Websocket', 'debug', "onmessage event:" + event
              App.Event.trigger( event, item['data'] )
          else
            @log 'Websocket', 'debug', "onmessage event:" + item['event']
            App.Event.trigger( item['event'], item['data'] )

  _ajaxInit: (data = {}) =>

    # return if init is already done and not forced
    return if @_ajaxInitDone && !data.force

    # stop init request if new one is started
    if @_ajaxInitWorking
      @_ajaxInitWorking.abort()

    # call init request
    @_ajaxInitWorking = App.Com.ajax(
      type:  'POST'
      url:   'api/message_send'
      data:  JSON.stringify({ data: { action: 'login' }  })
      processData: false
      queue: false
      success: (data) =>
        if data.client_id
          @log 'Websocket', 'notice', 'ajax:new client_id', data.client_id
          @client_id = data.client_id
          @_ajaxReceive()
          @_ajaxSendQueue()
        @_ajaxInitDone = true
        @_ajaxInitWorking = false
      error: =>
        @_ajaxInitDone = true
        @_ajaxInitWorking = false
    )

  _ajaxSend: (data) =>
    @log 'Websocket', 'debug', 'ajax:sendmessage', data
    if !@client_id || @client_id is undefined || !@_ajaxInitDone
      @_ajaxInit()
      @queue.push data
    else
      @queue.push data
      @_ajaxSendQueue()

  _ajaxSendQueue: =>
    while !_.isEmpty(@queue)
      data = @queue.shift()
      App.Com.ajax(
        type:  'POST'
        url:   'api/message_send'
        data:  JSON.stringify({ client_id: @client_id, data: data })
        processData: false
        queue: true
        success: (data) =>
          if data && data.error
            @client_id = undefined
            @_ajaxInit( force: true )
        error: =>
          @client_id = undefined
          @_ajaxInit( force: true )
      )

  _ajaxReceive: =>
    return if !@client_id
    return if @_ajaxReceiveWorking is true
    @_ajaxReceiveWorking = true
    App.Com.ajax(
      id:    'message_receive',
      type:  'POST'
      url:   'api/message_receive'
      data:  JSON.stringify({ client_id: @client_id })
      processData: false
      success: (data) =>
        @log 'Websocket', 'notice', 'ajax:onmessage', data
        @_receiveMessage(data)
        if data && data.error
          @client_id = undefined
          @_ajaxInit( force: true )
        @_ajaxReceiveWorking = false
        @_ajaxReceive()
      error: (data) =>
        @client_id = undefined
        @_ajaxInit( force: true )
        @_ajaxReceiveWorking = false
        @delay @_ajaxReceive, 5000, undefined, 'ws'
    )
