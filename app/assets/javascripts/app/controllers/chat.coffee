class App.CustomerChat extends App.Controller
  @extend Spine.Events

  events:
    'click .js-acceptChat': 'acceptChat'

  sounds:
    chat_new: new Audio('assets/sounds/chat_new.mp3')

  constructor: ->
    super

    @i = 0
    @chatWindows = {}
    @totalQuestions = 7
    @answered = 0
    @correct = 0
    @wrong = 0
    @maxChats = 4

    @messageCounter = 0
    @meta =
      active: false
      waiting_chat_count: 0
      running_chat_count: 0
      active_agents: 0

    @render()

    App.Event.bind(
      'chat_status_agent'
      (data) =>
        @meta = data
        @updateMeta()
        @interval(@pushState, 20000, 'pushState')
    )
    App.Event.bind(
      'chat_session_start'
      (data) =>
        App.WebSocket.send(event:'chat_status_agent')
        if data.session
          @addChat(data.session)
    )

    App.WebSocket.send(event:'chat_status_agent')

  pushState: =>
    App.WebSocket.send(
      event:'chat_agent_state'
      data:
        active: @meta.active
    )

  render: ->
    @html App.view('customer_chat/index')()

  show: (params) =>
    @navupdate '#customer_chat'

  counter: =>
    counter = 0

    # get count of controller messages
    if @meta.waiting_chat_count
      counter += @meta.waiting_chat_count

    # play on changes
    if @lastWaitingChatCount isnt counter
      @sounds.chat_new.play()
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

    # write state
    App.WebSocket.send(
      event:'chat_agent_state'
      data:
        active: @meta.active
    )

  updateNavMenu: =>
    delay = ->
      App.Event.trigger('menu:render')
    @delay(delay, 200, 'updateNavMenu')

  updateMeta: =>
    if @meta.waiting_chat_count
      @$('.js-acceptChat').addClass('is-clickable is-blinking')
    else
      @$('.js-acceptChat').removeClass('is-clickable is-blinking')
    @$('.js-badgeWaitingCustomers').text(@meta.waiting_chat_count)
    @$('.js-badgeChattingCustomers').text(@meta.running_chat_count)
    @$('.js-badgeActiveAgents').text(@meta.active_agents)

    if @meta.active_sessions
      for session in @meta.active_sessions
        @addChat(session)

    @updateNavMenu()

  addChat: (session) ->
    return if @chatWindows[session.session_id]
    chat = new chatWindow
      name: "#{session.created_at}"
      session: session
      removeCallback: @removeChat
      messageCallback: @updateNavMenu

    @on 'layout-has-changed', @propagateLayoutChange

    @$('.chat-workspace').append(chat.el)
    @chatWindows[session.session_id] = chat

  removeChat: (session_id) =>
    delete @chatWindows[session_id]

  propagateLayoutChange: (event) =>

    # adjust scroll position on layoutChange
    for session_id, chat of @chatWindows
      chat.trigger 'layout-changed'

  acceptChat: =>
    currentChats = 0
    for key, value of @chatWindows
      if @chatWindows[key]
        currentChats += 1
    return if currentChats >= @maxChats

    App.WebSocket.send(event:'chat_session_start')

class CustomerChatRouter extends App.ControllerPermanent
  constructor: (params) ->
    super

    # check authentication
    return if !@authenticate()

    App.TaskManager.execute(
      key:        'CustomerChat'
      controller: 'CustomerChat'
      params:     {}
      show:       true
      persistent: true
    )

class chatWindow extends App.Controller
  @extend Spine.Events

  className: 'chat-window'

  events:
    'keydown .js-customerChatInput': 'onKeydown'
    'focus .js-customerChatInput':   'clearUnread'
    'click':                         'clearUnread'
    'click .js-send':                'sendMessage'
    'click .js-close':               'close'

  elements:
    '.js-customerChatInput': 'input'
    '.js-status':            'status'
    '.js-body':              'body'
    '.js-scrollHolder':      'scrollHolder'

  sounds:
    message: new Audio('assets/sounds/chat_message.mp3')

  constructor: ->
    super

    @showTimeEveryXMinutes = 1
    @lastTimestamp
    @lastAddedType
    @isTyping = false
    @render()
    @resetUnreadMessages()

    @on 'layout-change', @scrollToBottom

    App.Event.bind(
      'chat_session_typing'
      (data) =>
        return if data.session_id isnt @session.session_id
        return if data.self_written
        @showWritingLoader()
    )
    App.Event.bind(
      'chat_session_message'
      (data) =>
        return if data.session_id isnt @session.session_id
        return if data.self_written
        @receiveMessage(data.message.content)
    )

  render: ->
    @html App.view('layout_ref/customer_chat_window')
      name: @options.name

    @el.one 'transitionend', @onTransitionend

    # make sure animation will run
    setTimeout (=> @el.addClass('is-open')), 0

    # @addMessage 'Hello. My name is Roger, how can I help you?', 'agent'
    if @session && @session.messages
      for message in @session.messages
        if message.created_by_id
          @addMessage message.content, 'agent'
        else
          @addMessage message.content, 'customer'

    # set focus
    @input.get(0).focus()

  onTransitionend: (event) =>
    # chat window is done with animation - adjust scroll-bars
    # of sibling chat windows
    @trigger 'layout-has-changed'

    if event.data and event.data.callback
      event.data.callback()

  close: =>
    @el.one 'transitionend', { callback: @release }, @onTransitionend
    @el.removeClass('is-open')
    App.WebSocket.send(
      event:'chat_session_close'
      data:
        session_id: @session.session_id
    )
    if @removeCallback
      @removeCallback(@session.session_id)

  release: =>
    @trigger 'closed'
    super

  clearUnread: =>
    @$('.chat-message--new').removeClass('chat-message--new')
    @updateModified(false)
    @resetUnreadMessages()

  onKeydown: (event) =>
    TABKEY = 9;
    ENTERKEY = 13;

    if event.keyCode isnt TABKEY && event.keyCode isnt ENTERKEY
      App.WebSocket.send(
        event:'chat_session_typing'
        data:
          session_id: @session.session_id
      )

    switch event.keyCode
      when TABKEY
        allChatInputs = $('.js-customerChatInput').not('[disabled="disabled"]')
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
        if !event.shiftKey
          event.preventDefault()
          @sendMessage()

  sendMessage: =>
    content = @input.html()
    return if !content

    #@trigger "answer", @input.html()
    App.WebSocket.send(
      event:'chat_session_message'
      data:
        content: content
        session_id: @session.session_id
    )

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

    @body.append App.view('layout_ref/customer_chat_message')
      message: message
      sender: sender
      isNew: isNew
      timestamp: Date.now()

    @scrollToBottom()

  showWritingLoader: =>
    if !@isTyping
      @isTyping = true
      @maybeAddTimestamp()
      @body.append App.view('layout_ref/customer_chat_loader')()
      @scrollToBottom()

    # clear old delay, set new
    @delay(@removeWritingLoader, 1800, 'typing')

  removeWritingLoader: =>
    @isTyping = false
    @$('.js-loader').remove()

  goOffline: =>
    @addStatusMessage("<strong>#{ @options.name }</strong>'s connection got closed")
    @status.attr('data-status', 'offline')
    @el.addClass('is-offline')
    @input.attr('disabled', true)

  maybeAddTimestamp: ->
    timestamp = Date.now()

    if !@lastTimestamp or timestamp - @lastTimestamp > @showTimeEveryXMinutes * 60000
      label = 'Today'
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
    @body.append App.view('layout_ref/customer_chat_timestamp')
      label: label
      time: time

  updateLastTimestamp: (label, time) ->
    @body
      .find('.js-timestamp')
      .last()
      .replaceWith App.view('layout_ref/customer_chat_timestamp')
        label: label
        time: time

  addStatusMessage: (message) ->
    @body.append App.view('layout_ref/customer_chat_status_message')
      message: message

    @scrollToBottom()

  scrollToBottom: ->
    @scrollHolder.scrollTop(@scrollHolder.prop('scrollHeight'))


App.Config.set( 'customer_chat', CustomerChatRouter, 'Routes' )
App.Config.set( 'CustomerChat', { controller: 'CustomerChat', authentication: true }, 'permanentTask' )
App.Config.set( 'CustomerChat', { prio: 1200, parent: '', name: 'Customer Chat', target: '#customer_chat', key: 'CustomerChat', role: ['Chat'], class: 'chat' }, 'NavBar' )
