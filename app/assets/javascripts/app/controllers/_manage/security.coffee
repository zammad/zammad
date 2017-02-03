class Security extends App.ControllerTabs
  requiredPermission: 'admin.security'
  header: 'Security'
  constructor: ->
    super

    @title 'Security', true
    @tabs = [
      { name: 'Base',                     'target': 'base',             controller: App.SettingsArea, params: { area: 'Security::Base' } }
      { name: 'Password',                 'target': 'password',         controller: App.SettingsArea, params: { area: 'Security::Password' } }
      #{ name: 'Authentication',           'target': 'auth',            controller: App.SettingsArea, params: { area: 'Security::Authentication' } }
      { name: 'Third-party Applications', 'target': 'third_party_auth', controller: App.SettingsArea, params: { area: 'Security::ThirdPartyAuthentication' } }
    ]
    @render()

App.Config.set('SettingSecurity', { prio: 1600, parent: '#settings', name: 'Security', target: '#settings/security', controller: Security, permission: ['admin.security'] }, 'NavBarAdmin')

