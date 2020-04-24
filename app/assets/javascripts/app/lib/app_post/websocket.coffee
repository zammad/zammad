class App.WebSocket
  _instance = undefined # Must be declared here to force the closure on the class
  @connect: (args) -> # Must be a static method
    if _instance == undefined
      _instance ?= new _webSocketSingleton
    _instance

  @close: (args) ->
    if _instance == undefined
      _instance ?= new _webSocketSingleton
    _instance.close(args)

  @send: (args) ->
    if _instance == undefined
      _instance ?= new _webSocketSingleton
    _instance.send(args)

  @auth: (args) ->
    if _instance == undefined
      _instance ?= new _webSocketSingleton
    _instance.auth(args)

  @channel: ->
    if _instance == undefined
      _instance ?= new _webSocketSingleton
    _instance.channel()

  @_spool: ->
    if _instance == undefined
      _instance ?= new _webSocketSingleton
    _instance.spool()

  @support: ->
    if _instance == undefined
      _instance ?= new _webSocketSingleton
    _instance.support()

  @queue: ->
    if _instance == undefined
      _instance ?= new _webSocketSingleton
    _instance.queue

# The actual Singleton class
class _webSocketSingleton extends App.Controller
  @include App.LogInclude

  queue:                    []
  supported:                true
  lastSpoolMessage:         undefined
  sentSpoolFinished:        true
  connectionKeepDown:       false
  connectionEstablished:    false
  connectionWasEstablished: false
  tryToConnect:             false
  backend:                  undefined # set in constructor when config is available
  backend_port:             ''
  client_id:                undefined
  error:                    false

  constructor: (@args) ->
    super

    @backend = @Config.get('websocket_backend') || 'websocket'

    # on auth, send new auth data to server
    App.Event.bind(
      'auth'
      (data) =>
        @auth()
      'ws'
    )

    # bind to send messages
    App.Event.bind(
      'ws:send'
      (data) =>
        @send(data)
      'ws'
    )

    # get spool messages after successful ws login
    App.Event.bind(
      'ws:login', =>
        @spool()
      'ws'
    )

    # get spool:sent
    App.Event.bind(
      'spool:sent'
      (data) =>

        # set timestamp to get spool messages later
        @lastSpoolMessage = data.timestamp

        # set sentSpoolFinished
        @sentSpoolFinished = true

        App.Delay.clear 'reset-spool-sent-if-not-returned', 'ws'
      'ws'
    )

    # initial connect
    @connect()

    # send ping after visibilitychange to check if connection is open again after wakeup
    $(document).bind('visibilitychange', =>
      @log 'debug', 'visibilitychange'
      return if document.hidden
      return if !@connectionEstablished
      @log 'debug', 'ping'
      @ping()
    )

  channel: ->
    return @backend if @connectionEstablished
    undefined

  support: ->
    @supported

  send: (data) =>
    if @backend is 'ajax'
      @_ajaxSend(data)
    else

      # A value of 0 indicates that the connection has not yet been established.
      # A value of 1 indicates that the connection is established and communication is possible.
      # A value of 2 indicates that the connection is going through the closing handshake.
      # A value of 3 indicates that the connection has been closed or could not be opened.
      if @ws.readyState isnt 1
        @queue.push data
      else
        string = JSON.stringify(data)
        @ws.send(string)

  auth: (data) =>
    return if !@supported

    # logon websocket
    data =
      event: 'login'
      session_id: App.Config.get('session_id')
      fingerprint: App.Browser.fingerprint()
    @send(data)

  spool: =>
    return if !@sentSpoolFinished
    @sentSpoolFinished = false

    # build data to send to server
    data =
      event: 'spool'
    if @lastSpoolMessage
      data['timestamp'] = @lastSpoolMessage

    @log 'debug', 'spool', data

    # reset @sentSpoolFinished if spool:sent will not return
    reset = =>
      @sentSpoolFinished = true
    App.Delay.set reset, 60000, 'reset-spool-sent-finished-if-not-returned', 'ws'

    # ask for spool messages
    @send(data)

  close: ( params = {} ) =>
    if params['force']
      @connectionKeepDown = true

    return if @backend is 'ajax'

    @ws.close()

  ping: =>
    return if @backend is 'ajax'

    @log 'debug', 'send websocket ping'
    @send(event: 'ping')

    # check if ping is back within 90 sec
    App.Delay.clear 'websocket-ping-check', 'ws'
    check = =>
      @log 'debug', 'no websocket ping response, reconnect...'
      @close()
    App.Delay.set check, 90000, 'websocket-ping-check', 'ws'

  pong: ->
    return if @backend is 'ajax'

    @log 'debug', 'received websocket pong'

    # test again after 60 sec
    App.Delay.set(@ping, 60000, 'websocket-pong', 'ws')

  connect: =>

    if !window.WebSocket
      @supported = false
      @backend = 'ajax'
      @log 'debug', 'no support of websocket, use ajax long polling'
      @_ajaxInit()
      return

    protocol = 'ws://'
    if window.location.protocol is 'https:'
      protocol = 'wss://'

    if @backend is 'websocket'
      port = ''
      if window.location.port && window.location.port != ''
        port = ":#{window.location.port}"
      @ws = new window.WebSocket("#{protocol}#{window.location.hostname}#{port}/ws")
    else if @backend is 'websocketPort'
      @backend_port = App.Config.get('websocket_port') || '6042'
      @ws           = new window.WebSocket("#{protocol}#{window.location.hostname}:#{@backend_port}/")
    else
      @_ajaxInit()

    # Set event handlers.
    @ws.onopen = =>
      if @backend_port
        port = ":#{@backend_port}"
      @log 'debug', "new websocket (#{@channel()}#{port}) connection open"

      @connectionEstablished    = true
      @connectionWasEstablished = true

      # close error message show up (because try so connect again) if exists
      App.Delay.clear('websocket-no-connection-try-reconnect-message', 'ws')
      if @error
        @error.close()
        @error        = false
        @tryToConnect = false

      @auth()

      # empty queue
      for item in @queue
        @log 'debug', 'empty ws queue', item
        @send(item)
      @queue = []

      # send ping to check connection
      App.Delay.set(@ping, 60000, 'websocket-send-ping-to-heck-connection', 'ws')

    @ws.onmessage = (e) =>
      pipe = JSON.parse(e.data)
      @log 'debug', 'ws:onmessage', pipe
      @_receiveMessage(pipe)

    @ws.onclose = (e) =>
      @log 'debug', 'close websocket connection'

      # take connection down and keep it down
      return if @connectionKeepDown

      if @connectionEstablished
        @connectionEstablished = false

      # if connection was not possible
      if !@connectionWasEstablished

        # use ws dedicated port fallback if no connection was possible
        if @backend is 'websocket'
          @log 'debug', 'no websocket connection on /ws, use :port/'
          @backend = 'websocketPort'
          @connect()
          return

        # use ajax fallback if no connection was possible
        if @backend is 'websocketPort'
          if @backend_port
            port = ":#{@backend_port}"
          @log 'debug', "no websocket connection on port #{port}, use ajax long polling as fallback"
          @backend = 'ajax'
          @connect()
          return

      # show error message, first try to reconnect
      if !@error
        message = =>

          # show reconnect message
          @error = new Modal()
        if !@tryToConnect
          App.Delay.set message, 7000, 'websocket-no-connection-try-reconnect-message', 'ws'
        @tryToConnect = true

      # try reconnect after 4.5 sec.
      App.Delay.set @connect, 4500, 'websocket-try-reconnect-after-x-sec', 'ws'

    @ws.onerror = (e) =>
      @log 'debug', 'ws:onerror', e

  _receiveMessage: (data = []) =>

    # go through all blocks
    for item in data
      @log 'debug', 'onmessage', item

      # set timestamp to get spool messages later
      if item['spool']
        @lastSpoolMessage = Math.round( +new Date()/1000 )

      # reset reconnect loop
      if item['event'] is 'pong'
        @pong()

      # fire event
      if item['event']
        @log 'debug', "onmessage event: #{item['event']}"
        App.Event.trigger(item['event'], item['data'])

  _ajaxInit: (data = {}) =>

    # return if init is already done and not forced
    return if @_ajaxInitDone && !data.force

    # call init request
    App.Ajax.request(
      id:    'ws-login'
      type:  'POST'
      url:   @Config.get('api_path') + '/message_send'
      data:  JSON.stringify(data: { event: 'login' })
      processData: false
      queue: false
      success: (data) =>
        if data.client_id
          @log 'debug', 'ajax:new client_id', data.client_id
          @client_id = data.client_id
          @_ajaxReceive()
          @_ajaxSendQueue()
        @_ajaxInitDone = true
      error: =>
        @_ajaxInitDone = true

        # try reconnect on error after x sec.
        reconnect = =>
          @_ajaxInit(force: true)
        App.Delay.set(reconnect, 10000, '_ajaxInit-reconnect-on-error', 'ws')
    )

  _ajaxSend: (data) =>
    @log 'debug', 'ajax:sendmessage', data
    if !@client_id || @client_id is undefined || !@_ajaxInitDone
      @_ajaxInit()
      @queue.push data
    else
      @queue.push data
      @_ajaxSendQueue()

  _ajaxSendQueue: =>
    while !_.isEmpty(@queue)
      data = @queue.shift()
      App.Ajax.request(
        type:  'POST'
        url:   @Config.get('api_path') + '/message_send'
        data:  JSON.stringify(client_id: @client_id, data: data)
        processData: false
        queue: true
        success: (data) =>
          if data && data.error
            @client_id = undefined
            @_ajaxInit(force: true)
        error: =>
          @client_id = undefined
          @_ajaxInit(force: true)
      )

  _ajaxReceive: =>
    return if !@client_id
    return if @_ajaxReceiveWorking is true
    @_ajaxReceiveWorking = true
    App.Ajax.request(
      id:    'message_receive',
      type:  'POST'
      url:   @Config.get('api_path') + '/message_receive'
      data:  JSON.stringify(client_id: @client_id)
      processData: false
      success: (data) =>
        @log 'debug', 'ajax:onmessage', data
        @_receiveMessage(data)
        if data && data.error
          @client_id = undefined
          @_ajaxInit(force: true)
        @_ajaxReceiveWorking = false
        @_ajaxReceive()
      error: (data) =>
        @client_id = undefined
        @_ajaxInit(force: true)
        @_ajaxReceiveWorking = false
    )

class Modal extends App.ControllerModal
  buttonClose: false
  buttonCancel: false
  buttonSubmit: false
  backdrop: 'static'
  keyboard: false
  head: 'Lost network connection!'

  content: ->
    'Trying to reconnect...'
