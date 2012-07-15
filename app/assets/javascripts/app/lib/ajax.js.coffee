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

  ajax: (params, defaults) ->
    data = $.extend({}, @defaults, defaults, params)
    @count++
    @_show_spinner()
#    console.log( 'START', @count )
    if params['id']
      if @queue_list[ params['id'] ]
        @queue_list[ params['id'] ].abort()
      @queue_list[ params['id'] ] = $.ajax( data ).always( @_hide_spinner )
    else
      $.ajax( data ).always( @_hide_spinner )

    console.log('AJAX', params['url'] )

  _show_spinner: =>
    $('.spinner').show()

  _hide_spinner: =>
    @count--
    if @count == 0
      $('.spinner').hide()

