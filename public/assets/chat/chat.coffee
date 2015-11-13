do($ = window.jQuery, window) ->

  scripts = document.getElementsByTagName('script')
  myScript = scripts[scripts.length - 1]
  scriptHost = myScript.src.match(".*://([^:/]*).*")[1]

  # Define the plugin class
  class ZammadChat

    defaults:
      invitationPhrase: '<strong>Chat</strong> with us!'
      agentPhrase: ' is helping you'
      show: true
      target: $('body')
      host: ''
      port: 6042
      debug: false

    _messageCount: 0
    isOpen: true
    blinkOnlineInterval: null
    stopBlinOnlineStateTimeout: null
    showTimeEveryXMinutes: 1
    lastTimestamp: null
    lastAddedType: null
    inputTimeout: null
    isTyping: false
    isOnline: true
    initialQueueDelay: 10000
    wsReconnectEnable: true
    strings:
      'Online': 'Online'
      'Offline': 'Offline'
      'Connecting': 'Verbinden'
      'Connection re-established': 'Connection re-established'
      'Today': 'Heute'
      'Send': 'Senden'
      'Compose your message...': 'Ihre Nachricht...'
      'All colleges are busy.': 'Alle Kollegen sind belegt.'
      'You are on waiting list position <strong>%s</strong>.': 'Sie sind in der Warteliste an der Position <strong>%s</strong>.'
      'Start new conversation': 'Neue Konversation starten'
      'Since you didn\'t respond in the last %s your conversation with <strong>%s</strong> got closed.': 'Da sie in den letzten %s nichts geschrieben haben wurde ihre Konversation mit <strong>%s</strong> geschlossen.'
      'minutes': 'Minuten'
    sessionId: undefined

    T: (string, items...) =>
      if !@strings[string]
        @log 'notice', "Translation needed for '#{string}'"
      translation = @strings[string] || string
      if items
        for item in items
          translation = translation.replace(/%s/, item)

      translation

    log: (level, string...) =>
      return if !@options.debug && level is 'debug'
      string.unshift(level)
      console.log.apply console, string

    view: (name) =>
      return (options) =>
        if !options
          options = {}

        options.T = @T
        return window.zammadChatTemplates[name](options)

    constructor: (options) ->

      # check prerequisites
      if !window.WebSocket or !sessionStorage
        @log 'notice', 'Chat: Browser not supported!'
        return

      @options = $.extend {}, @defaults, options
      @el = $(@view('chat')(@options))
      @options.target.append @el

      @input = @el.find('.zammad-chat-input')

      @el.find('.js-chat-open').click => @open()
      @el.find('.js-chat-close').click @close
      @el.find('.zammad-chat-controls').on 'submit', @onSubmit
      @input.on
        keydown: @checkForEnter
        input: @onInput

      @wsConnect()

    checkForEnter: (event) =>
      if not event.shiftKey and event.keyCode is 13
        event.preventDefault()
        @sendMessage()

    send: (event, data) =>
      @log 'debug', 'ws:send', event, data
      pipe = JSON.stringify
        event: event
        data: data
      @ws.send pipe

    onWebSocketMessage: (e) =>
      pipes = JSON.parse( e.data )

      for pipe in pipes
        @log 'debug', 'ws:onmessage', pipe
        switch pipe.event
          when 'chat_session_message'
            return if pipe.data.self_written
            @receiveMessage pipe.data
          when 'chat_session_typing'
            return if pipe.data.self_written
            @onAgentTypingStart()
          when 'chat_session_start'
            @onConnectionEstablished pipe.data
          when 'chat_session_queue'
            @onQueueScreen pipe.data
          when 'chat_session_closed'
            @onSessionClosed pipe.data
          when 'chat_session_left'
            @onSessionClosed pipe.data
          when 'chat_status_customer'
            switch pipe.data.state
              when 'online'
                @sessionId = undefined
                @onReady()
                @log 'debug', 'Zammad Chat: ready'
              when 'offline'
                @log 'debug', 'Zammad Chat: No agent online'
                @wsClose()
              when 'chat_disabled'
                @log 'debug', 'Zammad Chat: Chat is disabled'
                @wsClose()
              when 'no_seats_available'
                @log 'debug', 'Zammad Chat: Too many clients in queue. Clients in queue: ', pipe.data.queue
                @wsClose()
              when 'reconnect'
                @log 'debug', 'old messages', pipe.data.session
                @reopenSession pipe.data

    onReady: =>
      if @options.show
        @show()

    reopenSession: (data) =>
      unfinishedMessage = sessionStorage.getItem 'unfinished_message'

      # rerender chat history
      if data.agent
        @onConnectionEstablished(data)

        for message in data.session
          @renderMessage
            message: message.content
            id: message.id
            from: if message.created_by_id then 'agent' else 'customer'

        if unfinishedMessage
          @input.val unfinishedMessage

      # show wait list
      if data.position
        @onQueue data

      @show()
      @open()
      @scrollToBottom()

      if unfinishedMessage
        @input.focus()

    onInput: =>
      # remove unread-state from messages
      @el.find('.zammad-chat-message--unread')
        .removeClass 'zammad-chat-message--unread'

      sessionStorage.setItem 'unfinished_message', @input.val()

      @onTypingStart()

    onTypingStart: ->

      clearTimeout(@isTypingTimeout) if @isTypingTimeout

      # fire typingEnd after 5 seconds
      @isTypingTimeout = setTimeout @onTypingEnd, 1500

      # send typing start event
      if !@isTyping
        @isTyping = true
        @send 'chat_session_typing',
          session_id: @sessionId

    onTypingEnd: =>
      @isTyping = false

    onSubmit: (event) =>
      event.preventDefault()
      @sendMessage()

    sendMessage: ->
      message = @input.val()

      return if !message

      sessionStorage.removeItem 'unfinished_message'

      messageElement = @view('message')
        message: message
        from: 'customer'
        id: @_messageCount++

      @maybeAddTimestamp()

      # add message before message typing loader
      if @el.find('.zammad-chat-message--typing').size()
        @lastAddedType = 'typing-placeholder'
        @el.find('.zammad-chat-message--typing').before messageElement
      else
        @lastAddedType = 'message--customer'
        @el.find('.zammad-chat-body').append messageElement

      @input.val('')
      @scrollToBottom()

      @isTyping = false

      # send message event
      @send 'chat_session_message',
        content: message
        id: @_messageCount
        session_id: @sessionId

    receiveMessage: (data) =>
      # hide writing indicator
      @onAgentTypingEnd()

      @maybeAddTimestamp()

      @renderMessage
        message: data.message.content
        id: data.id
        from: 'agent'

    renderMessage: (data) =>
      @lastAddedType = "message--#{ data.from }"
      unread = document.hidden ? " zammad-chat-message--unread" : ""
      @el.find('.zammad-chat-body').append @view('message')(data)
      @scrollToBottom()

    open: =>
      if @isOpen
        @show()

      if !@sessionId
        @showLoader()

      @el
        .addClass('zammad-chat-is-open')

      if !@sessionId
        @el.animate { bottom: 0 }, 500, @onOpenAnimationEnd
      else
        @el.css 'bottom', 0
        @onOpenAnimationEnd()

      @isOpen = true

      if !@sessionId
        @session_init()

    onOpenAnimationEnd: =>
      #@showTimeout()

    close: (event) =>
      event.stopPropagation() if event

      # only close if session_id exists
      return if !@sessionId

      # stop delay of initial queue position
      if @onInitialQueueDelayId
        clearTimeout(@onInitialQueueDelayId)

      sessionStorage.removeItem 'sessionId'
      sessionStorage.removeItem 'unfinished_message'

      @closeWindow()

    closeWindow: =>
      remainerHeight = @el.height() - @el.find('.zammad-chat-header').outerHeight()
      @el.animate { bottom: -remainerHeight }, 500, @onCloseAnimationEnd

    onCloseAnimationEnd: =>
      @el.removeClass('zammad-chat-is-open')
      @disconnect()
      @isOpen = false

      @send 'chat_session_close',
        session_id: @sessionId

      @setSessionId undefined

    hide: ->
      @el.removeClass('zammad-chat-is-visible')

    show: ->
      @el.addClass('zammad-chat-is-visible')

      @input.autoGrow
        extraLine: false

      remainerHeight = @el.height() - @el.find('.zammad-chat-header').outerHeight()

      @el.css 'bottom', -remainerHeight

    disableInput: ->
      @input.prop('disabled', true)
      @el.find('.zammad-chat-send').prop('disabled', true)

    enableInput: ->
      @input.prop('disabled', false)
      @el.find('.zammad-chat-send').prop('disabled', false)

    onQueueScreen: (data) =>
      @setSessionId data.session_id

      # delay initial queue position, show connecting first
      show = =>
        @onQueue data
      if @initialQueueDelay && !@onInitialQueueDelayId
        @onInitialQueueDelayId = setTimeout(show, @initialQueueDelay)
        return

      # stop delay of initial queue position
      if @onInitialQueueDelayId
        clearTimeout(@onInitialQueueDelayId)

      # show queue position
      show()

    onQueue: (data) =>
      @log 'notice', 'onQueue', data.position
      @inQueue = true

      @el.find('.zammad-chat-body').html @view('waiting')
        position: data.position

    onAgentTypingStart: =>
      if @stopTypingId
        clearTimeout(@stopTypingId)
      @stopTypingId = setTimeout(@onAgentTypingEnd, 3000)

      # never display two typing indicators
      return if @el.find('.zammad-chat-message--typing').size()

      @maybeAddTimestamp()

      @el.find('.zammad-chat-body').append @view('typingIndicator')()

      @scrollToBottom()

    onAgentTypingEnd: =>
      @el.find('.zammad-chat-message--typing').remove()

    maybeAddTimestamp: ->
      timestamp = Date.now()

      if !@lastTimestamp or (timestamp - @lastTimestamp) > @showTimeEveryXMinutes * 60000
        label = @T('Today')
        time = new Date().toTimeString().substr 0,5
        if @lastAddedType is 'timestamp'
          # update last time
          @updateLastTimestamp label, time
          @lastTimestamp = timestamp
        else
          # add new timestamp
          @el.find('.zammad-chat-body').append @view('timestamp')
            label: label
            time: time
          @lastTimestamp = timestamp
          @lastAddedType = 'timestamp'
          @scrollToBottom()

    updateLastTimestamp: (label, time) ->
      @el.find('.zammad-chat-body')
        .find('.zammad-chat-timestamp')
        .last()
        .replaceWith @view('timestamp')
          label: label
          time: time

    addStatus: (status) ->
      @maybeAddTimestamp()

      @el.find('.zammad-chat-body').append @view('status')
        status: status

      @scrollToBottom()

    scrollToBottom: ->
      @el.find('.zammad-chat-body').scrollTop($('.zammad-chat-body').prop('scrollHeight'))

    session_init: ->
      @send('chat_session_init')

    detectHost: ->
      @options.host = "ws://#{ scriptHost }"

    wsConnect: =>
      @detectHost() if !@options.host

      @log 'notice', "Connecting to #{@options.host}:#{@options.port}"
      @ws = new window.WebSocket("#{@options.host}:#{@options.port}")
      @ws.onopen = @onWebSocketOpen

      @ws.onmessage = @onWebSocketMessage

      @ws.onclose = (e) =>
        @log 'debug', 'close websocket connection'
        if @wsReconnectEnable
          @reconnect()
        @setAgentOnlineState(false)

      @ws.onerror = (e) =>
        @log 'debug', 'ws:onerror', e

    wsClose: =>
      @wsReconnectEnable = false
      @ws.close()

    wsReconnect: =>
      if @reconnectDelayId
        clearTimeout(@reconnectDelayId)
      @reconnectDelayId = setTimeout(@wsConnect, 5000)

    onWebSocketOpen: =>
      @sessionId = sessionStorage.getItem('sessionId')
      @log 'debug', 'ws connected'

      @send 'chat_status_customer',
        session_id: @sessionId

      @setAgentOnlineState(true)

    reconnect: =>
      # set status to connecting
      @log 'notice', 'reconnecting'
      @disableInput()
      @lastAddedType = 'status'
      @el.find('.zammad-chat-agent-status').attr('data-status', 'connecting').text @T('Reconnecting')
      @addStatus @T('Connection lost')
      @wsReconnect()

    onConnectionReestablished: =>
      # set status back to online
      @lastAddedType = 'status'
      @el.find('.zammad-chat-agent-status').attr('data-status', 'online').text @T('Online')
      @addStatus @T('Connection re-established')

    onSessionClosed: (data) ->
      @addStatus @T('Chat closed by %s', data.realname)
      @disableInput()

    disconnect: ->
      @showLoader()
      @el.find('.zammad-chat-welcome').removeClass('zammad-chat-is-hidden')
      @el.find('.zammad-chat-agent').addClass('zammad-chat-is-hidden')
      @el.find('.zammad-chat-agent-status').addClass('zammad-chat-is-hidden')

    setSessionId: (id) =>
      @sessionId = id
      if id is undefined
        sessionStorage.removeItem 'sessionId'
      else
        sessionStorage.setItem 'sessionId', id

    onConnectionEstablished: (data) =>
      # stop delay of initial queue position
      if @onInitialQueueDelayId
        clearTimeout @onInitialQueueDelayId

      @inQueue = false
      if data.agent
        @agent = data.agent
      if data.session_id
        @setSessionId data.session_id

      @el.find('.zammad-chat-agent').html @view('agent')
        agent: @agent

      @enableInput()

      @el.find('.zammad-chat-body').empty()
      @el.find('.zammad-chat-welcome').addClass('zammad-chat-is-hidden')
      @el.find('.zammad-chat-agent').removeClass('zammad-chat-is-hidden')
      @el.find('.zammad-chat-agent-status').removeClass('zammad-chat-is-hidden')
      @input.focus()

    showTimeout: ->
      @el.find('.zammad-chat-body').html @view('timeout')
        agent: @agent.name
        delay: 10
        unit: @T('minutes')

    showLoader: ->
      @el.find('.zammad-chat-body').html @view('loader')()

    setAgentOnlineState: (state) =>
      @isOnline = state
      @el
        .find('.zammad-chat-agent-status')
        .toggleClass('zammad-chat-is-online', state)
        .text if state then @T('Online') else @T('Offline')

  window.ZammadChat = ZammadChat
