class SessionInvalid extends App.Controller
  constructor: ->
    super

    App.Event.bind('auth:session_invalid', =>
      App.Auth._logout(true, =>
        @navigate '#session_invalid'
      )
    )

  release: ->
    App.Event.unbind('auth:session_invalid')


App.Config.set('session_invalid', SessionInvalid, 'Plugins')
