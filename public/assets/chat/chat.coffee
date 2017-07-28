do($ = window.jQuery, window) ->

  scripts = document.getElementsByTagName('script')
  myScript = scripts[scripts.length - 1]
  scriptHost = myScript.src.match('.*://([^:/]*).*')[1]
  scriptProtocol = myScript.src.match('(.*)://[^:/]*.*')[1]

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
      scrollHint: 'Scroll down to see new messages'
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
      'de':
        '<strong>Chat</strong> with us!': '<strong>Chatte</strong> mit uns!'
        'Scroll down to see new messages': 'Scrolle nach unten um neue Nachrichten zu sehen'
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
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Es tut uns leid, es dauert länger als erwartet, um einen freien Platz zu erhalten. Bitte versuchen Sie es zu einem späteren Zeitpunkt noch einmal oder schicken Sie uns eine E-Mail. Vielen Dank!'
      'es':
        '<strong>Chat</strong> with us!': '<strong>Chatee</strong> con nosotros!'
        'Scroll down to see new messages': 'Haga scroll hacia abajo para ver nuevos mensajes'
        'Online': 'En linea'
        'Offline': 'Desconectado'
        'Connecting': 'Conectando'
        'Connection re-established': 'Conexión restablecida'
        'Today': 'Hoy'
        'Send': 'Enviar'
        'Compose your message...': 'Escriba su mensaje...'
        'All colleagues are busy.': 'Todos los agentes están ocupados.'
        'You are on waiting list position <strong>%s</strong>.': 'Usted está en la posición <strong>%s</strong> de la lista de espera.'
        'Start new conversation': 'Iniciar nueva conversación'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Puesto que usted no respondió en los últimos %s minutos su conversación con <strong>%s</strong> se ha cerrado.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Puesto que usted no respondió en los últimos %s minutos su conversación se ha cerrado.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Lo sentimos, se tarda más tiempo de lo esperado para ser atendido por un agente. Inténtelo de nuevo más tarde o envíenos un correo electrónico. ¡Gracias!'
      'fr':
        '<strong>Chat</strong> with us!': '<strong>Chattez</strong> avec nous!'
        'Scroll down to see new messages': 'Faites défiler pour lire les nouveaux messages'
        'Online': 'En-ligne'
        'Offline': 'Hors-ligne'
        'Connecting': 'Connexion en cours'
        'Connection re-established': 'Connexion rétablie'
        'Today': 'Aujourdhui'
        'Send': 'Envoyer'
        'Compose your message...': 'Composez votre message...'
        'All colleagues are busy.': 'Tous les collègues sont actuellement occupés.'
        'You are on waiting list position <strong>%s</strong>.': 'Vous êtes actuellement en <strong>%s</strong> position dans la file d\'attente.'
        'Start new conversation': 'Démarrer une nouvelle conversation'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Si vous ne répondez pas dans les <strong>%s</strong> minutes, votre conversation avec %s va être fermée.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Si vous ne répondez pas dans les %s minutes, votre conversation va être fermée.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Nous sommes désolés, il faut plus de temps que prévu pour obtenir un emplacement vide. Veuillez réessayer ultérieurement ou nous envoyer un courriel. Je vous remercie!'
      'zh-cn':
        '<strong>Chat</strong> with us!': '发起<strong>即时对话</strong>!'
        'Scroll down to see new messages': '向下滚动以查看新消息'
        'Online': '在线'
        'Offline': '离线'
        'Connecting': '连接中'
        'Connection re-established': '正在重新建立连接'
        'Today': '今天'
        'Send': '发送'
        'Compose your message...': '正在输入信息...'
        'All colleagues are busy.': '所有工作人员都在忙碌中.'
        'You are on waiting list position <strong>%s</strong>.': '您目前的等候位置是第 <strong>%s</strong> 位.'
        'Start new conversation': '开始新的会话'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': '由于您超过 %s 分钟没有回复, 您与 <strong>%s</strong> 的会话已被关闭.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': '由于您超过 %s 分钟没有任何回复, 该对话已被关闭.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': '非常抱歉, 目前需要等候更长的时间才能接入对话, 请稍后重试或向我们发送电子邮件. 谢谢!'
      'zh-tw':
        '<strong>Chat</strong> with us!': '開始<strong>即時對话</strong>!'
        'Scroll down to see new messages': '向下滑動以查看新訊息'
        'Online': '線上'
        'Offline': '离线'
        'Connecting': '連線中'
        'Connection re-established': '正在重新建立連線中'
        'Today': '今天'
        'Send': '發送'
        'Compose your message...': '正在輸入訊息...'
        'All colleagues are busy.': '所有服務人員都在忙碌中.'
        'You are on waiting list position <strong>%s</strong>.': '你目前的等候位置是第 <strong>%s</strong> 順位.'
        'Start new conversation': '開始新的對話'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': '由於你超過 %s 分鐘沒有回應, 你與 <strong>%s</strong> 的對話已被關閉.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': '由於你超過 %s 分鐘沒有任何回應, 該對話已被關閉.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': '非常抱歉, 當前需要等候更長的時間方可排入對話程序, 請稍後重試或向我們寄送電子郵件. 謝謝!'
    sessionId: undefined
    scrolledToBottom: true
    scrollSnapTolerance: 10

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
        if !@translations[@options.lang]
          @log.debug "lang: No #{@options.lang} found, try first two letters"
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
        url: window.location.href

    renderBase: ->
      @el = $(@view('chat')(
        title: @options.title,
        scrollHint: @options.scrollHint
      ))
      @options.target.append @el

      @input = @el.find('.zammad-chat-input')

      # start bindings
      @el.find('.js-chat-open').click @open
      @el.find('.js-chat-toggle').click @toggle
      @el.find('.zammad-chat-controls').on 'submit', @onSubmit
      @el.find('.zammad-chat-body').on 'scroll', @detectScrolledtoBottom
      @el.find('.zammad-scroll-hint').click @onScrollHintClick
      @input.on
        keydown: @checkForEnter
        input: @onInput
      $(window).on('beforeunload', =>
        @onLeaveTemporary()
      )
      $(window).bind('hashchange', =>
        if @isOpen
          if @sessionId
            @send 'chat_session_notice',
              session_id: @sessionId
              message: window.location.href
          return
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
      if @el.find('.zammad-chat-message--typing').get(0)
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

      @scrollToBottom showHint: true

    renderMessage: (data) =>
      @lastAddedType = "message--#{ data.from }"
      data.unreadClass = if document.hidden then ' zammad-chat-message--unread' else ''
      @el.find('.zammad-chat-body').append @view('message')(data)

    open: =>
      if @isOpen
        @log.debug 'widget already open, block'
        return

      @isOpen = true
      @log.debug 'open widget'

      if !@sessionId
        @showLoader()

      @el.addClass('zammad-chat-is-open')

      if !@inputInitialized
        @inputInitialized = true
        @input.autoGrow
          extraLine: false

      remainerHeight = @el.height() - @el.find('.zammad-chat-header').outerHeight()

      @el.css 'bottom', -remainerHeight

      if !@sessionId
        @el.animate { bottom: 0 }, 500, @onOpenAnimationEnd
        @send('chat_session_init'
          url: window.location.href
        )
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
      remainerHeight = @el.height() - @el.find('.zammad-chat-header').outerHeight()
      @el.animate { bottom: -remainerHeight }, 500, @onCloseAnimationEnd

    onCloseAnimationEnd: =>
      @el.css 'bottom', ''
      @el.removeClass('zammad-chat-is-open')

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
      return if @el.find('.zammad-chat-message--typing').get(0)

      @maybeAddTimestamp()

      @el.find('.zammad-chat-body').append @view('typingIndicator')()

      # only if typing indicator is shown
      return if !@isVisible(@el.find('.zammad-chat-message--typing'), true)
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

    detectScrolledtoBottom: =>
      scrollBottom = @el.find('.zammad-chat-body').scrollTop() + @el.find('.zammad-chat-body').outerHeight()
      @scrolledToBottom = Math.abs(scrollBottom - @el.find('.zammad-chat-body').prop('scrollHeight')) <= @scrollSnapTolerance
      @el.find('.zammad-scroll-hint').addClass('is-hidden') if @scrolledToBottom

    showScrollHint: ->
      @el.find('.zammad-scroll-hint').removeClass('is-hidden')
      # compensate scroll
      @el.find('.zammad-chat-body').scrollTop(@el.find('.zammad-chat-body').scrollTop() + @el.find('.zammad-scroll-hint').outerHeight())

    onScrollHintClick: =>
      # animate scroll
      @el.find('.zammad-chat-body').animate({scrollTop: @el.find('.zammad-chat-body').prop('scrollHeight')}, 300)

    scrollToBottom: ({ showHint } = { showHint: false }) ->
      if @scrolledToBottom
        @el.find('.zammad-chat-body').scrollTop($('.zammad-chat-body').prop('scrollHeight'))
      else if showHint
        @showScrollHint()

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

      # empty old messages
      @el.find('.zammad-chat-body').html('')

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
      if scriptProtocol is 'https'
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

    # based on https://github.com/customd/jquery-visible/blob/master/jquery.visible.js
    # to have not dependency, port to coffeescript
    isVisible: (el, partial, hidden, direction) ->
      return if el.length < 1

      $w         = $(window)
      $t         = if el.length > 1 then el.eq(0) else el
      t          = $t.get(0)
      vpWidth    = $w.width()
      vpHeight   = $w.height()
      direction  = if direction then direction else 'both'
      clientSize = if hidden is true then t.offsetWidth * t.offsetHeight else true

      if typeof t.getBoundingClientRect is 'function'

        # Use this native browser method, if available.
        rec      = t.getBoundingClientRect()
        tViz     = rec.top >= 0 && rec.top    <  vpHeight
        bViz     = rec.bottom >  0 && rec.bottom <= vpHeight
        lViz     = rec.left >= 0 && rec.left   <  vpWidth
        rViz     = rec.right  >  0 && rec.right <= vpWidth
        vVisible = if partial then tViz || bViz else tViz && bViz
        hVisible = if partial then lViz || rViz else lViz && rViz

        if direction is 'both'
          return clientSize && vVisible && hVisible
        else if direction is 'vertical'
          return clientSize && vVisible
        else if direction is 'horizontal'
          return clientSize && hVisible
      else
        viewTop         = $w.scrollTop()
        viewBottom      = viewTop + vpHeight
        viewLeft        = $w.scrollLeft()
        viewRight       = viewLeft + vpWidth
        offset          = $t.offset()
        _top            = offset.top
        _bottom         = _top + $t.height()
        _left           = offset.left
        _right          = _left + $t.width()
        compareTop      = if partial is true then _bottom else _top
        compareBottom   = if partial is true then _top else _bottom
        compareLeft     = if partial is true then _right else _left
        compareRight    = if partial is true then _left else _right

        if direction is 'both'
          return !!clientSize && ((compareBottom <= viewBottom) && (compareTop >= viewTop)) && ((compareRight <= viewRight) && (compareLeft >= viewLeft))
        else if direction is 'vertical'
          return !!clientSize && ((compareBottom <= viewBottom) && (compareTop >= viewTop))
        else if direction is 'horizontal'
          return !!clientSize && ((compareRight <= viewRight) && (compareLeft >= viewLeft))

  window.ZammadChat = ZammadChat
