class PasswordReset extends App.ControllerFullPage
  events:
    'submit form':   'submit'
    'click .submit': 'submit'
    'click .retry':  'retry'
  forceRender: true
  className: 'reset_password'

  constructor: ->
    super

    # go back if feature is not enabled
    if !@Config.get('user_lost_password')
      @navigate '#'
      return

    # if we are logged in, no password reset is wanted, redirect to app
    if @authenticateCheck()
      @navigate '#'
      return

    # set title
    @title 'Reset Password'
    @navupdate '#password_reset'

    @render()

  render: (params) ->
    configure_attributes = [
      { name: 'username', display: 'Enter your username or email address', tag: 'input', type: 'text', limit: 100, null: false, class: 'input span4' }
    ]

    @replaceWith(App.view('password/reset')(params))

    @form = new App.ControllerForm(
      el:        @el.find('.js-password')
      model:     { configure_attributes: configure_attributes }
      autofocus: true
    )

  retry: (e) ->
    e.preventDefault()
    @render()

  submit: (e) ->
    e.preventDefault()
    params = @formParam(e.target)
    @formDisable(e)

    # get data
    @ajax(
      id:          'password_reset'
      type:        'POST'
      url:         "#{@apiPath}/users/password_reset"
      data:        JSON.stringify(params)
      processData: true
      success:     @success
    )

  success: (data) =>

    # if in developer mode, redirect to set new password
    if data.token && @Config.get('developer_mode') is true
      redirect = =>
        @navigate "#password_reset_verify/#{data.token}"
      @delay(redirect, 2000)
    @html(App.view('password/reset_sent')())

App.Config.set('password_reset', PasswordReset, 'Routes')
