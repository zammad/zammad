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

    # convert to html and linkify
    message.message = App.Utils.textCleanup( message.message )
    message.message = App.Utils.text2html( message.message )

    new App.SessionMessage(
      head:        message.head
      content:     message.message
      keyboard:    true
      backdrop:    true
      close:       true
      button:      button
      forceReload: message.reload
    )

App.Config.set( 'maintenance', Widget, 'Widgets' )