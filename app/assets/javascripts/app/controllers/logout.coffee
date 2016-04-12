class Index extends App.ControllerContent
  constructor: ->
    super
    @signout()

  signout: ->

    # remove remote session
    App.Auth.logout()

    # remove local session
    @Session.init()
    App.Event.trigger('ui:rerender')

    # redirect to login
    redirect = =>
      @navigate 'login'
    @delay redirect, 150

App.Config.set( 'logout', Index, 'Routes' )
App.Config.set( 'Logout', { prio: 1800, parent: '#current_user', name: 'Sign out', translate: true, target: '#logout', divider: true, iconClass: 'signout', role: [ 'Agent', 'Customer' ] }, 'NavBarRight' )
