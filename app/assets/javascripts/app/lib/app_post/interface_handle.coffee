class App.Run extends App.Controller
  constructor: ->
    super
    @el = $('#app')

    App.Event.trigger('app:init')

    # browser check
    return if !App.Browser.check()

    # hide splash screen
    $('.splash').hide()

    # init collections
    App.Collection.init()

    # check if session already exists/try to get session data from server
    App.Auth.loginCheck(@start)

  start: =>
    # create web socket connection
    App.WebSocket.connect()

    # init plugins
    App.Plugin.init(@el)

    # init routes
    App.Router.init(@el)

    # start frontend time update
    @frontendTimeUpdate()

    # bind to fill selected text into
    App.ClipBoard.bind(@el)

    App.Event.trigger('app:ready')
