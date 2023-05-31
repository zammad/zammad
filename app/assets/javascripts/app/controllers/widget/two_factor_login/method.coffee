class App.TwoFactorLoginMethod extends App.Controller
  preVerify: false
  inputFieldLabel:     __('Security Code')

  render: (params) =>
    form:   @renderForm(params)
    footer: @renderFooter(params)

  renderForm: (params) =>
    App.view('widget/two_factor_login/security_code')(
      errorMessage:           params.errorMessage
      formPayload:            @loginContext.formPayload
      twoFactorMethodDetails: @method
      inputFieldLabel:        @inputFieldLabel
    )

  renderFooter: (params) =>
    App.view('widget/two_factor_login/help_text')(
      twoFactorAvailableAnotherMethod: @loginContext.twoFactorAvailableAnotherMethod
    )

  postRender: =>
    @loginContext.el.find('#security_code').focus()

    # scroll to top
    @scrollTo()

    @fetchPreVerifyConfiguration() if @preVerify and !@errorMessage

  fetchPreVerifyConfiguration: =>
    @ajax(
      id:          'two_factor_pre_verify_configuration'
      type:        'POST'
      data:        JSON.stringify(@loginContext.formPayload)
      processData: true
      url:         "#{@apiPath}/users/two_factor_pre_verify_configuration/#{@method.key}"
      success:     @preVerifyCallback
    )

  preVerifyCallback: (data, xhr, status) ->
    throw 'You need to implement preVerifyCallback(data, xhr, status) method'
