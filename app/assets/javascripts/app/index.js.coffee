#s#= require json2
#= require ./lib/jquery-1.7.2.min.js
#= require ./lib/ui/jquery-ui-1.8.18.custom.min.js

#= require ./lib/spine/spine.coffee
#= require ./lib/spine/ajax.coffee
#= require ./lib/spine/route.coffee

#= require ./lib/bootstrap-dropdown.js
#= require ./lib/bootstrap-tooltip.js
#= require ./lib/bootstrap-popover.js
#= require ./lib/bootstrap-modal.js
#= require ./lib/bootstrap-tab.js

#= require ./lib/underscore.coffee
#= require ./lib/ba-linkify.js
#= require ./lib/jquery.tagsinput.js
#= require ./lib/jquery.noty.js
#= require ./lib/waypoints.js
#= require ./lib/fileuploader.js
#= require ./lib/jquery.elastic.source.js

#not_used= require_tree ./lib
#= require_self
#= require_tree ./models
#= require_tree ./controllers
#= require_tree ./views

class App extends Spine.Controller
  @view: (name) ->
    JST["app/views/#{name}"]

###
class App.Config extends Spine.Module
  constructor: ->
    super
    @config = {}
    
  set: (key, value) =>
    @config[key] = value
    
  get: (key) =>
    @config[key]
    
  append: (key, value) =>
    if !@config[key]
      @config[key] = []
      
    @config[key].push = value


Config2 = new App.Config
Config2.set( 'a', 123)
console.log '1112222', Config2.get( 'a')
###

class App.Ajax
  defaults:
    contentType: 'application/json'
    dataType: 'json'
    processData: false
    headers: {'X-Requested-With': 'XMLHttpRequest'}
    cache: false
    async: true

  ajax: (params, defaults) ->
    $.ajax($.extend({}, @defaults, defaults, params))

class App.Auth extends App.Ajax
  constructor: ->
    console.log 'auth'

  login: (params) ->
    console.log 'login(...)', params
    @ajax(
#      params,
      type:   'POST',
      url:     '/signin',
      data:    JSON.stringify(params.data),
      success: params.success,
      error:   params.error,
    )

  loginCheck: ->
    console.log 'loginCheck(...)'
    @ajax(
      async: false,
      type:  'GET',
      url:   '/signshow',
      success: (data, status, xhr) =>
        console.log 'logincheck:success', data

        # if session is not valid
        if data.error
  
          # update config
          for key, value of data.config
            window.Config[key] = value

          # empty session
          window.Session = {}

          # rebuild navbar with new navbar items
          Spine.trigger 'navrebuild'

          return false;

        # set avatar
        if !data.session.image
          data.session.image = 'http://placehold.it/48x48'

        # update config
        for key, value of data.config
          window.Config[key] = value

        # store user data
        for key, value of data.session
          window.Session[key] = value
    
        # refresh/load default collections
        for key, value of data.default_collections
          App[key].refresh( value, options: { clear: true } )

        # rebuild navbar with new navbar items
        Spine.trigger 'navrebuild', data.session
    
        # rebuild navbar with updated ticket count of overviews
        Spine.trigger 'navupdate_remote'


      error: (xhr, statusText, error) =>
        console.log 'loginCheck:error'#, error, statusText, xhr.statusCode
       
        # empty session
        window.Session = {}

    )

  logout: ->
    console.log 'logout(...)'
    @ajax(
      type: 'DELETE',
      url:  '/signout',
    )

class App.i18n extends App.Ajax
#  @include App.Ajax

  constructor: ->
    @locale = 'de'
    @set( @locale )
    window.T = @translate_content
    window.Ti = @translate_inline

#    $('.translation [contenteditable]')
    $('body')
      .delegate '.translation', 'focus', (e) =>
        $this = $(e.target)
        $this.data 'before', $this.html()
#        console.log('11111current', $this.html())
        return $this
#      .delegate '.translation', 'blur keyup paste', (e) =>
      .delegate '.translation', 'blur', (e) =>
        $this = $(e.target)
        source = $this.attr('data-text')

        # get new translation
        translation_new = $this.html()
        translation_new = ('' + translation_new)
          .replace(/<.+?>/g, '')
          
        # set new translation
        $this.html(translation_new)
        
        # update translation
        return if $this.data('before') is translation_new
        console.log 'Translation Update', translation_new, $this.data 'before'
        $this.data 'before', translation_new

        # update runtime translation map
        @map[ source ] = translation_new

        # replace rest in page
        $(".translation[data-text='#{source}']").html( translation_new )

        # update permanent translation map
        translation = App.Translation.findByAttribute( 'source', source )
        if translation
          translation.updateAttribute( 'target', translation_new )
        else
          translation = new App.Translation
          translation.load(
            locale: @locale,
            source: source,
            target: translation_new,
          )
          translation.save()

        return $this

  set: (locale) =>
    @map = {}
    @ajax(
      type:   'GET',
      url:    '/translations/lang/' + locale,
      async:  false,
      success: (data, status, xhr) =>

        # load translation collection
        for object in data

          # set runtime lookup table
          @map[ object[1] ] = object[2]

          # load in collection if needed
          App.Translation.refresh( { id: object[0], source: object[1], target: object[2], locale: @locale }, options: { clear: true } )

      error: (xhr, statusText, error) =>
        console.log 'error', error, statusText, xhr.statusCode
    )

  translate_inline: (string, args...) =>
    @translate(string, args...)

  translate_content: (string, args...) =>
    translated = @translate(string, args...)
#    replace = '<span class="translation" contenteditable="true" data-text="' + @escape(string) + '">' + translated + '<span class="icon-edit"></span>'
    if window.Config['Translation']
      replace = '<span class="translation" contenteditable="true" data-text="' + @escape(string) + '">' + translated + ''
  #    if !@_translated
  #       replace += '<span class="missing">XX</span>'
      replace += '</span>'
    else
      translated

  translate: (string, args...) =>

    # return '' on undefined
    return '' if string is undefined

    # return translation
    if @map[string] isnt undefined
      @_translated = true
      translated = @map[string]
    else
      @_translated = false
      translated = string
      
    # search %s
    for arg in args
      translated = translated.replace(/%s/, arg)

    # escape
    translated = @escape(translated)

    # return translated string
    return translated

  escape: (string) ->
    string = ('' + string)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/\x22/g, '&quot;')

class App.Run extends Spine.Controller
  constructor: ->
    super
    @log 'RUN app'#, @
    @el = $('#app')

    # init of i18n
    new App.i18n

    # start navigation controller
    new App.Navigation( el: @el.find('#navigation') );

    # check if session already exists/try to get session data from server
    auth = new App.Auth
    auth.loginCheck()

    # start notify controller
    new App.Notify( el: @el.find('#notify') );
    
    # start content
    new App.Content( el: @el.find('#content') );

    # bind to fill selected text into
    $(@el).bind('mouseup', =>
      window.Session['UISeletion'] = @getSelected() + ''
    )

#    @ws = new WebSocket("ws://localhost:3001/");
  
    # Set event handlers.
#    @ws.onopen = ->
#      console.log("onopen")

#    @ws.onmessage = (e) ->
      # e.data contains received string.
#      console.log("onmessage: " + e.data)
#      eval e.data

#    Spine.bind 'ws:send', (data) =>
#      @log 'ws:send', data
#      @ws.send(data);

#    @ws.onclose = ->
#      console.log("onclose")

#    @ws.onerror = ->
#      console.log("onerror")
      
  getSelected: ->
    text = '';
    if window.getSelection
      text = window.getSelection()
    else if document.getSelection
      text = document.getSelection()
    else if document.selection
      text = document.selection.createRange().text
    text

class App.Content extends Spine.Controller
  className: 'container'

  constructor: ->
    super
    @log 'RUN content'#, @

    for route, callback of Config.Routes
      do (route, callback) =>
        @route(route, (params) ->
          Config['ActiveController'] = route
          Spine.trigger( 'ws:send', JSON.stringify( { action: 'active_controller', controller: route, params: params } ) )

          # unbind in controller area
          @el.unbind()
          @el.undelegate()
 
          # remove waypoints
          $('footer').waypoint('remove')
 
          params.el = @el
          params.auth = @auth
          new callback( params )

          # scroll to top
#          window.scrollTo(0,0)
        )

    Spine.Route.setup()    

window.App = App