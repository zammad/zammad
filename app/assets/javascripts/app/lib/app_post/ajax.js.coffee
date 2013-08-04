class App.Com
  _instance = undefined # Must be declared here to force the closure on the class
  @ajax: (args) -> # Must be a static method
    if _instance == undefined
      _instance ?= new _ajaxSingleton
    _instance.ajax(args)

# The actual Singleton class
class _ajaxSingleton
  defaults:
    contentType: 'application/json'
    dataType: 'json'
    processData: false
    headers: {'X-Requested-With': 'XMLHttpRequest'}
    cache: false
    async: true

  current_request: {}
  queue_list: []
  queue_running: false
  count: 0

  constructor: (@args) ->

    # run queue
    @_run()

    # bindings
    $(document).bind( 'ajaxSend', =>
      @_show_spinner()
    ).bind( 'ajaxComplete', =>
      @_hide_spinner()
    )

    # show error messages
    $(document).bind( 'ajaxError', ( e, jqxhr, settings, exception ) ->
      status = jqxhr.status
      detail = jqxhr.responseText
      if !status && !detail
        detail = 'General communication error, maybe internet is not available!'

      # do not show aborded requests
      return if status is 0

      # do not show any error message on wrong login
      return if status is 401 && !settings.url.match('login')

      # do not show any error message with code 200
      return if status is 200

      # show human readable message
      if status is 401
        status = 'Access denied.'
        detail = ''

      # show error message
      new App.ErrorModal(
        message: 'StatusCode: ' + status
        detail:  detail
        close:   true
      )
    )

  ajax: (params) ->
    data = $.extend({}, @defaults, params )
    if params['id']
      if @current_request[ params['id'] ]
        @current_request[ params['id'] ].abort()
      @current_request[ params['id'] ] = $.ajax( data )
    else
      if params['queue']
        @queue_list.push data
        if !@queue_running
          @_run()
      else
        $.ajax(data)

  _run: =>
    if @queue_list && @queue_list[0]
      @queue_running = true
      request = @queue_list.shift()
      request.complete = =>
        @queue_running = false
        @_run()
      $.ajax( request )

  _show_spinner: =>
    @count++
    $('.spinner').show()

  _hide_spinner: =>
    @count--
    if @count == 0
      $('.spinner').hide()

    else if App.WebSocket.channel() is 'ajax'
      if @count == 1
        $('.spinner').hide()
