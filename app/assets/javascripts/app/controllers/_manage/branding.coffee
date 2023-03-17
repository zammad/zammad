class Branding extends App.ControllerTabs
  requiredPermission: 'admin.branding'
  header: __('Branding')
  constructor: ->
    super

    @title __('Branding'), true
    @tabs = [
      { name: __('Base'), 'target': 'base', controller: App.SettingsArea, params: { area: 'System::Branding' } }
    ]
    @render()

App.Config.set('SettingBranding', { prio: 1200, parent: '#settings', name: __('Branding'), target: '#settings/branding', controller: Branding, permission: ['admin.branding'] }, 'NavBarAdmin')
