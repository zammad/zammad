class App.Run extends App.Controller
  constructor: ->
    super
    @el = $('#app')

    App.Event.trigger('app:init')

    # browser check
    if !App.Browser.check()
      return

    # hide splash screen
    $('#splash').hide()

    # init collections
    App.Collection.init()

    # create web socket connection
    App.WebSocket.connect()

    # check if session already exists/try to get session data from server
    App.Auth.loginCheck()

    # start navbars
    @setupWidget( 'Navigations', 'nav', @el.find('nav') )

    # start widgets
    @setupWidget( 'Widgets', 'widget', @el.find('section') )

    # start widgets
    @setupWidget( 'Footers', 'footer', @el.find('footer') )

    # bind to fill selected text into
    App.ClipBoard.bind( @el )

    App.Event.trigger('app:ready')

  setupWidget: (config, event, el) ->

    # start widgets
    App.Event.trigger( event + ':init')
    widgets = App.Config.get( config )
    if widgets
      for key, widget of widgets
        el.append('<div id="' + key + '"></div>')
        new widget( el: el.find("##{key}") )
    App.Event.trigger( event + ':ready')

class App.Content extends App.Controller
  className: 'container'

  constructor: ->
    super

    Routes = @Config.get( 'Routes' )
    for route, callback of Routes
      do (route, callback) =>
        @route(route, (params) ->

          @log 'notice', 'execute page controller', route, params

          # remove observers for page
          App.Collection.observeUnbindLevel('page')

          # remove events for page
          App.Event.unbindLevel('page')

          # remove delay for page
          App.Delay.clearLevel('page')

          # remove interval for page
          App.Interval.clearLevel('page')

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

          # execute controller
          controller = (params) =>
            params.el = @el
            new callback( params )
          controller( params )

          # rerender view on ui:rerender event
          App.Event.bind(
            'ui:page:rerender', =>
              controller( params )
            'page'
          )

          # scroll to top / remember last screen position
#          @scrollTo( 0, 0, 100 )
        )

    Spine.Route.setup()

App.Config.set( 'content', App.Content, 'Widgets' )
