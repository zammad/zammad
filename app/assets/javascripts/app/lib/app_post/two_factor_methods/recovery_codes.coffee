App.Config.set('RecoveryCodes', {
  key:         'recovery_codes'
  identifier:  'RecoveryCodes'
  label:       __('Recovery Codes')
  description: __('Use one of your safely stored recovery codes.')
  helpMessage: __('Enter one of your unused recovery codes.')
  icon:        'mobile-code'
  order:       2000
}, 'TwoFactorMethods')
