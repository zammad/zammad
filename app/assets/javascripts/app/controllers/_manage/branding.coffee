class Branding extends App.ControllerTabs
  header: 'Branding'
  constructor: ->
    super
    return if !@authenticate(false, 'Admin')
    @title 'Branding', true
    @tabs = [
      { name: 'Base', 'target': 'base', controller: App.SettingsArea, params: { area: 'System::Branding' } }
    ]
    @render()

App.Config.set('SettingBranding', { prio: 1200, parent: '#settings', name: 'Branding', target: '#settings/branding', controller: Branding, role: ['Admin'] }, 'NavBarAdmin')
