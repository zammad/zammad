class Widget extends App.Controller
  constructor: ->
    super
    @bind()

  bind: ->

    # only do takeover check after spool messages are finished
    App.Event.bind(
      'spool:sent'
      =>
        @spoolSent = true

        # broadcast to other browser instance
        App.WebSocket.send(
          event: 'broadcast'
          spool:  true
          recipient:
            user_id: [ App.Session.get( 'id' ) ]
          data:
            event: 'session:takeover'
            data:
              taskbar_id: App.TaskManager.TaskbarId()
        )
      'maintenance'
    )

    # session take over message
    App.Event.bind(
      'session:takeover'
      (data) =>

        # only if spool messages are already sent
        return if !@spoolSent

        # check if error message is already shown
        if !@error

          # only if new client id isn't own client id
          if data.taskbar_id isnt App.TaskManager.TaskbarId()
            @error = new App.SessionMessage(
              head:         'Session'
              message:      'A new session was created with your account. This session will be stopped to prevent a conflict.'
              keyboard:     false
              backdrop:     true
              buttonClose:  false
              buttonSubmit: 'Continue session'
              forceReload:  true
            )
            @disconnectClient()
      'maintenance'
    )

App.Config.set('session_taken_over', Widget, 'Widgets')
