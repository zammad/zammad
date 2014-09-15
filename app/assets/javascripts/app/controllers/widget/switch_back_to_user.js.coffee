class Widget extends App.Controller
  events:
    'click    .js-close':    'switchBack'

  constructor: ->
    super

    # start widget
    @bind 'app:ready', =>
      @render()

    # remove widget
    @bind 'auth:logout', =>
      App.Config.set('switch_back_to_possible', false)
      @render()

  render: (user) ->

    # if no switch to user is active
    if !App.Config.get('switch_back_to_possible') || _.isEmpty( App.Session.all() )
      @el.html('')
      $('#app').removeClass('switchBackToUserSpace')
      return

    # show switch back widget
    @html App.view('widget/switch_back_to_user')()
    $('#app').addClass('switchBackToUserSpace')

  switchBack: (e) =>
    e.preventDefault()
    @disconnectClient()
    $('#app').hide().attr('style', 'display: none!important')
    App.Auth._logout()
    window.location = App.Config.get('api_path') + '/sessions/switch_back'


App.Config.set( 'switch_back_to_user', Widget, 'Widgets' )
