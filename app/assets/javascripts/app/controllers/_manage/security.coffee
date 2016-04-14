class Security extends App.ControllerTabs
  header: 'Security'
  constructor: ->
    super
    return if !@authenticate(false, 'Admin')
    @title 'Security', true
    @tabs = [
      { name: 'Base',                     'target': 'base',             controller: App.SettingsArea, params: { area: 'Security::Base' } }
#       { name: 'Authentication',           'target': 'auth',             controller: App.SettingsArea, params: { area: 'Security::Authentication' } }
      { name: 'Password',                 'target': 'password',         controller: App.SettingsArea, params: { area: 'Security::Password' } }
      { name: 'Third-Party Applications', 'target': 'third_party_auth', controller: App.SettingsArea, params: { area: 'Security::ThirdPartyAuthentication' } }
    ]
    @render()

App.Config.set('SettingSecurity', { prio: 1600, parent: '#settings', name: 'Security', target: '#settings/security', controller: Security, role: ['Admin'] }, 'NavBarAdmin')
