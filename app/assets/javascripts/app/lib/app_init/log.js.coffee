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

class _Singleton
  constructor: ->
    @config = {}
#    @config['Collection'] = true
#      Session: true
#      ControllerForm: true

  log: ( module, level, args ) ->
    if !@config || level isnt 'debug'
      @_log( module, level, args )
    else if @config[ module ]
      @_log( module, level, args )

  _log: ( module, level, args ) ->
    if level is 'error'
      console.error "App.#{module}(#{level})", args
    else if level is 'debug'
      console.debug "App.#{module}(#{level})", args
    else
      console.log "App.#{module}(#{level})", args

