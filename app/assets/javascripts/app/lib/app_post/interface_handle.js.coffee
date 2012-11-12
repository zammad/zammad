
class App.Run extends App.Controller
  constructor: ->
    super
    @el = $('#app')

    # init collections
    App.Collection.init()

    # create web socket connection
    App.WebSocket.connect()

    # init of i18n
    App.i18n.init()

    # start navigation controller
    new App.Navigation( el: @el.find('#navigation') )

    # check if session already exists/try to get session data from server
    App.Auth.loginCheck()

    # start notify controller
    new App.Notify( el: @el.find('#notify') )

    # start content
    new App.Content( el: @el.find('#content') )

    # start chat
    new App.ChatWidget( el: @el.find('#chat') )

    # bind to fill selected text into
    App.ClipBoard.bind( @el )

class App.Content extends App.Controller
  className: 'container'

  constructor: ->
    super

    Routes = @Config.get( 'Routes' )
    for route, callback of Routes
      do (route, callback) =>
        @route(route, (params) ->

          @log 'Content', 'notice', 'execute page controller', route, params

          # remove observers for page
          App.Collection.observeUnbindLevel('page')

          # remove events for page
          App.Event.unbindLevel('page')

          # unbind in controller area
          @el.unbind()
          @el.undelegate()

          # send current controller
          params_only = {}
          for i of params
            if typeof params[i] isnt 'object'
              params_only[i] = params[i]

          # tell server what we are calling right now
          App.WebSocket.send(
            action:     'active_controller',
            controller: route,
            params:     params_only,
          )

          # remove waypoints
          $('footer').waypoint('remove')

          params.el = @el
          new callback( params )

          # scroll to top / remember last screen position
#          @scrollTo( 0, 0, 100 )
        )

    Spine.Route.setup()