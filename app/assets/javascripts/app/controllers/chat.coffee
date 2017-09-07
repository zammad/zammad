class App.CustomerChat extends App.Controller
  events:
    'click .js-acceptChat': 'acceptChat'
    'click .js-settings': 'settings'

  elements:
    '.js-acceptChat': 'acceptChatElement'
    '.js-badgeWaitingCustomers': 'badgeWaitingCustomers'
    '.js-badgeChattingCustomers': 'badgeChattingCustomers'
    '.js-badgeActiveAgents': 'badgeActiveAgents'
    '.chat-workspace': 'workspace'

  sounds:
    chat_new: new Audio('assets/sounds/chat_new.mp3')

  constructor: ->
    super

    @chatWindows = {}
    @maxChatWindows = 4
    preferences = @Session.get('preferences')
    if preferences && preferences.chat && preferences.chat.max_windows
      @maxChatWindows = parseInt(preferences.chat.max_windows)

    @pushStateIntervalOn = undefined
    @idleTimeout = parseInt(@Config.get('chat_agent_idle_timeout') || 120)
    @messageCounter = 0
    @meta =
      active: false
      waiting_chat_count: 0
      waiting_chat_session_list: []
      running_chat_count: 0
      running_chat_session_list: []
      active_agent_count: 0
      active_agent_ids: []

    @render()
    @on 'layout-has-changed', @propagateLayoutChange

    # update navbar on new status
    @bind('chat_status_agent', (data) =>
      if data.assets
        App.Collection.loadAssets(data.assets)
      @meta = data
      @updateMeta()
      if data.active is true
        @startPushState()
    )

    # add new chat window
    @bind('chat_session_start', (data) =>
      if data.session
        @addChat(data.session)
    )

    # on new login or on
    @bind('ws:login chat_agent_state', ->
      App.WebSocket.send(event:'chat_status_agent')
    )
    App.WebSocket.send(event:'chat_status_agent')

    # rerender view, e. g. on langauge change
    @bind('ui:rerender chat:rerender', =>
      return if !@authenticateCheck()
      for session_id, chat of @chatWindows
        chat.el.remove()
      @chatWindows = {}
      @render()
      App.WebSocket.send(event:'chat_status_agent')
    )

  startPushState: =>
    return if @pushStateIntervalOn
    @pushStateIntervalOn = true
    @interval(@pushState, 55000, 'pushState')

  stopPushState: =>
    @pushStateIntervalOn = false
    @clearInterval('pushState')

  pushState: =>
    App.WebSocket.send(
      event:'chat_agent_state'
      data:
        active: @meta.active
    )

  featureActive: =>
    return true if @Config.get('chat')
    false

  render: ->
    if !@permissionCheck('chat.agent')
      @renderScreenUnauthorized(objectName: 'Chat')
      return
    if !@Config.get('chat')
      @renderScreenError(detail: 'Feature disabled!')
      return

    @html App.view('customer_chat/index')()

    chatSessionList = (list) ->
      for chat_session in list
        chat = App.Chat.find(chat_session.chat_id)
        chat_session.name = "#{chat.displayName()} [##{chat_session.id}]"
        chat_session.geo_data = ''
        if chat_session.preferences && chat_session.preferences.geo_ip
          if chat_session.preferences.geo_ip.country_name
            chat_session.geo_data += chat_session.preferences.geo_ip.country_name
          if chat_session.preferences.geo_ip.city_name
            chat_session.geo_data += " #{chat_session.preferences.geo_ip.city_name}"
        if chat_session.user_id
          chat_session.user = App.User.find(chat_session.user_id)
      App.view('customer_chat/chat_list')(
        chat_sessions: list
      )

    @el.find('.js-waitingCustomers .js-info').popover(
      trigger:    'hover'
      html:       true
      animation:  false
      delay:      0
      placement:  'bottom'
      container:  'body' # place in body do prevent it from animating
      title: ->
        App.i18n.translateContent('Waiting Customers')
      content: =>
        chatSessionList(@meta.waiting_chat_session_list)
    )

    @el.find('.js-chattingCustomers .js-info').popover(
      trigger:    'hover'
      html:       true
      animation:  false
      delay:      0
      placement:  'bottom'
      container:  'body'
      title: ->
        App.i18n.translateContent('Chatting Customers')
      content: =>
        chatSessionList(@meta.running_chat_session_list)
    )

    @el.find('.js-activeAgents .js-info').popover(
      trigger:    'hover'
      html:       true
      animation:  false
      delay:      0
      placement:  'bottom'
      container:  'body'
      title: ->
        App.i18n.translateContent('Active Agents')
      content: =>
        users = []
        for user_id in @meta.active_agent_ids
          users.push App.User.find(user_id)
        App.view('customer_chat/user_list')(
          users: users
        )
    )

  show: (params) =>
    @title 'Customer Chat', true
    @navupdate '#customer_chat'

  active: (state) =>
    return @shown if state is undefined
    @shown = state

  counter: =>
    counter = 0

    # get count of controller messages
    if @meta.waiting_chat_count
      counter += @meta.waiting_chat_count

    # play on changes
    if @lastWaitingChatCount isnt counter

      # do not play sound on initial load
      if @switch()
        if counter > 0 && @lastWaitingChatCount isnt undefined
          @sounds.chat_new.play()
          @notifyDesktop(
            title: "#{counter} #{App.i18n.translateInline('Waiting Customers')}",
            url: '#customer_chat'
          )
      @lastWaitingChatCount = counter

    # collect chat window messages
    for key, value of @chatWindows
      if value
        counter += value.unreadMessages()

    @messageCounter = counter

  switch: (state = undefined) =>

    # read state
    if state is undefined
      return @meta.active

    @meta.active = state

    # check if min one chat is active
    if state
      @startPushState()
      preferences = @Session.get('preferences')
      if App.Chat.first() && !preferences || !preferences.chat || !preferences.chat.active || _.isEmpty(preferences.chat.active)

        # if we only have one chat, avtice it automatically
        if App.Chat.count() < 2
          preferences.chat = {}
          preferences.chat.active = {}
          preferences.chat.active[App.Chat.first().id] = 'on'

          # update user preferences
          @ajax(
            id:          'preferences'
            type:        'PUT'
            url:         "#{@apiPath}/users/preferences"
            data:        JSON.stringify(user: {chat: preferences.chat})
            processData: true
            success:     @success
            error:       @error
          )

        # if we have more chats, let decide the user
        else
          msg = 'To be able to chat you need to select min. one chat topic below!'

          # open modal settings
          @settings(
            errors:
              settings: msg
            active: @meta.active
          )

          @meta.active = false
          @pushState()
    else
      @stopPushState()
      @pushState()

  updateMeta: =>
    if @meta.waiting_chat_count && @maxChatWindows > @windowCount()
      @acceptChatElement.addClass('is-clickable is-blinking')
      @idleTimeoutStart()
    else
      @acceptChatElement.removeClass('is-clickable is-blinking')
      @idleTimeoutStop()

    @badgeWaitingCustomers.text(@meta.waiting_chat_count)
    @badgeChattingCustomers.text(@meta.running_chat_count)
    @badgeActiveAgents.text(@meta.active_agent_count)

    # reopen chats
    if @meta.active_sessions
      for session in @meta.active_sessions
        @addChat(session)
    @meta.active_sessions = false

    @updateNavMenu()

  addChat: (session) ->
    return if @chatWindows[session.session_id]
    chat = new ChatWindow
      session: session
      removeCallback: @removeChat
      messageCallback: @updateNavMenu

    @workspace.append chat.el
    chat.render()
    @chatWindows[session.session_id] = chat

    if @windowCount() is 1
      chat.focus()

  windowCount: =>
    count = 0
    for chat of @chatWindows
      count++
    count

  removeChat: (session_id) =>
    delete @chatWindows[session_id]
    @updateMeta()

  propagateLayoutChange: (event) =>
    # adjust scroll position on layoutChange
    for session_id, chat of @chatWindows
      chat.trigger 'layout-changed'

  acceptChat: =>
    return if @windowCount() >= @maxChatWindows
    App.WebSocket.send(event:'chat_session_start')
    @idleTimeoutStop()

  settings: (params = {}) ->
    new Setting(
      windowSpace: @
      errors: params.errors
      active: params.active
    )

  idleTimeoutStart: =>
    return if @idleTimeoutId
    switchOff = =>
      @switch(false)
      @notify(
        type: 'notice'
        msg:  App.i18n.translateContent('Chat not answered, set to offline automatically.')
      )
    @idleTimeoutId = @delay(switchOff, @idleTimeout * 1000)

  idleTimeoutStop: =>
    return if !@idleTimeoutId
    @clearDelay(@idleTimeoutId)
    @idleTimeoutId = undefined

  setPosition: (position) =>
    @$('.main').scrollTop(position)

  currentPosition: =>
    @$('.main').scrollTop()

class CustomerChatRouter extends App.ControllerPermanent
  requiredPermission: 'chat.agent'
  constructor: (params) ->
    super

    App.TaskManager.execute(
      key:        'CustomerChat'
      controller: 'CustomerChat'
      params:     {}
      show:       true
      persistent: true
    )

class ChatWindow extends App.Controller
  className: 'chat-window'

  events:
    'keydown .js-customerChatInput': 'onKeydown'
    'focus .js-customerChatInput':   'clearUnread'
    'click':                         'clearUnread'
    'click .js-send':                'sendMessage'
    'click .js-close':               'close'
    'click .js-disconnect':          'disconnect'
    'click .js-scrollHint':          'onScrollHintClick'

  elements:
    '.js-customerChatInput':         'input'
    '.js-status':                    'status'
    '.js-close':                     'closeButton'
    '.js-disconnect':                'disconnectButton'
    '.js-body':                      'body'
    '.js-scrollHolder':              'scrollHolder'
    '.js-scrollHint':                'scrollHint'

  sounds:
    message: new Audio('assets/sounds/chat_message.mp3')

  constructor: ->
    super

    @showTimeEveryXMinutes = 2
    @lastTimestamp
    @lastAddedType
    @isTyping = false
    @isAgentTyping = false
    @resetUnreadMessages()
    @scrolledToBottom = true
    @scrollSnapTolerance = 10 # pixels

    @chat = App.Chat.find(@session.chat_id)
    @name = "#{@chat.displayName()} ##{@session.id}"

    @on 'layout-change', @onLayoutChange

    @bind('chat_session_typing', (data) =>
      return if data.session_id isnt @session.session_id
      return if data.self_written
      @showWritingLoader()
    )
    @bind('chat_session_message', (data) =>
      return if data.session_id isnt @session.session_id
      return if data.self_written
      @receiveMessage(data.message.content)
    )
    @bind('chat_session_notice', (data) =>
      return if data.session_id isnt @session.session_id
      return if data.self_written
      @addNoticeMessage(data.message)
    )
    @bind('chat_session_left', (data) =>
      return if data.session_id isnt @session.session_id
      return if data.self_written
      @addStatusMessage("<strong>#{data.realname}</strong> left the conversation")
      @goOffline()
    )
    @bind('chat_session_closed', (data) =>
      return if data.session_id isnt @session.session_id
      return if data.self_written
      @addStatusMessage("<strong>#{data.realname}</strong> closed the conversation")
      @goOffline()
    )
    @bind('chat_focus', (data) =>
      return if data.session_id isnt @session.session_id
      @focus()
    )

  onLayoutChange: =>
    @scrollToBottom()

  render: ->
    @html App.view('customer_chat/chat_window')
      name: @name

    @el.one 'transitionend', @onTransitionend
    @scrollHolder.scroll @detectScrolledtoBottom

    # force repaint
    @el.prop('offsetHeight')
    @el.addClass('is-open')

    # @addMessage 'Hello. My name is Roger, how can I help you?', 'agent'
    if @session
      if @session && @session.preferences && @session.preferences.url
        @addNoticeMessage(@session.preferences.url)

      if @session.messages
        for message in @session.messages
          if message.created_by_id
            @addMessage message.content, 'agent'
          else
            @addMessage message.content, 'customer'

      # send init reply
      if !@session.messages || _.isEmpty(@session.messages)
        preferences = @Session.get('preferences')
        if preferences.chat && preferences.chat.phrase
          phrases = preferences.chat.phrase[@session.chat_id]
          if phrases
            phrasesArray = phrases.split(';')
            phrase = phrasesArray[_.random(0, phrasesArray.length-1)]
            @input.html(phrase)
            @sendMessage(1600)

    @$('.js-info').popover(
      trigger:    'hover'
      html:       true
      animation:  false
      delay:      0
      placement:  'bottom'
      container:  'body' # place in body do prevent it from animating
      title: ->
        App.i18n.translateContent('Details')
      content: =>
        App.view('customer_chat/chat_window_info')(
          session: @session
        )
    )

    # show text module UI
    new App.WidgetTextModule(
      el: @input
      data:
        user: App.Session.get()
        config: App.Config.all()
    )

  focus: =>
    @input.focus()

  onTransitionend: (event) =>
    # chat window is done with animation - adjust scroll-bars
    # of sibling chat windows
    @trigger 'layout-has-changed'

    if event.data and event.data.callback
      event.data.callback()

    @input.ce({
      mode:       'richtext'
      multiline:  true
      maxlength:  40000
      imageWidth: 'relative'
    })

  disconnect: =>
    @addStatusMessage('<strong>You</strong> left the conversation')
    App.WebSocket.send(
      event:'chat_session_close'
      data:
        session_id: @session.session_id
    )
    @goOffline()

  close: =>
    @el.one 'transitionend', { callback: @release }, @onTransitionend
    @el.removeClass('is-open')
    if @removeCallback
      @removeCallback(@session.session_id)

  release: =>
    @trigger 'closed'
    @el.remove()
    super

  clearUnread: =>
    @$('.chat-message--new').removeClass('chat-message--new')
    @updateModified(false)
    @resetUnreadMessages()

  onKeydown: (event) =>
    TABKEY = 9
    ENTERKEY = 13

    if event.keyCode isnt TABKEY && event.keyCode isnt ENTERKEY

      # send typing start event only every 1.4 seconds
      return if @isAgentTyping && @isAgentTyping > new Date(new Date().getTime() - 1400)
      @isAgentTyping = new Date()
      App.WebSocket.send(
        event:'chat_session_typing'
        data:
          session_id: @session.session_id
      )

    switch event.keyCode
      when TABKEY
        allChatInputs = @input.not('[disabled="disabled"]')
        chatCount = allChatInputs.size()
        index = allChatInputs.index(@input)

        if chatCount > 1
          switch index
            when chatCount-1
              if !event.shiftKey
                # State: tab without shift on last input
                # Jump to first input
                event.preventDefault()
                allChatInputs.eq(0).focus()
            when 0
              if event.shiftKey
                # State: tab with shift on first input
                # Jump to last input
                event.preventDefault()
                allChatInputs.eq(chatCount-1).focus()

      when ENTERKEY
        if !event.shiftKey && !event.altKey && !event.ctrlKey && !event.metaKey
          event.preventDefault()
          @sendMessage()

  sendMessage: (delay) =>
    content = @input.html()
    return if !content
    return if @el.hasClass('is-offline')

    send = =>
      App.WebSocket.send(
        event:'chat_session_message'
        data:
          content: content
          session_id: @session.session_id
      )
    if !delay
      send()
    else
      # show key enter and send phrase
      App.WebSocket.send(
        event:'chat_session_typing'
        data:
          session_id: @session.session_id
      )
      @delay(send, delay)

    @addMessage content, 'agent'
    @input.html('')

  updateModified: (state) =>
    @status.toggleClass('is-modified', state)

  receiveMessage: (message) =>
    isFocused = @input.is(':focus')

    @removeWritingLoader()
    @addMessage(message, 'customer', !isFocused)

    if !isFocused
      @addUnreadMessages()
      @updateModified(true)
      @sounds.message.play()
      @notifyDesktop(
        title: @name
        body: App.Utils.html2text(message)
        url: '#customer_chat'
        callback: =>
          App.Event.trigger('chat_focus', { session_id: @session.session_id })
      )

  unreadMessages: =>
    @unreadMessagesCounter

  addUnreadMessages: =>
    if @messageCallback
      @messageCallback(@session.session_id)
    @unreadMessagesCounter += 1

  resetUnreadMessages: =>
    if @messageCallback
      @messageCallback(@session.session_id)
    @unreadMessagesCounter = 0

  addMessage: (message, sender, isNew) =>
    @maybeAddTimestamp()

    @lastAddedType = sender

    @body.append App.view('customer_chat/chat_message')
      message: message
      sender: sender
      isNew: isNew
      timestamp: Date.now()

    @scrollToBottom showHint: true

  showWritingLoader: =>
    if !@isTyping
      @isTyping = true
      @maybeAddTimestamp()
      @body.append App.view('customer_chat/chat_loader')()
      @scrollToBottom()

    # clear old delay, set new
    @delay(@removeWritingLoader, 2000, 'typing')

  removeWritingLoader: =>
    @isTyping = false
    @$('.js-loader').remove()

  goOffline: =>
    @status.attr('data-status', 'offline')
    @disconnectButton.addClass 'is-hidden'
    @closeButton.removeClass 'is-hidden'
    @el.addClass('is-offline')
    @input.attr('disabled', true)

    # add footer with create ticket button
    @body.append App.view('customer_chat/chat_footer')()

  maybeAddTimestamp: ->
    timestamp = Date.now()

    if !@lastTimestamp or timestamp - @lastTimestamp > @showTimeEveryXMinutes * 60000
      label = App.i18n.translateInline('today')
      time = new Date().toTimeString().substr(0,5)
      if @lastAddedType is 'timestamp'
        # update last time
        @updateLastTimestamp label, time
        @lastTimestamp = timestamp
      else
        @addTimestamp label, time
        @lastTimestamp = timestamp
        @lastAddedType = 'timestamp'

  addTimestamp: (label, time) =>
    @body.append App.view('customer_chat/chat_timestamp')
      label: label
      time: time

  updateLastTimestamp: (label, time) ->
    @body
      .find('.js-timestamp')
      .last()
      .replaceWith App.view('customer_chat/chat_timestamp')
        label: label
        time: time

  addStatusMessage: (message, args) ->
    @maybeAddTimestamp()

    @body.append App.view('customer_chat/chat_status_message')
      message: message
      args: args

    @scrollToBottom()

  addNoticeMessage: (message, args) ->
    @maybeAddTimestamp()

    @body.append App.view('customer_chat/chat_notice_message')
      message: message
      args: args

    @scrollToBottom()

  detectScrolledtoBottom: =>
    scrollBottom = @scrollHolder.scrollTop() + @scrollHolder.outerHeight()
    @scrolledToBottom = Math.abs(scrollBottom - @scrollHolder.prop('scrollHeight')) <= @scrollSnapTolerance
    @scrollHint.addClass('is-hidden') if @scrolledToBottom

  showScrollHint: ->
    @scrollHint.removeClass('is-hidden')
    # compensate scroll
    @scrollHolder.scrollTop(@scrollHolder.scrollTop() + @scrollHint.outerHeight())

  onScrollHintClick: ->
    # animate scroll
    @scrollHolder.animate({scrollTop: @scrollHolder.prop('scrollHeight')}, 300)

  scrollToBottom: ({ showHint } = { showHint: false }) ->
    if @scrolledToBottom
      @scrollHolder.scrollTop(@scrollHolder.prop('scrollHeight'))
    else if showHint
      @showScrollHint()

class Setting extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: 'Settings'

  content: =>

    preferences = @Session.get('preferences')
    if !preferences
      preferences = {}
    if !preferences.chat
      preferences.chat = {}
    if !preferences.chat.active
      preferences.chat.active = {}
    if !preferences.chat.phrase
      preferences.chat.phrase = {}
    if !preferences.chat.max_windows
      preferences.chat.max_windows = @windowSpace.maxChatWindows

    App.view('customer_chat/setting')(
      chats: App.Chat.all()
      preferences: preferences
      errors: @errors || {}
    )

  submit: (e) =>
    e.preventDefault()
    params = @formParam(e.target)

    @formDisable(e)

    # update runtime
    @windowSpace.maxChatWindows = params.chat.max_windows

    # update user preferences
    @ajax(
      id:          'preferences'
      type:        'PUT'
      url:         "#{@apiPath}/users/preferences"
      data:        JSON.stringify({user:params})
      processData: true
      success:     @success
      error:       @error
    )

  success: (data, status, xhr) =>
    if @active is true || @active is false
      @windowSpace.meta.active = @active
      @windowSpace.pushState()
    else
      App.WebSocket.send(event:'chat_status_agent')
    App.User.full(
      App.Session.get('id'),
      =>
        @close()
      ,
      true
    )

  error: (xhr, status, error) =>
    data = JSON.parse(xhr.responseText)
    @notify(
      type: 'error'
      msg:  App.i18n.translateContent(data.message)
    )

App.Config.set('customer_chat', CustomerChatRouter, 'Routes')
App.Config.set('CustomerChat', { controller: 'CustomerChat', permission: ['chat.agent'] }, 'permanentTask')
App.Config.set('CustomerChat', { prio: 1200, parent: '', name: 'Customer Chat', target: '#customer_chat', key: 'CustomerChat', shown: false, permission: ['chat.agent'], class: 'chat' }, 'NavBar')
