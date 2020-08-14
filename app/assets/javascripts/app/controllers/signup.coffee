class Index extends App.ControllerContent
  events:
    'submit form': 'submit'
    'click .submit': 'submit'
    'click .js-submitResend': 'resend'
    'click .cancel': 'cancel'

  constructor: ->
    super

    # go back if feature is not enabled
    if !@Config.get('user_create_account')
      @navigate '#'
      return

    @navHide()

    # set title
    @title 'Sign up'
    @navupdate '#signup'

    @render()

  render: ->

    @html App.view('signup')()

    @form = new App.ControllerForm(
      el:        @el.find('form')
      model:     App.User
      screen:    'signup'
      autofocus: true
    )

  cancel: ->
    @navigate '#login'

  submit: (e) =>
    e.preventDefault()
    @formDisable(e)
    @params = @formParam(e.target)

    # if no login is given, use emails as fallback
    if !@params.login && @params.email
      @params.login = @params.email

    @params.signup = true
    @params.role_ids = []
    @log 'notice', 'updateAttributes', @params
    user = new App.User
    user.load(@params)

    errors = user.validate(
      screen: 'signup'
    )
    if errors
      @log 'error new', errors
      @formValidate(form: e.target, errors: errors)
      @formEnable(e)
      return false

    # save user
    user.save(
      done: (r) =>
        @html App.view('signup/verify')(
          email: @params.email
        )
      fail: (settings, details) =>
        @formEnable(e)
        if _.isArray(details.error)
          @form.showAlert( App.i18n.translateInline( details.error[0], details.error[1] ) )
        else
          @form.showAlert(details.error_human || details.error || 'Unable to update object!')
    )

  resend: (e) =>
    e.preventDefault()
    @formDisable(e)
    @resendParams = @formParam(e.target)

    @ajax(
      id:          'email_verify_send'
      type:        'POST'
      url:         @apiPath + '/users/email_verify_send'
      data:        JSON.stringify(email: @resendParams.email)
      processData: true
      success: (data, status, xhr) =>
        @formEnable(e)

        # add notify
        @notify
          type:      'success'
          msg:       App.i18n.translateContent('Email sent to "%s". Please verify your email address.', @params.email)
          removeAll: true

        if data.token && @Config.get('developer_mode') is true
          @navigate "#email_verify/#{data.token}"
      error: @error
    )

  error: (xhr, statusText, error) =>
    detailsRaw = xhr.responseText
    details = {}
    if !_.isEmpty(detailsRaw)
      details = JSON.parse(detailsRaw)

    @notify
      type:      'error'
      msg:       App.i18n.translateContent(details.error || 'Could not process your request')
      removeAll: true

App.Config.set('signup', Index, 'Routes')
