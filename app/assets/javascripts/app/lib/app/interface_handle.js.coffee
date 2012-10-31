
class App.Run extends App.Controller
  constructor: ->
    super
    @log 'RUN app'
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

    # bind to fill selected text into
    App.ClipBoard.bind( @el )

class App.Content extends Spine.Controller
  className: 'container'

  constructor: ->
    super
    @log 'RUN content'

    for route, callback of Config.Routes
      do (route, callback) =>
        @route(route, (params) ->

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

          # scroll to top
#          window.scrollTo(0,0)
        )

    Spine.Route.setup()