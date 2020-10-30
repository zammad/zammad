class App.Manage extends App.ControllerNavSidbar
  authenticateRequired: true
  configKey: 'NavBarAdmin'

class ManageRouter extends App.ControllerPermanent
  requiredPermission: ['admin.*']

  constructor: (params) ->
    super

    # check authentication
    @authenticateCheckRedirect()

    App.TaskManager.execute(
      key:        'Manage'
      controller: 'Manage'
      params:     params
      show:       true
      persistent: true
    )

App.Config.set('manage', ManageRouter, 'Routes')
App.Config.set('manage/:target', ManageRouter, 'Routes')
App.Config.set('manage/:target/:page', ManageRouter, 'Routes')
App.Config.set('settings/:target', ManageRouter, 'Routes')
App.Config.set('channels/:target', ManageRouter, 'Routes')
App.Config.set('channels/:target/:channel_id', ManageRouter, 'Routes')
App.Config.set('system/:target', ManageRouter, 'Routes')
App.Config.set('system/:target/:integration', ManageRouter, 'Routes')

App.Config.set('Manage', { prio: 1000, name: 'Manage', target: '#manage', permission: ['admin.*'] }, 'NavBarAdmin')
App.Config.set('Channels', { prio: 2500, name: 'Channels', target: '#channels', permission: ['admin.*'] }, 'NavBarAdmin')
App.Config.set('Settings', { prio: 7000, name: 'Settings', target: '#settings', permission: ['admin.*'] }, 'NavBarAdmin')
App.Config.set('System', { prio: 8000, name: 'System', target: '#system', permission: ['admin.*'] }, 'NavBarAdmin')
