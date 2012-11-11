$ = jQuery.sub()

class Index extends App.Controller
  className: 'container'

  events:
    'submit form': 'submit',
    'click .submit': 'submit',
    'click .retry': 'rerender',

  constructor: ->
    super

    # set title
    @title 'Reset Password'
    @navupdate '#reset_password'

    @render()

  render: ->
   configure_attributes = [
      { name: 'username', display: 'Enter your username or email address:', tag: 'input', type: 'text', limit: 100, null: false, class: 'input span4',  },
    ]

    @html App.view('reset_password')()

    new App.ControllerForm(
      el: @el.find('#form-password'),
      model: { configure_attributes: configure_attributes },
      autofocus: true,
    )

  rerender: (e) ->
    e.preventDefault()
    @render()

  submit: (e) ->
    e.preventDefault()
    params = @formParam(e.target)

    # get data
    App.Com.ajax(
      id:   'password_reset',
      type: 'POST',
      url:  '/api/users/password_reset',
      data: JSON.stringify(params),
      processData: true,
      success: @success,
      error: @error,
    )
  
  success: (data, status, xhr) =>
    @html App.view('generic/hero_message')(
      head:    'We\'ve sent password reset instructions to your email address',
      message: 'If you don\'t receive instructions within a minute or two, check your email\'s spam and junk filters, or try <a href="#" class="retry">resending your request</a>.'
    );

  error: (data, status, xhr) =>
    @html App.view('generic/hero_message')(
      head:    'Problem',
      message: 'Username or email address invalid, please go back and try <a href="#" class="retry">again</a>.'
    );

App.Config.set( 'reset_password', Index, 'Routes' )

class Verify extends App.Controller
  className: 'container'
  
  events:
    'submit form': 'submit',
    'click .submit': 'submit',

  constructor: ->
    super
    
    # set title
    @title 'Reset Password'
    @navupdate '#reset_password_verify'

    # get data
    params = {}
    params['token'] = @token
    App.Com.ajax(
      id:   'passwort_reset_verify',
      type: 'POST',
      url:  '/api/users/password_reset_verify',
      data: JSON.stringify(params),
      processData: true,
      success: @render_success
      error:   @render_failed
    )

  render_success: ->
   configure_attributes = [
      { name: 'password', display: 'Password', tag: 'input', type: 'password', limit: 100, null: false, class: 'input span4',  },
    ]

    @html App.view('reset_password_change')()

    new App.ControllerForm(
      el: @el.find('#form-password-change'),
      model: { configure_attributes: configure_attributes },
      autofocus: true,
    )

  render_failed: ->
    @html App.view('generic/hero_message')(
      head:    'Failed!',
      message: 'Token is not valid!'
    );

  submit: (e) ->
    e.preventDefault()
    params = @formParam(e.target)
    params['token'] = @token

    # get data
    App.Com.ajax(
      id:   'password_reset_verify',
      type: 'POST',
      url:  '/api/users/password_reset_verify',
      data: JSON.stringify(params),
      processData: true,
      success: @render_changed_success
      error:   @render_changed_failed
    )

  render_changed_success: (data, status, xhr) =>
    @html App.view('generic/hero_message')(
      head:    'Woo hoo! Your password has been changed!',
      message: 'Please try to login!',
    );

  render_changed_failed: ->
    @html App.view('generic/hero_message')(
      head:    'Failed!',
      message: 'Ask your admin!',
    );

App.Config.set( 'reset_password_verify/:token', Verify, 'Routes' )
