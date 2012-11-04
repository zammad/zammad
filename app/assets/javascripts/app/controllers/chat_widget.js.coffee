$ = jQuery.sub()

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
    App.Event.bind 'ajax:auth', (user) =>
      if !user
        @messageLog = []
        @el.html('')
      else
        @start()

    if !_.isEmpty( Session )
      @start()

  start: =>
    @focus      = false
    @isShown    = false
    @newMessage = false

    @render()
    @hide()
    @interval @position, 200, 'chat-widget'

    App.Event.bind(
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
    )

    App.Event.bind(
      'chat:window_toggle'
      (e) =>
        if e.show
          @show()
        else
          @hide()
    )

    App.Event.bind(
      'chat:message_new'
      (e) =>
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
            user_id: [ Session['id'] ]
          data:
            show:    true
      )
    else
      @hide()
      App.Event.trigger(
        'ws:send'
          action:    'broadcast'
          event:     'chat:window_toggle'
          recipient:
            user_id: [ Session['id'] ]
          data:
            show:    false
      )
    @newMessage = false

  show: =>
    @isShown = true
    if @newMessage
      @el.find('div.well').addClass('alert-success')
      @delay( =>
          @el.find('div.well').removeClass('alert-success')
          @log 'DELAY rm'

          App.Event.trigger(
            'ws:send'
              action: 'broadcast'
              recipient:
                user_id: [ Session['id'] ]
              event:  'chat:message_new'
              spool:  true
              data:
                show:    true
          )

        2000
        'chat-message-new'
      )
    @el.find('#chat_content').show(100)
    @newMessage = false

  hide: =>
    @isShown = false
    @el.find('#chat_content').hide(100)

  focusIn: =>
    @focus = true
    @clearDelay 'chat-message-focusout'

  focusOut: =>
    a = =>
      @focus = false
    @delay a, 200, 'chat-message-focusout'

  render: ->

    for message in @messageLog
      if message.nick is Session['login']
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

  position: =>
    chatHeigth     = $(@el).find('div').height()
    chatWidth      = $(@el).find('div').width()
    documentHeigth = $(document).height()
    documentWidth  = $(document).width()
    windowHeigth   = $(window).height()
    windowWidth    = $(window).width()
    scrollPositonY = window.pageYOffset
    scrollPositonX = window.pageXOffset

    heigth = windowHeigth + scrollPositonY - chatHeigth - 15
    width  = windowWidth - chatWidth - 55

    @el.offset( left: width, top: heigth )
    @el.css( width: '200px' )

  submitMessage: (e) ->
    e.preventDefault()
    message = $(e.target).find('[name=chat_message]').val()
    if message
      msg =
        message: message
        user_id: Session['id']
        nick:    Session['login']
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

