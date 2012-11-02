$ = jQuery.sub()

class App.ChatWidget extends App.Controller
  events:
    'submit   #chat_form':          'newMessage'
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
        @el.html()
      else
        @start()

    if !_.isEmpty( Session )
      @start()

  start: =>
    @focus = false

    @render()
    @hide()
    @interval @position, 200, 'chat-widget'

    App.Event.bind(
      'chat:message'
      (e) =>
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
        if e.user_id is Session['id']
          if e.show
            @show()
          else
            @hide()
    )

  toggle: (e) =>
    e.preventDefault()
    if @el.find('#chat_content').hasClass('hide')
      @show()
      App.Event.trigger(
        'ws:send'
          action: 'broadcast'
          event:  'chat:window_toggle'
          data:
            user_id: Session['id']
            show:    true
      )
    else
      @hide()
      App.Event.trigger(
        'ws:send'
          action: 'broadcast'
          event:  'chat:window_toggle'
          data:
            user_id: Session['id']
            show:    false
      )

  show: =>
    @el.find('#chat_content').removeClass('hide')

  hide: =>
    @el.find('#chat_content').addClass('hide')

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
    @html App.view('chat_widget')(
      messages: @messageLog
    )
    document.getElementById('chat_log_container').scrollTop = 10000
    if @focus
      @el.find('[name=chat_message]').focus()

  position: =>
    chatHeigth     = $(@el).find('div').height()
    chatWidth      = $(@el).find('div').width()
    documentHeigth = $(document).height()
    documentWidth  = $(document).width()
    windowHeigth   = $(window).height()
    windowWidth    = $(window).width()
    scrollPositonY = window.pageYOffset
    scrollPositonX = window.pageXOffset

    heigth = windowHeigth + scrollPositonY - chatHeigth - 10
    width  = windowWidth - chatWidth - 50

    @el.offset( left: width, top: heigth )
    @el.css( width: '200px' )

  newMessage: (e) ->
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

