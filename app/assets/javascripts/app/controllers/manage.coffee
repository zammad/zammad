class App.Manage extends App.ControllerNavSidbar
  authenticateRequired: true
  configKey: 'NavBarAdmin'

class ManageRouter extends App.ControllerPermanent
  @requiredPermission: ['admin.*']

  constructor: (params) ->
    super

    # check authentication
    @authenticateCheckRedirect()

    if params.search_query
      params.search_query = decodeURIComponent(params.search_query)

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
App.Config.set('manage/:target/:page/:search_query', ManageRouter, 'Routes')
App.Config.set('settings/:target', ManageRouter, 'Routes')
App.Config.set('channels/:target', ManageRouter, 'Routes')
App.Config.set('channels/:target/error/:error_code', ManageRouter, 'Routes')
App.Config.set('channels/:target/error/:error_code/channel/:channel_id', ManageRouter, 'Routes')
App.Config.set('channels/:target/error/:error_code/param/:param', ManageRouter, 'Routes')
App.Config.set('channels/:target/:channel_id', ManageRouter, 'Routes')
App.Config.set('ai/:target', ManageRouter, 'Routes')
App.Config.set('ai/:target/:page/:search_query', ManageRouter, 'Routes')
App.Config.set('system/:target', ManageRouter, 'Routes')
App.Config.set('system/:target/:integration', ManageRouter, 'Routes')
App.Config.set('system/:target/:integration/error/:error_code', ManageRouter, 'Routes')
App.Config.set('system/:target/:integration/success/:success_code', ManageRouter, 'Routes')

App.Config.set('Manage', { prio: 1000, name: __('Manage'), target: '#manage', permission: ['admin.*'] }, 'NavBarAdmin')
App.Config.set('Channels', { prio: 2500, name: __('Channels'), target: '#channels', permission: ['admin.*'] }, 'NavBarAdmin')
App.Config.set('Settings', { prio: 7000, name: __('Settings'), target: '#settings', permission: ['admin.*'] }, 'NavBarAdmin')
App.Config.set('AI', { prio: 7500, name: __('AI'), target: '#ai', permission: ['admin.*'] }, 'NavBarAdmin')
App.Config.set('System', { prio: 8000, name: __('System'), target: '#system', permission: ['admin.*'] }, 'NavBarAdmin')
