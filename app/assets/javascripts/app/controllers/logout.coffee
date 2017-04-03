class Index extends App.ControllerContent
  constructor: ->
    super

    App.Auth.logout()

App.Config.set('logout', Index, 'Routes')
App.Config.set('Logout', { prio: 1800, parent: '#current_user', name: 'Sign out', translate: true, target: '#logout', divider: true, iconClass: 'signout' }, 'NavBarRight')
