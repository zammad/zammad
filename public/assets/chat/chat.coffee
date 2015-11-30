do($ = window.jQuery, window) ->

  scripts = document.getElementsByTagName('script')
  myScript = scripts[scripts.length - 1]
  scriptHost = myScript.src.match('.*://([^:/]*).*')[1]

  # Define the plugin class
  class ZammadChat

    defaults:
      chatId: undefined
      show: true
      target: $('body')
      host: ''
      debug: false
      flat: false
      lang: undefined
      cssAutoload: true
      cssUrl: undefined
      fontSize: undefined
      buttonClass: 'open-zammad-chat'
      inactiveClass: 'is-inactive'
      title: '<strong>Chat</strong> with us!'
      idleTimeout: 8
      inactiveTimeout: 20

    _messageCount: 0
    isOpen: true
    blinkOnlineInterval: null
    stopBlinOnlineStateTimeout: null
    showTimeEveryXMinutes: 1
    lastTimestamp: null
    lastAddedType: null
    inputTimeout: null
    isTyping: false
    state: 'offline'
    initialQueueDelay: 10000
    wsReconnectEnable: true
    translations:
      de:
        '<strong>Chat</strong> with us!': '<strong>Chat</strong> mit uns!'
        'Online': 'Online'
        'Online': 'Online'
        'Offline': 'Offline'
        'Connecting': 'Verbinden'
        'Connection re-established': 'Verbindung wiederhergestellt'
        'Today': 'Heute'
        'Send': 'Senden'
        'Compose your message...': 'Ihre Nachricht...'
        'All colleges are busy.': 'Alle Kollegen sind belegt.'
        'You are on waiting list position <strong>%s</strong>.': 'Sie sind in der Warteliste an der Position <strong>%s</strong>.'
        'Start new conversation': 'Neue Konversation starten'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Da Sie in den letzten %s Minuten nichts geschrieben haben wurde Ihre Konversation mit <strong>%s</strong> geschlossen.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Da Sie in den letzten %s Minuten nichts geschrieben haben wurde Ihre Konversation geschlossen.'
    sessionId: undefined

    T: (string, items...) =>
      if @options.lang && @options.lang isnt 'en'
        if !@translations[@options.lang]
          @log 'notice', "Translation '#{@options.lang}' needed!"
        else
          translations = @translations[@options.lang]
          if !translations[string]
            @log 'notice', "Translation needed for '#{string}'"
          string = translations[string] || string
      if items
        for item in items
          string = string.replace(/%s/, item)
      string

    log: (level, string...) =>
      return if !@options.debug && level is 'debug'
      string.unshift(level)
      console.log.apply console, string

    view: (name) =>
      return (options) =>
        if !options
          options = {}

        options.T = @T
        options.background = @options.background
        options.flat = @options.flat
        options.fontSize = @options.fontSize
        return window.zammadChatTemplates[name](options)

    constructor: (options) ->
      @options = $.extend {}, @defaults, options

      # check prerequisites
      if !$
        @state = 'unsupported'
        @log 'notice', 'Chat: no jquery found!'
        return
      if !window.WebSocket or !sessionStorage
        @state = 'unsupported'
        @log 'notice', 'Chat: Browser not supported!'
        return
      if !@options.chatId
        @state = 'unsupported'
        @log 'error', 'Chat: need chatId as option!'
        return

      # detect language
      if !@options.lang
        @options.lang = $('html').attr('lang')
      if @options.lang
        @options.lang = @options.lang.replace(/-.+?$/, '') # replace "-xx" of xx-xx
        @log 'debug', "lang: #{@options.lang}"

      @el = $(@view('chat')(
        title: @options.title
      ))
      @options.target.append @el

      @input = @el.find('.zammad-chat-input')

      # disable open button
      $(".#{ @options.buttonClass }").addClass @inactiveClass

      @el.find('.js-chat-open').click @open
      @el.find('.js-chat-close').click @close
      @el.find('.zammad-chat-controls').on 'submit', @onSubmit
      @input.on
        keydown: @checkForEnter
        input: @onInput

      @wsConnect()

      @loadCss()

    checkForEnter: (event) =>
      if not event.shiftKey and event.keyCode is 13
        event.preventDefault()
        @sendMessage()

    send: (event, data = {}) =>
      data.chat_id = @options.chatId
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
          when 'chat_error'
            @log 'notice', pipe.data
            if pipe.data && pipe.data.state is 'chat_disabled'
              @wsClose()
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
                @onError 'Zammad Chat: No agent online'
                @state = 'off'
                @hide()
                @wsClose()
              when 'chat_disabled'
                @onError 'Zammad Chat: Chat is disabled'
                @state = 'off'
                @hide()
                @wsClose()
              when 'no_seats_available'
                @onError "Zammad Chat: Too many clients in queue. Clients in queue: #{pipe.data.queue}"
                @state = 'off'
                @hide()
                @wsClose()
              when 'reconnect'
                @log 'debug', 'old messages', pipe.data.session
                @reopenSession pipe.data

    onReady: =>
      $(".#{ @options.buttonClass }").click(@open).removeClass(@inactiveClass)

      if @options.show
        @show()

    onError: (message) =>
      @log 'debug', message
      $(".#{ @options.buttonClass }").hide()

    reopenSession: (data) =>
      @inactiveTimeoutStart()

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

      @onTyping()

    onTyping: ->

      # send typing start event only every 1.5 seconds
      return if @isTyping && @isTyping > new Date(new Date().getTime() - 1500)
      @isTyping = new Date()
      @send 'chat_session_typing',
        session_id: @sessionId
      @inactiveTimeoutStart()

    onSubmit: (event) =>
      event.preventDefault()
      @sendMessage()

    sendMessage: ->
      message = @input.val()
      return if !message

      @inactiveTimeoutStart()

      sessionStorage.removeItem 'unfinished_message'

      messageElement = @view('message')
        message: message
        from: 'customer'
        id: @_messageCount++
        unreadClass: ''

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

      # send message event
      @send 'chat_session_message',
        content: message
        id: @_messageCount
        session_id: @sessionId

    receiveMessage: (data) =>
      @inactiveTimeoutStart()

      # hide writing indicator
      @onAgentTypingEnd()

      @maybeAddTimestamp()

      @renderMessage
        message: data.message.content
        id: data.id
        from: 'agent'

    renderMessage: (data) =>
      @lastAddedType = "message--#{ data.from }"
      data.unreadClass = if document.hidden then ' zammad-chat-message--unread' else ''
      @el.find('.zammad-chat-body').append @view('message')(data)
      @scrollToBottom()

    open: =>
      if @isOpen
        @show()

      if !@sessionId
        @showLoader()

      @el.addClass('zammad-chat-is-open')

      if !@sessionId
        @el.animate { bottom: 0 }, 500, @onOpenAnimationEnd
      else
        @el.css 'bottom', 0
        @onOpenAnimationEnd()

      @isOpen = true

      if !@sessionId
        @sessionInit()

    onOpenAnimationEnd: =>
      @idleTimeoutStop()

    close: (event) =>
      return @state if @state is 'off' or @state is 'unsupported'
      event.stopPropagation() if event

      # only close if session_id exists
      return if !@sessionId

      # send close
      @send 'chat_session_close',
        session_id: @sessionId

      # stop timer
      @inactiveTimeoutStop()

      # delete input store
      sessionStorage.removeItem 'unfinished_message'

      # stop delay of initial queue position
      if @onInitialQueueDelayId
        clearTimeout(@onInitialQueueDelayId)

      if event
        @closeWindow()

      @setSessionId undefined

    closeWindow: =>
      @el.removeClass('zammad-chat-is-open')
      remainerHeight = @el.height() - @el.find('.zammad-chat-header').outerHeight()
      @el.animate { bottom: -remainerHeight }, 500, @onCloseAnimationEnd

    onCloseAnimationEnd: =>
      @el.removeClass('zammad-chat-is-visible')
      @disconnect()
      @isOpen = false

      # restart connection
      @onWebSocketOpen()

    hide: ->
      @el.removeClass('zammad-chat-is-shown')

    show: ->
      return @state if @state is 'off' or @state is 'unsupported'

      @el.addClass('zammad-chat-is-shown')

      if !@inputInitialized
        @inputInitialized = true
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

    sessionInit: ->
      @send('chat_session_init')

    detectHost: ->
      protocol = 'ws://'
      if window.location.protocol is 'https:'
        protocol = 'wss://'
      @options.host = "#{ protocol }#{ scriptHost }/ws"

    wsConnect: =>
      @detectHost() if !@options.host

      @log 'debug', "Connecting to #{@options.host}"
      @ws = new window.WebSocket("#{@options.host}")
      @ws.onopen = @onWebSocketOpen

      @ws.onmessage = @onWebSocketMessage

      @ws.onclose = (e) =>
        @log 'debug', 'close websocket connection'
        if @wsReconnectEnable
          @reconnect()

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
      @idleTimeoutStart()
      @sessionId = sessionStorage.getItem('sessionId')
      @log 'debug', 'ws connected'

      @send 'chat_status_customer',
        session_id: @sessionId

      @setAgentOnlineState 'online'

    reconnect: =>
      # set status to connecting
      @log 'notice', 'reconnecting'
      @disableInput()
      @lastAddedType = 'status'
      @setAgentOnlineState 'connecting'
      @addStatus @T('Connection lost')
      @wsReconnect()

    onConnectionReestablished: =>
      # set status back to online
      @lastAddedType = 'status'
      @setAgentOnlineState 'online'
      @addStatus @T('Connection re-established')

    onSessionClosed: (data) ->
      @addStatus @T('Chat closed by %s', data.realname)
      @disableInput()
      @setAgentOnlineState 'offline'
      @inactiveTimeoutStop()

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

      @setAgentOnlineState 'online'

    showTimeout: ->
      @el.find('.zammad-chat-body').html @view('timeout')
        agent: @agent.name
        delay: @options.inactiveTimeout
      @close()
      reload = ->
        location.reload()
      @el.find('.js-restart').click reload

    showLoader: ->
      @el.find('.zammad-chat-body').html @view('loader')()

    setAgentOnlineState: (state) =>
      @state = state
      capitalizedState = state.charAt(0).toUpperCase() + state.slice(1)
      @el
        .find('.zammad-chat-agent-status')
        .attr('data-status', state)
        .text @T(capitalizedState)

    loadCss: ->
      return if !@options.cssAutoload
      url = @options.cssUrl
      if !url
        url = @options.host
          .replace(/^wss/i, 'https')
          .replace(/^ws/i, 'http')
          .replace(/\/ws/i, '')
        url += '/assets/chat/chat.css'

      @log 'debug', "load css from '#{url}'"
      styles = "@import url('#{url}');"
      newSS = document.createElement('link')
      newSS.rel = 'stylesheet'
      newSS.href = 'data:text/css,' + escape(styles)
      document.getElementsByTagName('head')[0].appendChild(newSS)

    inactiveTimeoutStart: =>
      @inactiveTimeoutStop()
      delay = =>
        @log 'debug', "Inactive timeout of #{@options.inactiveTimeout} minutes, show timeout screen."
        @state = 'off'
        @setAgentOnlineState 'offline'
        @showTimeout()
        @wsClose()
      @inactiveTimeoutStopDelayId = setTimeout(delay, @options.inactiveTimeout * 1000 * 60)

    inactiveTimeoutStop: =>
      return if !@inactiveTimeoutStopDelayId
      clearTimeout(@inactiveTimeoutStopDelayId)

    idleTimeoutStart: =>
      @idleTimeoutStop()
      delay = =>
        @log 'debug', "Idle timeout of #{@options.idleTimeout} minutes, hide widget"
        @state = 'off'
        @hide()
        @wsClose()
      @idleTimeoutStopDelayId = setTimeout(delay, @options.idleTimeout * 1000 * 60)

    idleTimeoutStop: =>
      return if !@idleTimeoutStopDelayId
      clearTimeout(@idleTimeoutStopDelayId)

  window.ZammadChat = ZammadChat
