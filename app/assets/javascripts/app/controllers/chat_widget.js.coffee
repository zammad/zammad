class App.ChatWidget extends App.Controller
  events:
    'submit   #chat_form':          'submitMessage'
    'focusin  [name=chat_message]': 'focusIn'
    'focusout [name=chat_message]': 'focusOut'
    'click    .close':              'toggle'

  constructor: ->
    super

    @messageLog = []

    # rebuild chat widget
    @bind 'auth', (user) =>
      if !user
        @messageLog = []
        @el.html('')
      else
        if !@access()
          @messageLog = []
          @el.html('')
          return
        @start()

    if @access()
      @start()

  access: ->
    return false if _.isEmpty( @Session.all() )
    return true if @isRole('Agent')
    return true if @isRole('Admin')
    return false

  start: =>
    @focus      = false
    @isShown    = false
    @newMessage = false

    @render()
    @hide()

    @bind(
      'chat:message'
      (e) =>

        # show new message info
        @newMessage = true

        # remember messages
        @messageLog.push e

        # chump max message count
        max = 10
        length = @messageLog.length
        if length > 10
          @messageLog = @messageLog.slice( length - max, length )
        @render()

        if !e.spool
          @notifyDesktop(
            msg:  'Chat'
            body: "#{e.nick}: #{e.message}"
          )
    )

    @bind(
      'chat:window_toggle'
      (e) =>
        if e.show
          @show()
        else
          @hide()
    )

    @bind(
      'chat:message_new'
      (e) =>

        # show new message info
        @newMessage = false
        @el.find('div.well').removeClass('alert-success')
    )

  toggle: (e) =>
    e.preventDefault()
    if !@el.find('#chat_content').is(':visible')
      @show()
      App.Event.trigger(
        'ws:send'
          action: 'broadcast'
          event:  'chat:window_toggle'
          recipient:
            user_id: [ @Session.get('id') ]
          data:
            show: true
      )
    else
      @hide()
      App.Event.trigger(
        'ws:send'
          action: 'broadcast'
          event:  'chat:window_toggle'
          recipient:
            user_id: [ @Session.get('id') ]
          data:
            show: false
      )
    @newMessage = false

  show: =>
    @isShown = true
    @el.find('#chat_toogle').html('&times;');
    if @newMessage
      @el.find('div.well').addClass('alert-success')
      @delay( =>
          @el.find('div.well').removeClass('alert-success')

          App.Event.trigger(
            'ws:send'
              action: 'broadcast'
              recipient:
                user_id: [ @Session.get('id') ]
              event:  'chat:message_new'
              spool:  true
              data:
                show: true
          )

        2000
        'chat-message-new'
      )
    @el.find('#chat_content').show(100)
    @el.find('#chat_content').removeClass('hide')
    @newMessage = false

    # hide
    @delay( =>
        @hide()
      60000
      'chat-window-hide'
    )

  hide: =>
    @isShown = false
    @el.find('#chat_content').hide(100)
    @el.find('#chat_content').addClass('hide')
    @el.find('#chat_toogle').html('&diams;');

  focusIn: =>
    @focus = true
    @clearDelay 'chat-message-focusout'
    @clearDelay 'chat-window-hide'

  focusOut: =>
    a = =>
      @focus = false
    @delay a, 200, 'chat-message-focusout'

    # hide
    @delay( =>
        @hide()
      60000
      'chat-window-hide'
    )

  render: ->

    for message in @messageLog
      if message.nick is @Session.get('login')
        message.nick = 'me'

    # insert data
    shown = false
    if @isShown
      shown = true
    @html App.view('chat_widget')(
      messages: @messageLog
      isShown:  shown
    )
    document.getElementById('chat_log_container').scrollTop = 10000

    # focus in input box
    if @focus
      @el.find('[name=chat_message]').focus()

    # show or not show window
    if @isShown
      @show()
    else
      @hide()
      if @newMessage
        @el.find('div.well').addClass('alert-success')

  submitMessage: (e) ->
    e.preventDefault()
    message = $(e.target).find('[name=chat_message]').val()
    if message
      msg =
        message: message
        user_id: @Session.get( 'id' )
        nick:    @Session.get( 'login' )
      @messageLog.push msg

      $(e.target).find('[name=chat_message]').val('')

      App.Event.trigger(
        'ws:send'
          action: 'broadcast'
          event:  'chat:message'
          spool:  true
          data:   msg
      )
      @render()

App.Config.set( 'chat', App.ChatWidget, 'Widgets' )
