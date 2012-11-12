class App.Log
  _instance = undefined

#  @sub: (module) ->
#  @module: (name) ->

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
    console.log 'NNNNNNNEEEWWW LOG!!!'
    @config = {}
#      Session: true
#      ControllerForm: true

  log: ( module, level, args ) ->
    if !@config || level isnt 'debug'
      @_log( module, level, args )
    else if @config[ module ]
      @_log( module, level, args )


  _log: ( module, level, args ) ->
    console.log "App.#{module}(#{level})", args

