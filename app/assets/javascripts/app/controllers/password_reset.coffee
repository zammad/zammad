class Index extends App.ControllerContent
  events:
    'submit form':   'submit'
    'click .submit': 'submit'
    'click .retry':  'retry'

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

    @navHide()

    # set title
    @title 'Reset Password'
    @navupdate '#password_reset'

    @render()

  render: (params) ->
    configure_attributes = [
      { name: 'username', display: 'Enter your username or email address', tag: 'input', type: 'text', limit: 100, null: false, class: 'input span4' }
    ]

    @html App.view('password/reset')(params)

    @form = new App.ControllerForm(
      el:        @el.find('.form-password-item')
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
    if data.message is 'ok'

      # if in developer mode, redirect to set new password
      if data.token && @Config.get('developer_mode') is true
        redirect = =>
          @navigate "#password_reset_verify/#{data.token}"
        @delay(redirect, 2000)
      @render(sent: true)

    else
      @$('[name=username]').val('')
      @notify(
        type: 'error'
        msg:  App.i18n.translateContent('Username or email address invalid, please try again.')
      )
      @formEnable( @el.find('.form-password') )

App.Config.set('password_reset', Index, 'Routes')

class Verify extends App.ControllerContent
  events:
    'submit form':   'submit'
    'click .submit': 'submit'

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

    @navHide()

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

      @html App.view('password/reset_change')()

      new App.ControllerForm(
        el:        @el.find('.form-password-change')
        model:     { configure_attributes: configure_attributes }
        autofocus: true
      )
    else
      @html App.view('password/reset_failed')(
        head:    'Reset Password failed!'
        message: 'Token is invalid!'
      )

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
      @notify
        type:      'error'
        msg:       'Can\'t update password, your new passwords do not match. Please try again!'
        removeAll: true
      return
    if !params['password']
      @formEnable(e)
      @notify
        type:      'error'
        msg:       'Please supply your new password!'
        removeAll: true
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
          @notify
            type:      'success'
            msg:       'Woo hoo! Your password has been changed!'
            removeAll: true

          # redirect to #
          @navigate '#'

        error: =>
          @formEnable( @$('form') )

          # add notify
          @notify
            type:      'error'
            msg:       'Something went wrong. Please contact your administrator.'
            removeAll: true
      )
    else
      if data.notice
        @notify
          type:      'error'
          msg:       App.i18n.translateContent( data.notice[0], data.notice[1] )
          removeAll: true
      else
        @notify
          type:      'error'
          msg:       'Unable to set password. Please contact your administrator.'
          removeAll: true
      @formEnable( @$('form') )

App.Config.set('password_reset_verify/:token', Verify, 'Routes')
