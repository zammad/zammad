class App.Track
  _instance = undefined

  @init: ->
    _instance ?= new _trackSingleton

  @log: ( area, level, args ) ->
    if _instance == undefined
      _instance ?= new _trackSingleton
    _instance.log( area, level, args )

  @send: ->
    if _instance == undefined
      _instance ?= new _trackSingleton
    _instance.send()

  @_all: ->
    if _instance == undefined
      _instance ?= new _trackSingleton
    _instance._all()

class _trackSingleton
  constructor: ->
    @trackId = 'track-' + new Date().getTime() + '-' + Math.floor( Math.random() * 99999 )
    @browser = App.Browser.detection()
    @data    = []
    @url     = 'https://portal.znuny.com/api/ui'
#    @url     = 'api/ui'

    @log( 'start', 'notice', {} )

    # start initial submit 10 sec. later to avoid ie10 cookie issues
    delay = =>
      App.Interval.set @send, 60000
    App.Delay.set delay, 10000

    # log clicks
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
        @log( 'click', 'notice', info )
    )

    # log ajax calls
    $(document).bind( 'ajaxComplete', ( e, request, settings ) =>
      length = @url.length
      if settings.url.substr(0,length) isnt @url && settings.url.substr(0,6) isnt 'api/ui'
        level = 'notice'
        responseText = ''
        if request.status >= 400
          level = 'error'
          responseText = request.responseText
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
        @log( 'end', 'notice', {} )
        @send(false)
        return
    )


  log: ( area, level, args ) ->
    info =
      time:     Math.round( new Date().getTime() / 1000 )
      area:     area
      level:    level
      location: window.location.href
      data:     args
    @data.push info

  send: (async = true) =>
    return if _.isEmpty @data
    newData = _.clone( @data )
    @data = []
    newDataNew = [] 
    for item in newData
      try
        itemNew = _.clone( item )
        JSON.stringify(item)

        # add browser info
        for item, value of @browser
          itemNew[item] = value
        newDataNew.push itemNew
      catch e
        # nothing

    App.Ajax.request(
      type:   'POST'
      url:    @url
      async:  async
      data:   JSON.stringify(
        track_id: @trackId
        log:      newDataNew
      )
      crossDomain: true
#      success: (data, status, xhr) =>
#        @data = []
#        console.log('done')
      error: =>

        # queue all data
        for item in newDataNew
          @data.push item
    )

  _all: ->
    @data

`
window.onerror = function(errorMsg, url, lineNumber) {
  console.error(errorMsg + " - in " + url + ", line " + lineNumber);
};

(function() {
  var console = window.console
  if (!console) return
  function intercept(method){
    var original = console[method]
    console[method] = function(){

      //alert('new m' + method)
      App.Track.log(
        'console.' + method,
        method,
        arguments
      )

      // do sneaky stuff
      if (original.apply){
        // Do this for normal browsers
        original.apply(console, arguments)
      }
      else{
        // Do this for IE
        var message = Array.prototype.slice.apply(arguments).join(' ')
        original(message)
      }
    }
  }
  var methods = ['log', 'warn', 'error']
  for (var i = 0; i < methods.length; i++)
    intercept(methods[i])
}).call(this);
`
