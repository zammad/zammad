_instance = undefined
class App.LogInclude
  @log: (level, args...) ->
    if _instance == undefined
      _instance ?= new _Singleton
    module = @constructor.name
    _instance.log(module, level, args)

class App.Log
  @debug: (module, args...) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.log(module, 'debug', args)

  @notice: (module, args...) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.log(module, 'notice', args)

  @error: (module, args...) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.log(module, 'error', args)

  @config: (type, regex) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.config(type, regex)

  @timeTrack: (message) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.timeTrack(message)

class _Singleton
  constructor: ->
    @moduleColorsMap    = {}
    @currentConfig      = {}
    @currentConfigReady = {}
    if window.localStorage
      raw = window.localStorage.getItem('log_config')
      if raw
        @currentConfig = JSON.parse(raw)
        @configReady()

    # example config to enable debugging
    #@config('module', 'i18n|websocket')
    #@config('content', 'send')

    # detect color support
    @colorSupport = false
    data = App.Browser.detection()
    if data.browser
      if data.browser.name is 'Chrome'
        @colorSupport = true
      else if data.browser.anem is 'Firefox'
        if data.browser.major >= 31.0
          @colorSupport = true
      else if data.browser.name is 'Safari'
        @colorSupport = true

  configReady: ->
    for type, value of @currentConfig
      if type is 'module' || type is 'content'
        @currentConfigReady[type] = new RegExp(value, 'i')
      else
        @currentConfigReady[type] = value

  config: (type = undefined, value = undefined) ->

    # get
    if value is undefined
      if type
        return @currentConfig[type]
      return @currentConfig

    # set runtime config
    @currentConfig[type] = value
    @configReady()

    if window.localStorage
      window.localStorage.setItem('log_config', JSON.stringify(@currentConfig))

  log: (module, level, args) ->
    if level is 'debug'
      return if !@currentConfigReady.module && !@currentConfigReady.content
      return if @currentConfigReady.module && !module.match(@currentConfigReady.module)
      return if @currentConfigReady.content && !args.toString().match(@currentConfigReady.content)
    @_log(module, level, args)

  _log: (module, level, args) ->
    prefixLength = 32
    prefix       = "App.#{module}(#{level})"
    if prefix.length < prefixLength
      prefix += Array(prefixLength - prefix.length).join(' ')
    prefix += '|'

    if @colorSupport
      prefix = '%c' + prefix
      if !@moduleColorsMap[module]
        @moduleColorsMap[module]= @yieldColor()
      color       = @moduleColorsMap[module]
      colorString = 'color: hsl(' + (color) + ',99%,40%); font-weight: bold'
      logArgs     = [prefix, colorString].concat(args)
    else
      logArgs = [prefix].concat(args)

    if level is 'error'
      console.error.apply console, logArgs
    else if level is 'debug'
      console.debug.apply console, logArgs
    else
      console.log.apply console, logArgs

  # used inpirations from http://latentflip.com/bows/
  yieldColor: =>
    if !@hue
      @hue = 0
    @hue += 1
    goldenRatio = 0.618033988749895
    @hue += goldenRatio
    @hue = @hue % 1
    @hue * 360

  timeTrack: (message) =>
    currentTime = new Date().getTime()
    if !@lastTime
      @lastTime = currentTime
      console.log('timeTrack start', message)
    else
      diff = currentTime - @lastTime
      @lastTime = currentTime
      console.log('timeTrack start', message, diff)
