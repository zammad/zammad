class Index extends App.ControllerNavSidbar
  authenticateRequired: true
  configKey: 'NavBarProfile'

App.Config.set('profile', Index, 'Routes')
App.Config.set('profile/:target', Index, 'Routes')

App.Config.set('Profile', { prio: 1000, name: 'Profile', target: '#profile' }, 'NavBarProfile')
App.Config.set('Profile', { prio: 1700, parent: '#current_user', name: 'Profile', target: '#profile', translate: true }, 'NavBarRight')
