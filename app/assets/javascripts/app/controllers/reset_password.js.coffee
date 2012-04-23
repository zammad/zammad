$ = jQuery.sub()

class Index extends App.Controller
  className: 'container'
  
  events:
    'submit form': 'submit',
    'click .submit': 'submit',
    'click .cancel': 'cancel',

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

  cancel: ->
    @navigate 'login'

  submit: (e) ->
    @log 'submit'
    e.preventDefault()
    params = @formParam(e.target)

    # get data
    ajax = new App.Ajax
    ajax.ajax(
      type: 'POST',
      url:  '/users/password_reset',
      data: JSON.stringify(params),
      processData: true,
      success: @success
    )
  
  success: (data, status, xhr) =>

    @html App.view('reset_password_sent')()

  error: (xhr, statusText, error) =>
    
    # add notify
    Spine.trigger 'notify:removeall'
    Spine.trigger 'notify', {
      type: 'warning',
      msg: 'Wrong Username and Password combination.', 
    }
    
    # rerender login page
    @render(
      msg: 'Wrong Username and Password combination.', 
      username: @username
    )

Config.Routes['reset_password'] = Index
