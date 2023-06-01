class App.TwoFactorLoginMethod extends App.Controller
  initiate:        false
  inputFieldLabel: __('Security Code')

  render: (params) =>
    form:   @renderForm(params)
    footer: @renderFooter(params)

  renderForm: (params = {}) =>
    App.view('widget/two_factor_login/security_code')(
      errorMessage:           params.errorMessage or @errorMessage
      formPayload:            @loginContext.formPayload
      inputFieldLabel:        @inputFieldLabel
      twoFactorMethodDetails: @method
    )

  renderFooter: (params) =>
    App.view('widget/two_factor_login/help_text')(
      twoFactorAvailableAnotherMethod: @loginContext.twoFactorAvailableAnotherMethod
    )

  postRender: =>
    @loginContext.el.find('#security_code').focus()

    # scroll to top
    @scrollTo()

    @fetchInitiateConfiguration() if @initiate and !@errorMessage

  fetchInitiateConfiguration: =>
    @ajax(
      id:          'two_factor_initiate_authentication'
      type:        'POST'
      data:        JSON.stringify(@loginContext.formPayload)
      processData: true
      url:         "#{@apiPath}/auth/two_factor_initiate_authentication/#{@method.key}"
      success:     @initiateCallback
    )

  initiateCallback: (data, xhr, status) ->
    throw 'You need to implement initiateCallback(data, xhr, status) method'
