$ = jQuery.sub()

class App.Com
  _instance = undefined # Must be declared here to force the closure on the class
  @ajax: (args) -> # Must be a static method
    if _instance == undefined
      _instance ?= new _Singleton

    _instance.ajax(args)
    _instance

# The actual Singleton class
class _Singleton
  defaults:
    contentType: 'application/json'
    dataType: 'json'
    processData: false
    headers: {'X-Requested-With': 'XMLHttpRequest'}
    cache: false
    async: true

  queue_list: {}
  count: 0

  constructor: (@args) ->

    # bindings
    $('body').bind( 'ajaxSend', =>
      @_show_spinner()
    ).bind( 'ajaxComplete', =>
      @_hide_spinner()
    )

    # show error messages
    $('body').bind( 'ajaxError', ( e, jqxhr, settings, exception ) ->
      status = jqxhr.status
      detail = jqxhr.responseText
      if !status && !detail
        detail = 'General communication error, maybe internet is not available!'
      new App.ErrorModal(
        message: 'StatusCode: ' + status
        detail:  detail
        close:   true
      )
    )

  ajax: (params, defaults) ->
    data = $.extend({}, @defaults, defaults, params)
    if params['id']
      if @queue_list[ params['id'] ]
        @queue_list[ params['id'] ].abort()
      @queue_list[ params['id'] ] = $.ajax( data )
    else
      $.ajax( data )

#    console.log('AJAX', params['url'] )

  _show_spinner: =>
    @count++
    $('.spinner').show()

  _hide_spinner: =>
    @count--
    if @count == 0
      $('.spinner').hide()

