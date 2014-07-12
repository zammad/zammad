class Widget extends App.Controller
  constructor: ->
    super

    # bind on event to show message
    App.Event.bind(
      'session:maintenance'
      (data) =>
        new Message( message: data )
      'maintenance'
    )

class Message extends App.ControllerModal
  constructor: ->
    super
    @render(@message)

  render: (message = {}) ->

    if message.reload
      @disconnectClient()
      button = 'Reload application'

    new App.SessionMessage(
      title:       message.title
      message:     message.message
      keyboard:    false
      backdrop:    true
      close:       true
      button:      button
      forceReload: message.reload
    )

App.Config.set( 'maintenance', Widget, 'Widgets' )