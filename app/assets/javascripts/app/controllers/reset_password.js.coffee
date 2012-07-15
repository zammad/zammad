$ = jQuery.sub()

class Index extends App.Controller
  className: 'container'
  
  events:
    'submit form': 'submit',
    'click .submit': 'submit',

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

    @html App.view('reset_password')(
      form: @formGen( model: { configure_attributes: configure_attributes } ),
    )

  submit: (e) ->
    e.preventDefault()
    params = @formParam(e.target)

    # get data
    App.Com.ajax(
      id:   'password_reset',
      type: 'POST',
      url:  '/users/password_reset',
      data: JSON.stringify(params),
      processData: true,
      success: @success
    )
  
  success: (data, status, xhr) =>
    @html App.view('generic/hero_message')(
      head:    'We\'ve sent password reset instructions to your email address',
      message: 'If you don\'t receive instructions within a minute or two, check your email\'s spam and junk filters, or try <a href="#reset_password">resending your request</a>.'
    );

Config.Routes['reset_password'] = Index


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
      url:  '/users/password_reset_verify',
      data: JSON.stringify(params),
      processData: true,
      success: @render_success
      error:   @render_failed
    )

  render_success: ->
   configure_attributes = [
      { name: 'password', display: 'Password', tag: 'input', type: 'password', limit: 100, null: false, class: 'input span4',  },
    ]

    @html App.view('reset_password_change')(
      form: @formGen( model: { configure_attributes: configure_attributes } ),
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
      url:  '/users/password_reset_verify',
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

Config.Routes['reset_password_verify/:token'] = Verify
