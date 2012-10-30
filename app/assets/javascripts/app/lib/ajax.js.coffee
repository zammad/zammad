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
    $('body').bind( 'ajaxError', (e,jqxhr, settings, exception) ->
      new App.ErrorModal(
        message: 'StatusCode: ' + jqxhr.status
        detail:  jqxhr.responseText
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

