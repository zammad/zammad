class App.Log
  _instance = undefined

  @log: ( module, level, args... ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.log( module, level, args )

  @debug: ( module, level, args... ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.log( module, level, args )


class _Singleton
  constructor: ->
    @config = {}
#      Session: true
#      ControllerForm: true

  log: ( module, level, args ) ->
    if !@config || level isnt 'debug'
      @_log( module, level, args )
    else if @config[ module ]
      @_log( module, level, args )


  _log: ( module, level, args ) ->
    return if !console
    console.log "App.#{module}(#{level})", args

