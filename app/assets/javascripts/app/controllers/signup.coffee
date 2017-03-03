class Index extends App.ControllerContent
  events:
    'submit form': 'submit'
    'click .submit': 'submit'
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
        App.Auth.login(
          data:
            username: @params.login
            password: @params.password
          success: @success
          error: @error
        )
      fail: (settings, details) =>
        @formEnable(e)
        @form.showAlert(details.error_human || details.error || 'Unable to update object!')
    )

  success: (data, status, xhr) =>

    # login check
    App.Auth.loginCheck()

    # add notify
    @notify
      type:      'success'
      msg:       App.i18n.translateContent('Thanks for joining. Email sent to "%s". Please verify your email address.', @params.email)
      removeAll: true

    # redirect to #
    @navigate '#'

  error: (xhr, statusText, error) =>
    detailsRaw = xhr.responseText
    details = {}
    if !_.isEmpty(detailsRaw)
      details = JSON.parse(detailsRaw)

    @notify
      type:      'error'
      msg:       App.i18n.translateContent(details.error || 'Wrong Username or Password combination.')
      removeAll: true

App.Config.set('signup', Index, 'Routes')
