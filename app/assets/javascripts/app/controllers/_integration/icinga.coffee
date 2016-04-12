class Icinga extends App.ControllerTabs
  header: 'Icinga'
  constructor: ->
    super
    return if !@authenticate(false, 'Admin')
    @title 'Icinga', true
    @tabs = [
      { name: 'Base', 'target': 'base', controller: App.SettingsArea, params: { area: 'Integration::Icinga' } }
    ]
    @render()

App.Config.set('IntegrationIcinga', { prio: 1100, parent: '#integration', name: 'Icinga', target: '#integration/icinga', controller: Icinga, role: ['Admin'] }, 'NavBarIntegration')
