class Widget extends App.Controller
  constructor: ->
    super

    # bind on event to show message
    App.Event.bind(
      'session:maintenance'
      (data) =>
        console.log('session:maintenance', data)
        @showMessage(data)
      'maintenance'
    )

  showMessage: (message = {}) =>
    if message.reload
      @disconnectClient()
      button = 'Continue session'
    else
      button = 'Close'

    # convert to html and linkify
    message.message = App.Utils.textCleanup(message.message)
    message.message = App.Utils.text2html(message.message)

    new App.SessionMessage(
      head:          message.head
      contentInline: message.message
      keyboard:      true
      backdrop:      true
      buttonClose:   true
      buttonSubmit:  button
      forceReload:   message.reload
    )

App.Config.set('maintenance', Widget, 'Widgets')
