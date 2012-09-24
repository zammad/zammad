
class App.Run extends App.Controller
  constructor: ->
    super
    @log 'RUN app'
    @el = $('#app')

    # init collections
    App.Collection.init()

    # create web socket connection
    App.WebSocket.connect()

    # init of i18n
    new App.i18n

    # start navigation controller
    new App.Navigation( el: @el.find('#navigation') )

    # check if session already exists/try to get session data from server
    App.Auth.loginCheck()

    # start notify controller
    new App.Notify( el: @el.find('#notify') )
    
    # start content
    new App.Content( el: @el.find('#content') )

    # bind to fill selected text into
    $(@el).bind('mouseup', =>
      window.Session['UISelection'] = @getSelected() + ''
    )

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

          # remember current controller
          Config['ActiveController'] = route

          # send current controller
          params_only = {}
          for i of params
            if typeof params[i] isnt 'object'
              params_only[i] = params[i]
          App.WebSocket.send(
            action:     'active_controller',
            controller: route,
            params:     params_only,
          )

          # unbind in controller area
          @el.unbind()
          @el.undelegate()

          # remove waypoints
          $('footer').waypoint('remove')

          params.el = @el
          new callback( params )

          # scroll to top
#          window.scrollTo(0,0)
        )

    Spine.Route.setup()