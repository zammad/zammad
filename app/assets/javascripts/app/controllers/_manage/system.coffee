class System extends App.ControllerTabs
  requiredPermission: 'admin.setting_system'
  header: 'System'
  constructor: ->
    super

    @title 'System', true
    @tabs = []
    if !App.Config.get('system_online_service')
      @tabs.push { name: 'Base',     'target': 'base',     controller: App.SettingsArea, params: { area: 'System::Base' } }
    @tabs.push { name: 'Services',   'target': 'services', controller: App.SettingsArea, params: { area: 'System::Services' } }
    if !App.Config.get('system_online_service')
      @tabs.push { name: 'Storage',  'target': 'storage',  controller: App.SettingsArea, params: { area: 'System::Storage' } }
    if !App.Config.get('system_online_service')
      @tabs.push { name: 'Network',  'target': 'network',  controller: App.SettingsArea, params: { area: 'System::Network' } }
    @tabs.push { name: 'Frontend',   'target': 'ui',       controller: App.SettingsArea, params: { area: 'System::UI' } }
    @render()

App.Config.set('SettingSystem', { prio: 1400, parent: '#settings', name: 'System', target: '#settings/system', controller: System, permission: ['admin.setting_system'] }, 'NavBarAdmin')
