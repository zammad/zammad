Spine = @Spine or require('spine')
$     = Spine.$

hashStrip    = /^#*/
namedParam   = /:([\w\d]+)/g
splatParam   = /\*([\w\d]+)/g
escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g

class Spine.Route extends Spine.Module
  @extend Spine.Events

  @historySupport: window.history?.pushState?

  @routes: []

  @options:
    trigger: true
    history: false
    shim: false
    replace: false
    redirect: false

  @add: (path, callback) ->
    if (typeof path is 'object' and path not instanceof RegExp)
      @add(key, value) for key, value of path
    else
      @routes.push(new @(path, callback))

  @setup: (options = {}) ->
    @options = $.extend({}, @options, options)

    if (@options.history)
      @history = @historySupport and @options.history

    return if @options.shim

    if @history
      $(window).bind('popstate', @change)
    else
      $(window).bind('hashchange', @change)
    @change()

  @unbind: ->
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

    @trigger('navigate', @path)

    route = @matchRoute(@path, options) if options.trigger

    return if options.shim

    if !route
      if typeof options.redirect is 'function'
        return options.redirect.apply this, [@path, options]
      else
        if options.redirect is true
          @redirect(@path)

    if @history and options.replace
      history.replaceState({}, document.title, @path)
    else if @history
      history.pushState({}, document.title, @path)
    else
      window.location.hash = @path

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

  @change: ->
    path = @getPath()
    return if path is @path
    @path = path
    @matchRoute(@path)

  @matchRoute: (path, options) ->
    for route in @routes when route.match(path, options)
      @trigger('change', route, path)
      return route

  @redirect: (path) ->
    window.location = path

  constructor: (@path, @callback) ->
    @names = []

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
    match = @route.exec(path)
    return false unless match
    options.match = match
    params = match.slice(1)

    if @names.length
      for param, i in params
        options[@names[i]] = param
    @.constructor.trigger('before', @)
    @callback.call(null, options) isnt false

# Coffee-script bug
Spine.Route.change = Spine.Route.proxy(Spine.Route.change)

Spine.Controller.include
  route: (path, callback) ->
    Spine.Route.add(path, @proxy(callback))

  routes: (routes) ->
    @route(key, value) for key, value of routes

  navigate: ->
    Spine.Route.navigate.apply(Spine.Route, arguments)

module?.exports = Spine.Route
