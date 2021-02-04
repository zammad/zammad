###
  App.Ajax.request(
    id:    'search'
    type:  'GET'
    url:   url
    data:
      qeury: query
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

  @queue: ->
    if _instance == undefined
      _instance ?= new _ajaxSingleton
    _instance.queue()

  @current: ->
    if _instance == undefined
      _instance ?= new _ajaxSingleton
    _instance.current()

  @token: ->
    if _instance == undefined
      _instance ?= new _ajaxSingleton
    _instance.token()

# The actual Singleton class
class _ajaxSingleton
  defaults:
    contentType: 'application/json'
    dataType: 'json'
    processData: false
    headers:
      'X-Requested-With': 'XMLHttpRequest'
    cache: false
    async: true
  currentToken: null
  currentRequest: {}
  queueList: []
  queueRunning: false
  count: 0

  constructor: (@args) ->

    # run queue
    @runNextInQueue()

    # bindings
    $(document).bind('ajaxSend', =>
      @_show_spinner()
    ).bind('ajaxComplete', (request, xhr, settings) =>
      @_hide_spinner()

      # remeber XSRF-TOKEN for later
      CSRFToken = xhr.getResponseHeader('CSRF-TOKEN')
      return if !CSRFToken
      @currentToken = CSRFToken
      @defaults.headers['X-CSRF-Token'] = CSRFToken
      Spine.Ajax.defaults.headers['X-CSRF-Token'] = CSRFToken
    )

    # show error messages
    $(document).bind('ajaxError', (e, jqxhr, settings, exception) ->
      status = jqxhr.status
      detail = jqxhr.responseText
      if !status && !detail
        detail = 'General communication error, maybe internet is not available!'

      # do not show aborded requests
      return if status is 0

      # 200, all is fine
      return if status is 200

      # do not show any error message for various 4** codes (handled by controllers)
      return if status is 401
      return if status is 403
      return if status is 404
      return if status is 422

      # do not show any error message with code 502
      return if status is 502

      # show error message
      new App.ControllerModal(
        head:          "StatusCode: #{status}"
        contentInline: "<pre>#{App.Utils.htmlEscape(detail)}</pre>"
        buttonClose:   true
        buttonSubmit:  false
      )
    )

  request: (params) ->
    data = $.extend({}, @defaults, params)

    # execute call with id, clear old call first if exists
    if data['id']
      @abort(data['id'])
      @addCurrentRequest(data['id'], data)
      return data['id']

    # generate a uniq rand id
    data['id'] = "rand-#{new Date().getTime()}-#{Math.floor(Math.random() * 99999)}"

    # queue request
    if data['queue']
      @queueList.push data
      if !@queueRunning
        @runNextInQueue()

    # execute request
    else
      @addCurrentRequest(data['id'], data)
    data['id']

  addCurrentRequest: (id, data, queueRunning) =>
    data.complete = =>
      if queueRunning
        @queueRunning = false
      @removeCurrentRequest(id)
      if queueRunning
        @runNextInQueue()
    @currentRequest[id] = $.ajax(data)
    return if data.async is true
    @removeCurrentRequest(id)

  removeCurrentRequest: (id) =>
    @currentRequest[id] = undefined
    delete @currentRequest[id]

  abort: (id) =>

    # abort currentRequest
    if @currentRequest[id]
      @currentRequest[id].abort()
      @currentRequest[id] = undefined
      delete @currentRequest[id]

    # remove from queue list
    @queueList = _.filter(
      @queueList
      (item) ->
        return item if item['id'] isnt id
        return
    )

  abortAll: =>
    abortedIds = []
    for id, ajax of @currentRequest
      @abort(id)
      abortedIds.push id
    abortedIds

  runNextInQueue: =>
    return if !@queueList || !@queueList[0]
    @queueRunning = true
    data = @queueList.shift()
    @addCurrentRequest(data['id'], data, true)

  queue: =>
    @queueList

  current: =>
    @currentRequest

  token: =>
    @currentToken

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
