class SwitchBackToUser extends App.Controller
  className: 'switchBackToUser'

  constructor: ->
    super

    # start widget
    @controllerBind('app:ready', =>
      @render()
    )

    # e.g. if language has changed
    @controllerBind('ui:rerender', =>
      @render()
    )

    App.Event.bind('auth:login', (user) ->
      App.Config.set('switch_back_to_possible', false)
    )

  render: (user) ->

    # if no switch to user is active
    if !App.Config.get('switch_back_to_possible') || !App.Session.get()
      @element().remove()
      return

    # show switch back widget
    @html App.view('widget/switch_back_to_user')()
    @element().on('click', '.js-close', (e) =>
      @switchBack(e)
    )

  switchBack: (e) =>
    e.preventDefault()
    @disconnectClient()
    $('#app').hide().attr('style', 'display: none!important')
    @delay(
      =>
        App.Auth._logout(false)
        @ajax(
          id:          'user_switch_back'
          type:        'GET'
          url:         "#{@apiPath}/sessions/switch_back"
          success:     (data, status, xhr) =>
            location = "#{window.location.protocol}//#{window.location.host}#{data.location}"
            @windowReload(undefined, location)
        )
      800
    )

  element: =>
    $("##{@key}")

  html: (raw) =>

    # check if parent exists
    if !$("##{@key}").get(0)
      $('#app').before("<div id=\"#{@key}\" class=\"#{@className}\"></div>")
    $("##{@key}").html raw

App.Config.set('switch_back_to_user', SwitchBackToUser, 'Plugins')
