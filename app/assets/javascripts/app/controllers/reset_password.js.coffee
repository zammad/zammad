class Index extends App.ControllerContent
  className: 'container'

  events:
    'submit form':   'submit'
    'click .submit': 'submit'
    'click .retry':  'rerender'

  constructor: ->
    super

    # go back if feature is not enabled
    if !@Config.get('user_lost_password')
      @navigate '#'
      return

    # set title
    @title 'Reset Password'
    @navupdate '#reset_password'

    @render()

  render: (params) ->
   configure_attributes = [
      { name: 'username', display: 'Enter your username or email address', tag: 'input', type: 'text', limit: 100, null: false, class: 'input span4',  },
    ]

    @html App.view('password/reset')(params)

    @form = new App.ControllerForm(
      el:        @el.find('#form-password-item')
      model:     { configure_attributes: configure_attributes }
      autofocus: true
    )

  rerender: (e) ->
    e.preventDefault()
    @el.find('#form-password').show()

  submit: (e) ->
    e.preventDefault()
    params = @formParam(e.target)
    @formDisable(e)

    # get data
    @ajax(
      id:   'password_reset'
      type: 'POST'
      url:  @apiPath + '/users/password_reset'
      data: JSON.stringify(params)
      processData: true
      success: @success
      error:   @error
    )

  success: (data, status, xhr) =>
    @render( sent: true )
    @el.find('#form-password').hide()

  error: (data, status, xhr) =>
    @notify(
      type: 'error'
      msg:  App.i18n.translateContent( 'Username or email address invalid, please try again.' )
    )
    @formEnable( @el.find('#form-password') )

App.Config.set( 'reset_password', Index, 'Routes' )

class Verify extends App.ControllerContent
  className: 'container'

  events:
    'submit form': 'submit'
    'click .submit': 'submit'

  constructor: ->
    super

    # set title
    @title 'Reset Password'
    @navupdate '#reset_password_verify'

    # get data
    params = {}
    params['token'] = @token
    @ajax(
      id:   'password_reset_verify'
      type: 'POST'
      url:  @apiPath + '/users/password_reset_verify'
      data: JSON.stringify(params)
      processData: true
      success: @render_success
      error:   @render_failed
    )

  render_success: =>
   configure_attributes = [
      { name: 'password', display: 'Password', tag: 'input', type: 'password', limit: 100, null: false, class: 'input span4',  },
    ]

    @html App.view('password/reset_change')()

    new App.ControllerForm(
      el:        @el.find('#form-password-change')
      model:     { configure_attributes: configure_attributes }
      autofocus: true
    )

  render_failed: =>
    @html App.view('generic/hero_message')(
      head:    'Failed!'
      message: 'Token is not valid!'
    )

  submit: (e) ->
    e.preventDefault()
    params = @formParam(e.target)
    params['token'] = @token
    @password = params['password']

    # get data
    @ajax(
      id:   'password_reset_verify'
      type: 'POST'
      url:  @apiPath + '/users/password_reset_verify'
      data: JSON.stringify(params)
      processData: true
      success: @render_changed_success
      error:   @render_changed_failed
    )

  render_changed_success: (data, status, xhr) =>
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

        # add notify
        @notify
          type:      'error'
          msg:       'Something went wrong. Please contact your administrator.'
          removeAll: true
    )

  render_changed_failed: =>
    @html App.view('generic/hero_message')(
      head:    'Failed!'
      message: 'Ask your admin!'
    )

App.Config.set( 'password_reset_verify/:token', Verify, 'Routes' )
