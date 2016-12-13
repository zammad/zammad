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

    # start frontend time update
    @frontendTimeUpdate()

    # start navbars
    @setupWidget('Navigations', 'nav', @el)

    # start widgets
    @setupWidget('Widgets', 'widget', @el)

    # bind to fill selected text into
    App.ClipBoard.bind(@el)

    App.Event.trigger('app:ready')

  setupWidget: (config, event, el) ->

    # start widgets
    App.Event.trigger(event + ':init')
    widgets = App.Config.get(config)
    if widgets
      sortedKeys = Object.keys(widgets).sort()
      for key in sortedKeys
        widget = widgets[key]
        try
          new widget(
            el:  el
            key: key
          )
        catch e
          @log 'error', "widget #{key}:", e
    App.Event.trigger(event + ':ready')

class App.Content extends App.ControllerWidgetPermanent
  className: 'content flex horizontal'

  constructor: ->
    super

    Routes = @Config.get('Routes')
    for route, callback of Routes
      do (route, callback) =>
        @route(route, (params) ->

          @log 'debug', 'execute page controller', route, params

          # remove events for page
          App.Event.unbindLevel('page')

          # remove delay for page
          App.Delay.clearLevel('page')

          # remove interval for page
          App.Interval.clearLevel('page')

          # unbind in controller area
          @el.unbind()
          @el.undelegate()

          # remember history
          # needed to mute "redirect" url to support browser back
          history = App.Config.get('History')
          if history[10]
            history.shift()
          history.push window.location.hash

          # execute controller
          controller = (params) =>
            params.el = @el
            try
              new callback(params)
            catch e
              @log 'error', "route #{route}:", e
          controller(params)
        )

    Spine.Route.setup()

App.Config.set('content', App.Content, 'Widgets')
