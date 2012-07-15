#s#= require json2
#= require ./lib/jquery-1.7.2.min.js
#= require ./lib/ui/jquery-ui-1.8.18.custom.min.js

#= require ./lib/spine/spine.js
#= require ./lib/spine/ajax.js
#= require ./lib/spine/route.js

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
#= require ./lib/ajax.js.coffee
#= require ./lib/auth.js.coffee
#= require ./lib/i18n.js.coffee
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
    App.Auth.loginCheck()

    # start notify controller
    new App.Notify( el: @el.find('#notify') );
    
    # start content
    new App.Content( el: @el.find('#content') );

    # bind to fill selected text into
    $(@el).bind('mouseup', =>
      window.Session['UISelection'] = @getSelected() + ''
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