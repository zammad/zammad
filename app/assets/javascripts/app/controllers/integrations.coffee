class IndexRouter extends App.ControllerNavSidbar
  authenticateRequired: true
  configKey: 'NavBarIntegration'

App.Config.set('integration', IndexRouter, 'Routes')
App.Config.set('integration/:target', IndexRouter, 'Routes')

App.Config.set('Integration', { prio: 1000, name: 'Integration', target: '#integration', role: ['Admin'] }, 'NavBarIntegration')
