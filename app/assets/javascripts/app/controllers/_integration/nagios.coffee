class Nagios extends App.ControllerTabs
  header: 'Nagios'
  constructor: ->
    super
    return if !@authenticate(false, 'Admin')
    @title 'Nagios', true
    @tabs = [
      { name: 'Base', 'target': 'base', controller: App.SettingsArea, params: { area: 'Integration::Nagios' } }
    ]
    @render()

App.Config.set('IntegrationNagios', { prio: 1200, parent: '#integration', name: 'Nagios', target: '#integration/nagios', controller: Nagios, role: ['Admin'] }, 'NavBarIntegration')
