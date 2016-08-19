class Branding extends App.ControllerTabs
  requiredPermission: 'admin.branding'
  header: 'Branding'
  constructor: ->
    super

    @title 'Branding', true
    @tabs = [
      { name: 'Base', 'target': 'base', controller: App.SettingsArea, params: { area: 'System::Branding' } }
    ]
    @render()

App.Config.set('SettingBranding', { prio: 1200, parent: '#settings', name: 'Branding', target: '#settings/branding', controller: Branding, permission: ['admin.branding'] }, 'NavBarAdmin')
