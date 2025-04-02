class App.Plugin
  _instance = undefined

  @init: (el) ->
    if _instance == undefined
      _instance ?= new _pluginSingleton
    _instance.init(el)

  @instance: ->
    _instance

class _pluginSingleton
  backends: {}
  el: undefined

  constructor: ->

  init: (el) =>
    @appEl = el if el
    @setupAll()

    App.Event.bind('auth:login auth:logout', (user) =>
      @setupAll()
    )

  setupAll: =>
    @appEl.empty()
    for key, backend of @backend
      if backend.release
        backend.release()
      if backend.releaseController
        backend.releaseController()
    @backend = {}
    @setup('Plugins', 'plugin')

  setup: (config, event) ->

    # start plugins
    App.Event.trigger(event + ':init')
    plugins = App.Config.get(config)
    if plugins
      sortedKeys = Object.keys(plugins).sort()
      for key in sortedKeys
        plugin = plugins[key]
        try
          @backend[key] = new plugin(
            appEl: @appEl
            key: key
          )
        catch e
          App.Log.error "plugin #{key}:", e
    App.Event.trigger(event + ':ready')
