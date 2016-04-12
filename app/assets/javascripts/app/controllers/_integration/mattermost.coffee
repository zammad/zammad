class Mattermost extends App.ControllerTabs
  header: 'Mattermost'
  constructor: ->
    super
    return if !@authenticate(false, 'Admin')
    @title 'Mattermost', true
    @tabs = [
      { name: 'Base', 'target': 'base', controller: App.SettingsArea, params: { area: 'Integration::Mattermost' } }
    ]
    @render()

App.Config.set('IntegrationMattermost', { prio: 1000, parent: '#integration', name: 'Mattermost', target: '#integration/mattermost', controller: Mattermost, role: ['Admin'] }, 'NavBarIntegration')
