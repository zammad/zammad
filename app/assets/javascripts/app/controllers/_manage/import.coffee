class Import extends App.ControllerTabs
  header: 'Import'
  constructor: ->
    super
    return if !@authenticate(false, 'Admin')
    @title 'Import', true
    @tabs = [
      { name: 'Base', 'target': 'base', controller: App.SettingsArea, params: { area: 'Import::Base' } }
      { name: 'OTRS', 'target': 'otrs', controller: App.SettingsArea, params: { area: 'Import::OTRS' } }
    ]
    @render()

App.Config.set('SettingImport', { prio: 1800, parent: '#settings', name: 'Import', target: '#settings/import', controller: Import, role: ['Admin'] }, 'NavBarAdmin')
