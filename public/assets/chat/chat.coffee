do($ = window.jQuery, window) ->

  # Define the plugin class
  class ZammadChat

    defaults:
      invitationPhrase: '<strong>Chat</strong> with us!'
      agentPhrase: '%%agent%% is helping you'
      show: true
      target: $('body')

    isOpen: false
    blinkOnlineInterval: null
    stopBlinOnlineStateTimeout: null
    showTimeEveryXMinutes: 1
    lastTimestamp: null
    lastAddedType: null
    inputTimeout: null
    isTyping: false
    isOnline: true
    strings:
      'Online': 'Online'
      'Offline': 'Offline'
      'Connecting': 'Connecting'
      'Connection re-established': 'Connection re-established'
      'Today': 'Today'

    T: (string) ->
      return @strings[string]

    view: (name) ->
      return window.zammadChatTemplates[name]

    constructor: (el, options) ->
      @options = $.extend {}, @defaults, options
      @el = $(@view('chat')())
      @options.target.append @el

      @setAgentOnlineState @isOnline

      @el.find('.zammad-chat-header').click @toggle
      @el.find('.zammad-chat-controls').on 'submit', @onSubmit
      @el.find('.zammad-chat-input').on(
        keydown: @checkForEnter
        input: @onInput
      ).autoGrow { extraLine: false }

      if !window.WebSocket
        console.log('no websockets available')
        return

      zammad_host = 'ws://localhost:6042'
      @ws = new window.WebSocket(zammad_host)
      console.log("connecting ws #{zammad_host}")

      @ws.onopen = =>
        console.log('ws connected')

      @ws.onmessage = (e) =>
        pipe = JSON.parse( e.data )
        console.log 'debug', 'ws:onmessage', pipe

      @ws.onclose = (e) =>
        console.log 'debug', 'close websocket connection'

      @ws.onerror = (e) =>
        console.log 'debug', 'ws:onerror', e

    checkForEnter: (event) =>
      if not event.shiftKey and event.keyCode is 13
        event.preventDefault()
        @sendMessage()

    onInput: =>
      # remove unread-state from messages
      @el.find('.zammad-chat-message--unread')
        .removeClass 'zammad-chat-message--unread'

      clearTimeout(@inputTimeout) if @inputTimeout

      # fire typingEnd after 5 seconds
      @inputTimeout = setTimeout @onTypingEnd, 5000

      @onTypingStart() if @isTyping

    onTypingStart: ->
      # send typing start event
      @isTyping = true

    onTypingEnd: =>
      # send typing end event
      @isTyping = false

    onSubmit: (event) =>
      event.preventDefault()
      @sendMessage()

    sendMessage: ->
      message = @el.find('.zammad-chat-input').val()

      if message
        messageElement = @view('message')
          message: message
          from: 'customer'

        @maybeAddTimestamp()

        # add message before message typing loader
        if @el.find('.zammad-chat-message--typing').size()
          @lastAddedType = 'typing-placeholder'
          @el.find('.zammad-chat-message--typing').before messageElement 
        else
          @lastAddedType = 'message--customer'
          @el.find('.zammad-chat-body').append messageElement

        @el.find('.zammad-chat-input').val('')
        @scrollToBottom()

        @isTyping = false
        # send message event

    receiveMessage: (message) =>
      # hide writing indicator
      @onAgentTypingEnd()

      @maybeAddTimestamp()

      @lastAddedType = 'message--agent'
      unread = document.hidden ? " zammad-chat-message--unread" : ""
      @el.find('.zammad-chat-body').append @view('message')
        message: message
        from: 'agent'
      @scrollToBottom()

    toggle: =>
      if @isOpen then @close() else @open()

    open: ->
      @el
        .addClass('zammad-chat-is-open')
        .animate { bottom: 0 }, 500, @onOpenAnimationEnd

    onOpenAnimationEnd: =>
      @isOpen = true
      setTimeout @onConnectionEstablished, 1180
      setTimeout @onAgentTypingStart, 2000
      setTimeout @receiveMessage, 5000, "Hello! How can I help you?"
      @connect()

    close: ->
      remainerHeight = @el.height() - @el.find('.zammad-chat-header').outerHeight()
      @el.animate { bottom: -remainerHeight }, 500, @onCloseAnimationEnd

    onCloseAnimationEnd: =>
      @el.removeClass('zammad-chat-is-open')
      @disconnect()
      @isOpen = false

    hide: ->
      @el.removeClass('zammad-chat-is-visible')

    show: ->
      @el.addClass('zammad-chat-is-visible')

      remainerHeight = @el.outerHeight() - @el.find('.zammad-chat-header').outerHeight()

      @el.css 'bottom', -remainerHeight

    onAgentTypingStart: =>
      # never display two loaders
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
          @addStatus label, time
          @lastTimestamp = timestamp
          @lastAddedType = 'timestamp'

    updateLastTimestamp: (label, time) ->
      @el.find('.zammad-chat-body')
        .find('.zammad-chat-status')
        .last()
        .replaceWith @view('status')
          label: label
          time: time

    addStatus: (label, time) ->
      @el.find('.zammad-chat-body').append @view('status')
        label: label
        time: time

    scrollToBottom: ->
      @el.find('.zammad-chat-body').scrollTop($('.zammad-chat-body').prop('scrollHeight'))

    connect: ->


    reconnect: =>
      # set status to connecting
      @lastAddedType = 'status'
      @el.find('.zammad-chat-agent-status').attr('data-status', 'connecting').text @T('Connecting')
      @addStatus @T('Connection lost')

    onConnectionReestablished: =>
      # set status back to online
      @lastAddedType = 'status'
      @el.find('.zammad-chat-agent-status').attr('data-status', 'online').text @T('Online')
      @addStatus @T('Connection re-established')

    disconnect: ->
      @el.find('.zammad-chat-loader').removeClass('zammad-chat-is-hidden');
      @el.find('.zammad-chat-welcome').removeClass('zammad-chat-is-hidden');
      @el.find('.zammad-chat-agent').addClass('zammad-chat-is-hidden');
      @el.find('.zammad-chat-agent-status').addClass('zammad-chat-is-hidden');

    onConnectionEstablished: =>
      @el.find('.zammad-chat-loader').addClass('zammad-chat-is-hidden');
      @el.find('.zammad-chat-welcome').addClass('zammad-chat-is-hidden');
      @el.find('.zammad-chat-agent').removeClass('zammad-chat-is-hidden');
      @el.find('.zammad-chat-agent-status').removeClass('zammad-chat-is-hidden');
      @el.find('.zammad-chat-input').focus();

    setAgentOnlineState: (state) =>
      @isOnline = state
      @el
        .find('.zammad-chat-agent-status')
        .toggleClass('zammad-chat-is-online', state)
        .text if state then @T('Online') else @T('Offline')

  $(document).ready ->
    window.zammadChat = new ZammadChat()
