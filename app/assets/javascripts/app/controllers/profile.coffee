class App.Profile extends App.ControllerNavSidbar
  authenticateRequired: true
  configKey: 'NavBarProfile'

class ProfileRouter extends App.ControllerPermanent
  requiredPermission: ['user_preferences.*']

  constructor: (params) ->
    super

    # check authentication
    @authenticateCheckRedirect()

    App.TaskManager.execute(
      key:        'Profile'
      controller: 'Profile'
      params:     params
      show:       true
      persistent: true
    )

App.Config.set('profile', ProfileRouter, 'Routes')
App.Config.set('profile/:target', ProfileRouter, 'Routes')

App.Config.set('Profile', { prio: 1000, name: 'Profile', target: '#profile' }, 'NavBarProfile')
App.Config.set('Profile', { prio: 1700, parent: '#current_user', name: 'Profile', target: '#profile', permission: ['user_preferences.*'], translate: true }, 'NavBarRight')
