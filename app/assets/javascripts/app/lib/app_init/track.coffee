# coffeelint: disable=no_backticks
class App.Track
  _instance = undefined

  @init: ->
    _instance ?= new _trackSingleton

  @log: (area, level, args) ->
    if _instance == undefined
      _instance ?= new _trackSingleton
    _instance.log(area, level, args)

  @send: ->
    if _instance == undefined
      _instance ?= new _trackSingleton
    _instance.send()

  @force: (value) ->
    if _instance == undefined
      _instance ?= new _trackSingleton
    _instance.force(value)

  @_all: ->
    if _instance == undefined
      _instance ?= new _trackSingleton
    _instance._all()

class _trackSingleton
  constructor: ->
    @trackId = "track-#{new Date().getTime()}-#{Math.floor(Math.random() * 99999)}"
    @browser = App.Browser.detection() if App.Browser
    @data    = []
#    @url     = 'http://localhost:3005/api/v1/ui'
    @url      = 'https://log.zammad.com/api/v1/ui'
    @logClick = true
    @logAjax  = false

    @forceSending = false

    @log('start', 'notice', {})

    # start initial submit 30 sec. later to avoid ie10 cookie issues
    delay = =>
      App.Interval.set @send, 60000
    App.Delay.set delay, 30000

    # log clicks
    if @logClick
      $(document).bind(
        'click'
        (e) =>
          w = window.screen.width
          h = window.screen.height
          aTag = $(e.target)
          if !aTag.attr('href')
            newTag = $(e.target).parents('a')
            if newTag[0]
              aTag = newTag
          info =
            level:   'notice'
            href:    aTag.attr('href')
            title:   aTag.attr('title')
            text:    aTag.text()
            clickX:  e.pageX
            clickY:  e.pageY
            screenX: w
            screenY: h
          @log('click', 'notice', info)
      )

    # log ajax calls
    if @logAjax
      $(document).bind( 'ajaxComplete', ( e, request, settings ) =>

        # do not log ui requests
        if settings.url && settings.url.substr(settings.url.length-3,3) isnt '/ui'
          level = 'notice'
          responseText = ''
          if request.status >= 400
            level = 'error'
            responseText = request.responseText

          if settings.data

            # add length limitation
            if settings.data.length > 3000
              settings.data = settings.data.substr(0,3000)

            # delete passwords form data
            if typeof settings.data is 'string'
              settings.data = settings.data.replace(/"password":".+?"/gi, '"password":"xxx"')

          @log(
            'ajax.send',
            level,
            {
              type:         settings.type
              dataType:     settings.dataType
              async:        settings.async
              url:          settings.url
              data:         settings.data
              status:       request.status
              responseText: responseText
            }
          )
      )

    $(window).bind(
      'beforeunload'
      =>
        @log('good bye', 'notice', {})
        @send(false)
        return
    )

  log: (facility, level, args) =>
    return if !@shouldSend()
    info =
      time:     Math.round(new Date().getTime() / 1000)
      facility: facility
      level:    level
      location: window.location.pathname + window.location.hash
      message:  args
    @data.push info

  send: (async = true) =>
    return if !@shouldSend()
    return if _.isEmpty @data
    newData = _.clone(@data)
    @data = []
    newDataNew = []
    for item in newData
      try

        # check if strigify is possibe, prevent ajax errors
        JSON.stringify(item)

        newDataNew.push item
      catch e
        console.log 'error', e

    App.Ajax.request(
      type:   'POST'
      url:    @url
      async:  async
      data:   JSON.stringify(
        meta:
          track_id: @trackId
          host:     window.location.host
          protocol: window.location.protocol
        browser: @browser
        log:     newDataNew
      )
      crossDomain: true
      headers:
        'X-Requested-With': 'XMLHttpRequest'
      error: =>
        for item in newDataNew
          @data.push item
    )

  force: (value = true) ->
    @forceSending = value

  shouldSend: ->
    return true if @forceSending
    return false if App.Config.get('developer_mode')
    return false if !App.Config.get('ui_send_client_stats')
    true

  _all: ->
    @data

`
(function() {
  window.getStackTrace = function() {
    var stack
    try {
      throw new Error('')
    }
    catch (error) {
      stack = error.stack || ''
    }

    stack = stack.split('\n').map(function (line) { return line.trim() })
    return stack.splice(stack[0] == 'Error' ? 2 : 1)
  }
  window.onerrorOld = window.onerror
  window.onerror = function(errorMsg, url, lineNumber, column, errorObj) {
    var stack = ''
    if (errorObj !== undefined && errorObj.stack) {
      stack = "\n" + errorObj.stack
    }
    App.Track.log(
      'console.error',
      'error',
      errorMsg + " - in " + url + ", line " + lineNumber + stack
    )
    if (window.onerrorOld) {
      window.onerrorOld(errorMsg, url, lineNumber, column, errorObj)
    }
    return false
  }

  var console = window.console
  if (!console) return
  function intercept(method){
    var original = console[method]
    console[method] = function(){
      App.Track.log(
        'console.' + method,
        method,
        arguments
      )
      if (method == 'error') {
        App.Track.log(
          'traceback',
          method,
          window.getStackTrace().join('\n')
        )
      }

      // do sneaky stuff
      if (original.apply){
        // Do this for normal browsers
        original.apply(console, arguments)
      }
      else {
        // Do this for IE
        var message = Array.prototype.slice.apply(arguments).join(' ')
        original(message)
      }
    }
  }
  var methods = ['debug', 'log', 'warn', 'error']
  for (var i = 0; i < methods.length; i++)
    intercept(methods[i])
}).call(this);
`
