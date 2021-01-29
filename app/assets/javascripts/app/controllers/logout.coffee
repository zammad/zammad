class Logout
  constructor: ->
    App.Auth.logout()

App.Config.set('logout', Logout, 'Routes')
App.Config.set('Logout', { prio: 1800, parent: '#current_user', name: 'Sign out', translate: true, target: '#logout', divider: true, iconClass: 'signout' }, 'NavBarRight')
