###
  App.Ajax.request(
    id:    'search'
    type:  'GET'
    url:   url
    data:
      term: term
    processData: true,
    success: (data, status, xhr) =>
      console.log(data, status)
    error: (xhr, statusText, error) =>
      console.log(statusText, error)
  )
###

class App.Ajax
  _instance = undefined
  @request: (args) ->
    if _instance == undefined
      _instance ?= new _ajaxSingleton
    _instance.request(args)

  @abort: (args) ->
    if _instance == undefined
      _instance ?= new _ajaxSingleton
    _instance.abort(args)

  @abortAll: ->
    if _instance == undefined
      _instance ?= new _ajaxSingleton
    _instance.abortAll()

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

      # 200, all is fine
      return if status is 200

      # do not show any error message with code 401/404 (handled by controllers)
      return if status is 401
      return if status is 404
      return if status is 422

      # do not show any error message with code 502
      return if status is 502

      # show error message
      new App.ControllerModal(
        head:          'StatusCode: ' + status
        contentInline: '<pre>' + App.Utils.htmlEscape(detail) + '</pre>'
        buttonClose:   true
        buttonSubmit:  false
      )
    )

  request: (params) ->
    data = $.extend({}, @defaults, params )

    # execute call with id, clear old call first if exists
    if params['id']
      @abort( params['id'] )
      @current_request[ params['id'] ] = $.ajax( data )
      return params['id']

    # generate a uniq rand id
    params['id'] = 'rand-' + new Date().getTime() + '-' + Math.floor( Math.random() * 99999 )

    # queue request
    if params['queue']
      @queue_list.push data
      if !@queue_running
        @_run()

    # execute request
    else
      @current_request[ params['id'] ] = $.ajax(data)

    params['id']

  abort: (id) =>

    # abort current_request
    if @current_request[ id ]
      @current_request[ id ].abort()
      delete @current_request[ id ]

    # remove from queue list
    @queue_list = _.filter(
      @queue_list
      (item) ->
        return item if item['id'] isnt id
        return
    )

  abortAll: =>
    return if !@current_request
    abortedIds = []
    for id, ajax of @current_request
      @abort(id)
      abortedIds.push id
    abortedIds

  _run: =>
    if @queue_list && @queue_list[0]
      @queue_running = true
      request = @queue_list.shift()
      request.complete = =>
        @queue_running = false
        @_run()
      @current_request[ request['id'] ] = $.ajax( request )

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
