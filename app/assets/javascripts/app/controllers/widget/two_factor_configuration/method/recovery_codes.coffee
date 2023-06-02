class App.TwoFactorConfigurationMethodRecoveryCodes extends App.TwoFactorConfigurationMethod
  passwordCheckHeadPrefix: __('Generate recovery codes')

  methodModalClass: ->
    App.TwoFactorConfigurationModalRecoveryCodes
