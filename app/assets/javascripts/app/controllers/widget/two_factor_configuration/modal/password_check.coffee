class App.TwoFactorConfigurationModalPasswordCheck extends App.TwoFactorConfigurationModal
  buttonSubmit: __('Next')
  buttonClass: 'btn--primary'
  head: __('Password')

  content: ->
    configure_attributes = [
      { name: 'password', display: __('Password'), tag: 'input', type: 'password', limit: 100, null: false, class: 'input', single: true }
    ]

    @form = new App.ControllerForm(
      model:     { configure_attributes: configure_attributes }
      autofocus: true
    )

    @form.el

  onSubmit: (e) ->
    params = @formParam(e.target)

    errors = @form.validate(params)
    if !_.isEmpty(errors)
      @formValidate(form: e.target, errors: errors)
      return false

    @formDisable(e)

    @ajax
      id: 'password_check'
      type: 'POST'
      url: "#{@apiPath}/users/password_check"
      data: JSON.stringify(params)
      processData: true
      success: (data, status, xhr) =>
        if data?.success
          @close()

          # Pass the modal options to the next modal instance.
          @next(
            container: @container
            successCallback: @successCallback
          )

          # We are not calling `super`, since we do not want to call success callback yet.

          return

        @formValidate( form: e.target, errors:
          password: __('Current password is wrong!')
        )

        @formEnable(e)
