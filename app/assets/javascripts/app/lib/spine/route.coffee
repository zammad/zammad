# coffeelint: disable=no_this,indentation,arrow_spacing
Spine = @Spine or require('spine')
$     = Spine.$

hashStrip    = /^#*/
namedParam   = /:([\w\d]+)/g
splatParam   = /\*([\w\d]+)/g
escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g


class Path extends Spine.Module

  constructor: (path, callback) ->
    @names = []
    @path = path
    @callback = callback
    if typeof path is 'string'
      namedParam.lastIndex = 0
      while (match = namedParam.exec(path)) != null
        @names.push(match[1])

      splatParam.lastIndex = 0
      while (match = splatParam.exec(path)) != null
        @names.push(match[1])

      path = path.replace(escapeRegExp, '\\$&')
                 .replace(namedParam, '([^\/]*)')
                 .replace(splatParam, '(.*?)')

      @route = new RegExp("^#{path}$")
    else
      @route = path

  match: (path, options = {}) ->
    return false unless match = @route.exec(path)
    options.match = match
    params = match.slice(1)

    if @names.length
      for param, i in params
        options[@names[i]] = param

    Route.trigger('before', this)
    @callback.call(null, options) isnt false


class Route extends Spine.Module
  @extend Spine.Events

  @historySupport: window.history?.pushState?

  @options:
    trigger: true
    history: false
    shim: false
    replace: false
    redirect: false

  @routers: []

  @setup: (options = {}) ->
    @options = $.extend({}, @options, options)

    if @options.history
      @history = @historySupport and @options.history

    return if @options.shim

    if @history
      $(window).bind('popstate', @change)
    else
      $(window).bind('hashchange', @change)
    @change()

  @unbind: ->
    unbindResult = Spine.Events.unbind.apply this, arguments
    return unbindResult if arguments.length > 0

    return if @options.shim

    if @history
      $(window).unbind('popstate', @change)
    else
      $(window).unbind('hashchange', @change)

  @navigate: (args...) ->
    options = {}
    lastArg = args[args.length - 1]
    if typeof lastArg is 'object'
      options = args.pop()
    else if typeof lastArg is 'boolean'
      options.trigger = args.pop()
    options = $.extend({}, @options, options)

    path = args.join('/')
    return if @path is path
    @path = path

    if options.trigger
      @trigger('navigate', @path)
      routes = @matchRoutes(@path, options)
      unless routes.length
        if typeof options.redirect is 'function'
          return options.redirect.apply this, [@path, options]
        else
          if options.redirect is true
            @redirect(@path)

    if options.shim
      true
    else if @history and options.replace
      history.replaceState({}, document.title, @path)
    else if @history
      history.pushState({}, document.title, @path)
    else
      window.location.hash = @path

  @create: ->
    router = new this
    @routers.push router
    router

  @add: (path, callback) ->
    #@router ?= new this
    @router.add path, callback

  add: (path, callback) ->
    if typeof path is 'object' and path not instanceof RegExp
      @add(key, value) for key, value of path
    else
      @routes.push(new Path(path, callback))

  destroy: ->
    @routes.length = 0
    @constructor.routers = (r for r in @constructor.routers when r isnt this)

  # Private

  @getPath: ->
    if @history
      path = window.location.pathname
      path = '/' + path if path.substr(0,1) isnt '/'
    else
      path = window.location.hash
      path = path.replace(hashStrip, '')
    path

  @getHost: ->
    "#{window.location.protocol}//#{window.location.host}"

  @change: =>
    path = @getPath()
    return if path is @path
    @path = path
    @matchRoutes(@path)

  @matchRoutes: (path, options)->
    matches = []
    for router in @routers.concat [@router]
      match = router.matchRoute path, options
      matches.push match if match
    @trigger('change', matches, path) if matches.length
    matches

  @redirect: (path) ->
    window.location = path

  constructor: ->
    @routes = []

  matchRoute: (path, options) ->
    for route in @routes when route.match(path, options)
      return route

  trigger: (args...) ->
    args.splice(1, 0, this)
    @constructor.trigger(args...)

Route.router = new Route


Spine.Controller.include
  route: (path, callback) ->
    if @router instanceof Spine.Route
      @router.add(path, @proxy(callback))
    else
      Spine.Route.add(path, @proxy(callback))

  routes: (routes) ->
    @route(key, value) for key, value of routes

  navigate: ->
    Spine.Route.navigate.apply(Spine.Route, arguments)

Route.Path      = Path
Spine.Route     = Route
module?.exports = Route
