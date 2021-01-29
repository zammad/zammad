class PasswordResetVerify extends App.ControllerFullPage
  events:
    'submit form':   'submit'
    'click .submit': 'submit'
  forceRender: true
  className: 'reset_password'

  constructor: ->
    super

    # go back if feature is not enabled
    if !@Config.get('user_lost_password')
      @navigate '#'
      return

    # if we are logged in, no passwort reset is wanted, redirect to app
    if @authenticateCheck()
      @navigate '#'
      return

    # set title
    @title 'Reset Password'
    @navupdate '#password_reset_verify'

    # get data
    params =
      token: @token
    @ajax(
      id:          'password_reset_verify'
      type:        'POST'
      url:         "#{@apiPath}/users/password_reset_verify"
      data:        JSON.stringify(params)
      processData: true
      success:     @renderChange
    )

  renderChange: (data) =>
    if data.message is 'ok'
      configure_attributes = [
        { name: 'password', display: 'Password', tag: 'input', type: 'password', limit: 100, null: false, class: 'input' }
      ]

      @replaceWith(App.view('password/reset_change')())

      new App.ControllerForm(
        el:        @el.find('.js-password')
        model:     { configure_attributes: configure_attributes }
        autofocus: true
      )
    else
      @replaceWith(App.view('password/reset_failed')(
        head:    'Reset Password failed!'
        message: 'Token is invalid!'
      ))

  submit: (e) ->
    e.preventDefault()
    params          = @formParam(e.target)
    params['token'] = @token
    @password       = params['password']

    # disable form
    @formDisable(e)

    # validate
    if params['password_confirm'] isnt params['password']
      @formEnable(e)
      @$('[name=password]').val('')
      @$('[name=password_confirm]').val('')
      @notify(
        type:      'error'
        msg:       'Can\'t update password, your new passwords do not match. Please try again!'
        removeAll: true
      )
      return
    if !params['password']
      @formEnable(e)
      @notify(
        type:      'error'
        msg:       'Please supply your new password!'
        removeAll: true
      )
      return

    # get data
    @ajax(
      id:          'password_reset_verify'
      type:        'POST'
      url:         "#{@apiPath}/users/password_reset_verify"
      data:        JSON.stringify(params)
      processData: true
      success:     @renderChanged
    )

  renderChanged: (data, status, xhr) =>
    if data.message is 'ok'
      App.Auth.login(
        data:
          username: data.user_login
          password: @password
        success: =>

          # login check
          App.Auth.loginCheck()

          # add notify
          @notify(
            type:      'success'
            msg:       'Woo hoo! Your password has been changed!'
            removeAll: true
          )

          # redirect to #
          @navigate '#'

        error: =>
          @formEnable(@$('form'))

          # add notify
          @notify(
            type:      'error'
            msg:       'Something went wrong. Please contact your administrator.'
            removeAll: true
          )
      )
    else
      if data.notice
        @notify(
          type:      'error'
          msg:       App.i18n.translateContent(data.notice[0], data.notice[1])
          removeAll: true
        )
      else
        @notify(
          type:      'error'
          msg:       'Unable to set password. Please contact your administrator.'
          removeAll: true
        )
      @formEnable(@$('form'))

App.Config.set('password_reset_verify/:token', PasswordResetVerify, 'Routes')
