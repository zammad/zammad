class App.TwoFactorLoginMethodSecurityKeys extends App.TwoFactorLoginMethod
  initiate: true
  events:
    'click .js-retry': 'retry'

  renderForm: (params = {}) =>
    formElement = $(App.view('widget/two_factor_login/security_keys')(
      errorMessage:           params.errorMessage or @errorMessage
      formPayload:            @loginContext.formPayload
      twoFactorMethodDetails: @method
    ))

    formElement.find('.js-retry').on('click', @retry)

    formElement

  initiateCallback: (data) =>
    @config = data

    @verify()

  verify: =>
    if not window.isSecureContext
      @showError(__('The application is not running in a secure context.'))
      return

    webauthnJSON
      .get(publicKey: @config)
      .then((publicKeyCredential) =>
        params = _.extend({}, @loginContext.formPayload,
          two_factor_method: @method.key
          two_factor_payload:
            credential: publicKeyCredential
            challenge: @config.challenge
        )

        App.Auth.login(
          data:    params
          success: @loginContext.success
          error:   @loginContext.error
        )
      )
      .catch((e) =>
        App.Log.error('TwoFactorLoginMethodSecurityKeys', e)
        @showError()
      )

  showError: (message = __('Security key verification failed.')) =>
    @loginContext.el.find('.js-form').html @renderForm(
      errorMessage: message
    )

  retry: =>
    @loginContext.renderTwoFactor(
      twoFactorMethod: @method.key
    )
