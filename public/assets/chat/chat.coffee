do($ = window.jQuery, window) ->

  scripts = document.getElementsByTagName('script')
  myScript = scripts[scripts.length - 1]
  scriptHost = myScript.src.match('.*://([^:/]*).*')[1]

  # Define the plugin class
  class Base
    defaults:
      debug: false

    constructor: (options) ->
      @options = $.extend {}, @defaults, options
      @log = new Log(debug: @options.debug, logPrefix: @options.logPrefix || @logPrefix)

  class Log
    defaults:
      debug: false

    constructor: (options) ->
      @options = $.extend {}, @defaults, options

    debug: (items...) =>
      return if !@options.debug
      @log('debug', items)

    notice: (items...) =>
      @log('notice', items)

    error: (items...) =>
      @log('error', items)

    log: (level, items) =>
      items.unshift('||')
      items.unshift(level)
      items.unshift(@options.logPrefix)
      console.log.apply console, items

      return if !@options.debug
      logString = ''
      for item in items
        logString += ' '
        if typeof item is 'object'
          logString += JSON.stringify(item)
        else if item && item.toString
          logString += item.toString()
        else
          logString += item
      $('.js-chatLogDisplay').prepend('<div>' + logString + '</div>')

  class Timeout extends Base
    timeoutStartedAt: null
    logPrefix: 'timeout'
    defaults:
      debug: false
      timeout: 4
      timeoutIntervallCheck: 0.5

    constructor: (options) ->
      super(options)

    start: =>
      @stop()
      timeoutStartedAt = new Date
      check = =>
        timeLeft = new Date - new Date(timeoutStartedAt.getTime() + @options.timeout * 1000 * 60)
        @log.debug "Timeout check for #{@options.timeout} minutes (left #{timeLeft/1000} sec.)"#, new Date
        return if timeLeft < 0
        @stop()
        @options.callback()
      @log.debug "Start timeout in #{@options.timeout} minutes"#, new Date
      @intervallId = setInterval(check, @options.timeoutIntervallCheck * 1000 * 60)

    stop: =>
      return if !@intervallId
      @log.debug "Stop timeout of #{@options.timeout} minutes"#, new Date
      clearInterval(@intervallId)

  class Io extends Base
    logPrefix: 'io'
    constructor: (options) ->
      super(options)

    set: (params) =>
      for key, value of params
        @options[key] = value

    connect: =>
      @log.debug "Connecting to #{@options.host}"
      @ws = new window.WebSocket("#{@options.host}")
      @ws.onopen = (e) =>
        @log.debug 'onOpen', e
        @options.onOpen(e)
        @ping()

      @ws.onmessage = (e) =>
        pipes = JSON.parse(e.data)
        @log.debug 'onMessage', e.data
        for pipe in pipes
          if pipe.event is 'pong'
            @ping()
        if @options.onMessage
          @options.onMessage(pipes)

      @ws.onclose = (e) =>
        @log.debug 'close websocket connection', e
        if @pingDelayId
          clearTimeout(@pingDelayId)
        if @manualClose
          @log.debug 'manual close, onClose callback'
          @manualClose = false
          if @options.onClose
            @options.onClose(e)
        else
          @log.debug 'error close, onError callback'
          if @options.onError
            @options.onError('Connection lost...')

      @ws.onerror = (e) =>
        @log.debug 'onError', e
        if @options.onError
          @options.onError(e)

    close: =>
      @log.debug 'close websocket manually'
      @manualClose = true
      @ws.close()

    reconnect: =>
      @log.debug 'reconnect'
      @close()
      @connect()

    send: (event, data = {}) =>
      @log.debug 'send', event, data
      msg = JSON.stringify
        event: event
        data: data
      @ws.send msg

    ping: =>
      localPing = =>
        @send('ping')
      @pingDelayId = setTimeout(localPing, 29000)

  class ZammadChat extends Base
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
      idleTimeout: 6
      idleTimeoutIntervallCheck: 0.5
      inactiveTimeout: 8
      inactiveTimeoutIntervallCheck: 0.5
      waitingListTimeout: 4
      waitingListTimeoutIntervallCheck: 0.5

    logPrefix: 'chat'
    _messageCount: 0
    isOpen: false
    blinkOnlineInterval: null
    stopBlinOnlineStateTimeout: null
    showTimeEveryXMinutes: 2
    lastTimestamp: null
    lastAddedType: null
    inputTimeout: null
    isTyping: false
    state: 'offline'
    initialQueueDelay: 10000
    translations:
      de:
        '<strong>Chat</strong> with us!': '<strong>Chatte</strong> mit uns!'
        'Online': 'Online'
        'Online': 'Online'
        'Offline': 'Offline'
        'Connecting': 'Verbinden'
        'Connection re-established': 'Verbindung wiederhergestellt'
        'Today': 'Heute'
        'Send': 'Senden'
        'Compose your message...': 'Ihre Nachricht...'
        'All colleagues are busy.': 'Alle Kollegen sind belegt.'
        'You are on waiting list position <strong>%s</strong>.': 'Sie sind in der Warteliste an der Position <strong>%s</strong>.'
        'Start new conversation': 'Neue Konversation starten'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Da Sie in den letzten %s Minuten nichts geschrieben haben wurde Ihre Konversation mit <strong>%s</strong> geschlossen.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Da Sie in den letzten %s Minuten nichts geschrieben haben wurde Ihre Konversation geschlossen.'
    sessionId: undefined

    T: (string, items...) =>
      if @options.lang && @options.lang isnt 'en'
        if !@translations[@options.lang]
          @log.notice "Translation '#{@options.lang}' needed!"
        else
          translations = @translations[@options.lang]
          if !translations[string]
            @log.notice "Translation needed for '#{string}'"
          string = translations[string] || string
      if items
        for item in items
          string = string.replace(/%s/, item)
      string

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
      super(@options)

      # fullscreen
      @isFullscreen = (window.matchMedia and window.matchMedia('(max-width: 768px)').matches)
      @scrollRoot = $(@getScrollRoot())

      # check prerequisites
      if !$
        @state = 'unsupported'
        @log.notice 'Chat: no jquery found!'
        return
      if !window.WebSocket or !sessionStorage
        @state = 'unsupported'
        @log.notice 'Chat: Browser not supported!'
        return
      if !@options.chatId
        @state = 'unsupported'
        @log.error 'Chat: need chatId as option!'
        return

      # detect language
      if !@options.lang
        @options.lang = $('html').attr('lang')
      if @options.lang
        @options.lang = @options.lang.replace(/-.+?$/, '') # replace "-xx" of xx-xx
        @log.debug "lang: #{@options.lang}"

      # detect host
      @detectHost() if !@options.host

      @loadCss()

      @io = new Io(@options)
      @io.set(
        onOpen: @render
        onClose: @onWebSocketClose
        onMessage: @onWebSocketMessage
        onError: @onError
      )

      @io.connect()

    getScrollRoot: ->
      return document.scrollingElement if 'scrollingElement' of document
      html = document.documentElement
      start = html.scrollTop
      html.scrollTop = start + 1
      end = html.scrollTop
      html.scrollTop = start
      return if end > start then html else document.body

    render: =>
      if !@el || !$('.zammad-chat').get(0)
        @renderBase()

      # disable open button
      $(".#{ @options.buttonClass }").addClass @inactiveClass

      @setAgentOnlineState 'online'

      @log.debug 'widget rendered'

      @startTimeoutObservers()
      @idleTimeout.start()

      # get current chat status
      @sessionId = sessionStorage.getItem('sessionId')
      @send 'chat_status_customer',
        session_id: @sessionId

    renderBase: ->
      @el = $(@view('chat')(
        title: @options.title
      ))
      @options.target.append @el

      @input = @el.find('.zammad-chat-input')

      # start bindings
      @el.find('.js-chat-open').click @open
      @el.find('.js-chat-toggle').click @toggle
      @el.find('.zammad-chat-controls').on 'submit', @onSubmit
      @input.on
        keydown: @checkForEnter
        input: @onInput
      $(window).on('beforeunload', =>
        @onLeaveTemporary()
      )
      $(window).bind('hashchange', =>
        return if @isOpen
        @idleTimeout.start()
      )

      if @isFullscreen
        @input.on
          focus: @onFocus
          focusout: @onFocusOut

    checkForEnter: (event) =>
      if not event.shiftKey and event.keyCode is 13
        event.preventDefault()
        @sendMessage()

    send: (event, data = {}) =>
      data.chat_id = @options.chatId
      @io.send(event, data)

    onWebSocketMessage: (pipes) =>
      for pipe in pipes
        @log.debug 'ws:onmessage', pipe
        switch pipe.event
          when 'chat_error'
            @log.notice pipe.data
            if pipe.data && pipe.data.state is 'chat_disabled'
              @destroy(remove: true)
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

                if !@options.cssAutoload || @cssLoaded
                  @onReady()
                else
                  @socketReady = true
              when 'offline'
                @onError 'Zammad Chat: No agent online'
              when 'chat_disabled'
                @onError 'Zammad Chat: Chat is disabled'
              when 'no_seats_available'
                @onError "Zammad Chat: Too many clients in queue. Clients in queue: #{pipe.data.queue}"
              when 'reconnect'
                @onReopenSession pipe.data

    onReady: ->
      @log.debug 'widget ready for use'
      $(".#{ @options.buttonClass }").click(@open).removeClass(@inactiveClass)

      if @options.show
        @show()

    onError: (message) =>
      @log.debug message
      @addStatus(message)
      $(".#{ @options.buttonClass }").hide()
      if @isOpen
        @disableInput()
        @destroy(remove: false)
      else
        @destroy(remove: true)

    onReopenSession: (data) =>
      @log.debug 'old messages', data.session
      @inactiveTimeout.start()

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

    onFocus: =>
      $(window).scrollTop(10)
      keyboardShown = $(window).scrollTop() > 0
      $(window).scrollTop(0)

      if keyboardShown
        @log.notice 'virtual keyboard shown'
        # on keyboard shown
        # can't measure visible area height :(

    onFocusOut: ->
      # on keyboard hidden

    onTyping: ->

      # send typing start event only every 1.5 seconds
      return if @isTyping && @isTyping > new Date(new Date().getTime() - 1500)
      @isTyping = new Date()
      @send 'chat_session_typing',
        session_id: @sessionId
      @inactiveTimeout.start()

    onSubmit: (event) =>
      event.preventDefault()
      @sendMessage()

    sendMessage: ->
      message = @input.val()
      return if !message

      @inactiveTimeout.start()

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
      @inactiveTimeout.start()

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
        @log.debug 'widget already open, block'
        return

      @isOpen = true
      @log.debug 'open widget'

      if !@sessionId
        @showLoader()

      @el.addClass('zammad-chat-is-open')

      if !@sessionId
        @el.animate { bottom: 0 }, 500, @onOpenAnimationEnd
        sendDelayedInit = =>
          @send('chat_session_init')
        @initDelayId = setTimeout(sendDelayedInit, 1000)
      else
        @el.css 'bottom', 0
        @onOpenAnimationEnd()

    onOpenAnimationEnd: =>
      @idleTimeout.stop()

      if @isFullscreen
        @disableScrollOnRoot()

    sessionClose: =>
      # send close
      @send 'chat_session_close',
        session_id: @sessionId

      # stop timer
      @inactiveTimeout.stop()
      @waitingListTimeout.stop()

      # delete input store
      sessionStorage.removeItem 'unfinished_message'

      # stop delay of initial queue position
      if @onInitialQueueDelayId
        clearTimeout(@onInitialQueueDelayId)

      @setSessionId undefined

    toggle: (event) =>
      if @isOpen
        @close(event)
      else
        @open(event)

    close: (event) =>
      if !@isOpen
        @log.debug 'can\'t close widget, it\'s not open'
        return
      if @initDelayId
        clearTimeout(@initDelayId)
      if !@sessionId
        @log.debug 'can\'t close widget without sessionId'
        return

      @log.debug 'close widget'

      event.stopPropagation() if event

      @sessionClose()

      if @isFullscreen
        @enableScrollOnRoot()

      # close window
      @el.removeClass('zammad-chat-is-open')
      remainerHeight = @el.height() - @el.find('.zammad-chat-header').outerHeight()
      @el.animate { bottom: -remainerHeight }, 500, @onCloseAnimationEnd

    onCloseAnimationEnd: =>
      @el.removeClass('zammad-chat-is-visible')

      @showLoader()
      @el.find('.zammad-chat-welcome').removeClass('zammad-chat-is-hidden')
      @el.find('.zammad-chat-agent').addClass('zammad-chat-is-hidden')
      @el.find('.zammad-chat-agent-status').addClass('zammad-chat-is-hidden')

      @isOpen = false

      @io.reconnect()

    onWebSocketClose: =>
      return if @isOpen
      if @el
        @el.removeClass('zammad-chat-is-shown')
        @el.removeClass('zammad-chat-is-loaded')

    show: ->
      return if @state is 'offline'

      @el.addClass('zammad-chat-is-loaded')

      if !@inputInitialized
        @inputInitialized = true
        @input.autoGrow
          extraLine: false

      remainerHeight = @el.height() - @el.find('.zammad-chat-header').outerHeight()

      console.log "el", @el.height()
      console.log "header", @el.find('.zammad-chat-header').outerHeight()

      @el.css 'bottom', -remainerHeight
      @el.addClass('zammad-chat-is-shown')

    disableInput: ->
      @input.prop('disabled', true)
      @el.find('.zammad-chat-send').prop('disabled', true)

    enableInput: ->
      @input.prop('disabled', false)
      @el.find('.zammad-chat-send').prop('disabled', false)

    hideModal: ->
      @el.find('.zammad-chat-modal').html ''

    onQueueScreen: (data) =>
      @setSessionId data.session_id

      # delay initial queue position, show connecting first
      show = =>
        @onQueue data
        @waitingListTimeout.start()

      if @initialQueueDelay && !@onInitialQueueDelayId
        @onInitialQueueDelayId = setTimeout(show, @initialQueueDelay)
        return

      # stop delay of initial queue position
      if @onInitialQueueDelayId
        clearTimeout(@onInitialQueueDelayId)

      # show queue position
      show()

    onQueue: (data) =>
      @log.notice 'onQueue', data.position
      @inQueue = true

      @el.find('.zammad-chat-modal').html @view('waiting')
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

    onLeaveTemporary: =>
      return if !@sessionId
      @send 'chat_session_leave_temporary',
        session_id: @sessionId

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
      return if !@el
      @el.find('.zammad-chat-body')
        .find('.zammad-chat-timestamp')
        .last()
        .replaceWith @view('timestamp')
          label: label
          time: time

    addStatus: (status) ->
      return if !@el
      @maybeAddTimestamp()

      @el.find('.zammad-chat-body').append @view('status')
        status: status

      @scrollToBottom()

    scrollToBottom: ->
      @el.find('.zammad-chat-body').scrollTop($('.zammad-chat-body').prop('scrollHeight'))

    destroy: (params = {}) =>
      @log.debug 'destroy widget', params

      @setAgentOnlineState 'offline'

      if params.remove && @el
        @el.remove()

      # stop all timer
      if @waitingListTimeout
        @waitingListTimeout.stop()
      if @inactiveTimeout
        @inactiveTimeout.stop()
      if @idleTimeout
        @idleTimeout.stop()

      # stop ws connection
      @io.close()

    reconnect: =>
      # set status to connecting
      @log.notice 'reconnecting'
      @disableInput()
      @lastAddedType = 'status'
      @setAgentOnlineState 'connecting'
      @addStatus @T('Connection lost')

    onConnectionReestablished: =>
      # set status back to online
      @lastAddedType = 'status'
      @setAgentOnlineState 'online'
      @addStatus @T('Connection re-established')

    onSessionClosed: (data) ->
      @addStatus @T('Chat closed by %s', data.realname)
      @disableInput()
      @setAgentOnlineState 'offline'
      @inactiveTimeout.stop()

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

      @hideModal()
      @el.find('.zammad-chat-welcome').addClass('zammad-chat-is-hidden')
      @el.find('.zammad-chat-agent').removeClass('zammad-chat-is-hidden')
      @el.find('.zammad-chat-agent-status').removeClass('zammad-chat-is-hidden')

      @input.focus() if not @isFullscreen

      @setAgentOnlineState 'online'

      @waitingListTimeout.stop()
      @idleTimeout.stop()
      @inactiveTimeout.start()

    showCustomerTimeout: ->
      @el.find('.zammad-chat-modal').html @view('customer_timeout')
        agent: @agent.name
        delay: @options.inactiveTimeout
      reload = ->
        location.reload()
      @el.find('.js-restart').click reload
      @sessionClose()

    showWaitingListTimeout: ->
      @el.find('.zammad-chat-modal').html @view('waiting_list_timeout')
        delay: @options.watingListTimeout
      reload = ->
        location.reload()
      @el.find('.js-restart').click reload
      @sessionClose()

    showLoader: ->
      @el.find('.zammad-chat-modal').html @view('loader')()

    setAgentOnlineState: (state) =>
      @state = state
      return if !@el
      capitalizedState = state.charAt(0).toUpperCase() + state.slice(1)
      @el
        .find('.zammad-chat-agent-status')
        .attr('data-status', state)
        .text @T(capitalizedState)

    detectHost: ->
      protocol = 'ws://'
      if window.location.protocol is 'https:'
        protocol = 'wss://'
      @options.host = "#{ protocol }#{ scriptHost }/ws"

    loadCss: ->
      return if !@options.cssAutoload
      url = @options.cssUrl
      if !url
        url = @options.host
          .replace(/^wss/i, 'https')
          .replace(/^ws/i, 'http')
          .replace(/\/ws/i, '')
        url += '/assets/chat/chat.css'

      @log.debug "load css from '#{url}'"
      styles = "@import url('#{url}');"
      newSS = document.createElement('link')
      newSS.onload = @onCssLoaded
      newSS.rel = 'stylesheet'
      newSS.href = 'data:text/css,' + escape(styles)
      document.getElementsByTagName('head')[0].appendChild(newSS)

    onCssLoaded: =>
      if @socketReady
        @onReady()
      else
        @cssLoaded = true

    startTimeoutObservers: =>
      @idleTimeout = new Timeout(
        logPrefix: 'idleTimeout'
        debug: @options.debug
        timeout: @options.idleTimeout
        timeoutIntervallCheck: @options.idleTimeoutIntervallCheck
        callback: =>
          @log.debug 'Idle timeout reached, hide widget', new Date
          @destroy(remove: true)
      )
      @inactiveTimeout = new Timeout(
        logPrefix: 'inactiveTimeout'
        debug: @options.debug
        timeout: @options.inactiveTimeout
        timeoutIntervallCheck: @options.inactiveTimeoutIntervallCheck
        callback: =>
          @log.debug 'Inactive timeout reached, show timeout screen.', new Date
          @showCustomerTimeout()
          @destroy(remove: false)
      )
      @waitingListTimeout = new Timeout(
        logPrefix: 'waitingListTimeout'
        debug: @options.debug
        timeout: @options.waitingListTimeout
        timeoutIntervallCheck: @options.waitingListTimeoutIntervallCheck
        callback: =>
          @log.debug 'Waiting list timeout reached, show timeout screen.', new Date
          @showWaitingListTimeout()
          @destroy(remove: false)
      )

    disableScrollOnRoot: ->
      @rootScrollOffset = @scrollRoot.scrollTop()
      @scrollRoot.css
        overflow: 'hidden'
        position: 'fixed'

    enableScrollOnRoot: ->
      @scrollRoot.scrollTop @rootScrollOffset
      @scrollRoot.css
        overflow: ''
        position: ''

  window.ZammadChat = ZammadChat
