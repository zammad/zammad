App.Config.set('AuthenticatorApp', {
  key:         'authenticator_app'
  identifier:  'AuthenticatorApp'
  label:       __('Authenticator App')
  description: __('Get the security code from the authenticator app on your device.')
  helpMessage: __('Enter the code from your two-factor authenticator app.')
  icon:        'mobile-code'
  order:       2000
}, 'TwoFactorMethods')
