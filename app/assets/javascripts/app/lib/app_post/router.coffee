class App.Router extends Spine.Controller
  @init: (el) ->
    new App.Router(el)

  constructor: (el) ->
    routes = App.Config.get('Routes')
    for route, callback of routes
      do (route, callback) =>
        @route(route, (params) ->

          App.Log.debug 'execute page controller', route, params

          # remember history
          # needed to mute "redirect" url to support browser back
          history = App.Config.get('History')
          if history[10]
            history.shift()
          history.push window.location.hash

          # execute controller
          controller = (params) ->
            params.appEl = el
            try
              new callback(params)
            catch e
              App.Log.error "route #{route}:", e
          controller(params)
        )

    Spine.Route.setup()
