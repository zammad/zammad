App.Config.set('AuthenticatorApp', {
  key:                  'authenticator_app'
  identifier:           'AuthenticatorApp'
  editable:             true
  label:                __('Authenticator App')
  description:          __('Get the security code from the authenticator app on your device.')
  helpMessage:          __('Enter the code from your two-factor authenticator app.')
  icon:                 'mobile-code'
  order:                2000
  authenticationMethod: true
  settingKey:           'two_factor_authentication_method_authenticator_app'
}, 'TwoFactorMethods')
