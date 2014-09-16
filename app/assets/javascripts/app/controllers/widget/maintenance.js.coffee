class Widget extends App.Controller
  constructor: ->
    super

    # bind on event to show message
    App.Event.bind(
      'session:maintenance'
      (data) =>
        console.log('session:maintenance', data)
        @showMessage( data )
      'maintenance'
    )

  showMessage: (message = {}) =>
    if message.reload
      @disconnectClient()
      button = 'Reload application'

    new App.SessionMessage(
      head:        message.head
      message:     message.message
      keyboard:    false
      backdrop:    true
      close:       true
      button:      button
      forceReload: message.reload
    )

App.Config.set( 'maintenance', Widget, 'Widgets' )