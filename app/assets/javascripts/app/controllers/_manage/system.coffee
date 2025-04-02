class System extends App.ControllerTabs
  @requiredPermission: 'admin.system'
  header: __('System')
  constructor: ->
    super

    @title __('System'), true
    @tabs = []
    if !App.Config.get('system_online_service')
      @tabs.push { name: __('Base'),     'target': 'base',     controller: App.SettingsArea, params: { area: 'System::Base' } }
    @tabs.push { name: __('Services'),   'target': 'services', controller: App.SettingsArea, params: { area: 'System::Services' } }
    if !App.Config.get('system_online_service')
      @tabs.push { name: __('Storage'),  'target': 'storage',  controller: App.SettingsArea, params: { area: 'System::Storage' } }
    if !App.Config.get('system_online_service')
      @tabs.push { name: __('Network'),  'target': 'network',  controller: App.SettingsArea, params: { area: 'System::Network' } }
    @tabs.push { name: __('Frontend'),   'target': 'ui',       controller: App.SettingsArea, params: { area: 'System::UI' } }
    @render()

App.Config.set('SettingSystem', { prio: 1400, parent: '#settings', name: __('System'), target: '#settings/system', controller: System, permission: ['admin.system'] }, 'NavBarAdmin')
