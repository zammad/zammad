_instance = undefined
class App.LogInclude
  @log: ( level, args... ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    module = @constructor.name
    _instance.log( module, level, args )

class App.Log
  @debug: ( module, args... ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.log( module, 'debug', args )

  @notice: ( module, args... ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.log( module, 'notice', args )

  @error: ( module, args... ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.log( module, 'error', args )

  @config: ( type, regex ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.config( type, regex )

class _Singleton
  constructor: ->
    @moduleColorsMap = {}
    @currentConfig = {}
    if window.localStorage
      raw = window.localStorage.getItem('log_config')
      if raw
        @currentConfig = JSON.parse(raw)

    # example config to enable debugging
    #@config('module', 'i18n|websocket')
    #@config('content', 'send')

    # detect color support
    @colorSupport = false
    data = App.Browser.detection()
    if data && (data.browser is 'Chrome' || ( data.browser is 'Firefox' && data.version >= 31.0 ) )
      @colorSupport = true

  config: (type = undefined, value = undefined) ->

    # get
    if value is undefined
      if type
        return @currentConfig[type]
      return @currentConfig

    # set
    if type is 'module' || type is 'content'
      @currentConfig[type] = new RegExp(value, 'i')
    else
      @currentConfig[type] = value
    if window.localStorage
      window.localStorage.setItem('log_config', JSON.stringify(@currentConfig))

  log: ( module, level, args ) ->
    if level is 'debug'
      return if !@currentConfig.module && !@currentConfig.content
      return if @currentConfig.module && !module.match(@currentConfig.module)
      return if @currentConfig.content && !args.toString().match(@currentConfig.content)
    @_log( module, level, args )

  _log: ( module, level, args ) ->
    prefixLength = 28
    prefix       = "App.#{module}(#{level})"
    if prefix.length < prefixLength
      prefix += Array(prefixLength - prefix.length).join(' ')
    prefix += '|'
    prefix = '%c' + prefix

    if @colorSupport
      if !@moduleColorsMap[module]
        @moduleColorsMap[module]= @yieldColor()
      color       = @moduleColorsMap[module]
      colorString = "color: hsl(" + (color) + ",99%,40%); font-weight: bold";
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