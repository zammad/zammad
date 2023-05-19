class Security extends App.ControllerTabs
  @requiredPermission: 'admin.security'
  header: __('Security')
  constructor: ->
    super

    @title __('Security'), true
    @tabs = [
      { name: __('Base'),                      target: 'base',             controller: App.SettingsArea, params: { area: 'Security::Base' } }
      { name: __('Password'),                  target: 'password',         controller: App.SettingsArea, params: { area: 'Security::Password' } }
      { name: __('Two-factor Authentication'), target: 'two_factor_auth',  controller: App.SettingsArea, params: { area: 'Security::TwoFactorAuthentication', subtitle: __('Two-factor Authentication Methods') } }
      { name: __('Third-party Applications'),  target: 'third_party_auth', controller: App.SettingsArea, params: { area: 'Security::ThirdPartyAuthentication' } }
    ]
    @render()

App.Config.set('SettingSecurity', { prio: 1600, parent: '#settings', name: __('Security'), target: '#settings/security', controller: Security, permission: ['admin.security'] }, 'NavBarAdmin')
