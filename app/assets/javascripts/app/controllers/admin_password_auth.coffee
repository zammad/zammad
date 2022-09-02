class AdminPasswordAuth extends App.ControllerFullPage
  events:
    'submit form':   'submit'
    'click .submit': 'submit'
    'click .retry':  'retry'
  forceRender: true
  className: 'admin_password_auth'

  constructor: ->
    super

    # go back if password login is enabled
    if @Config.get('user_show_password_login')
      @navigate '#'
      return

    # if we are logged in, no admin password auth is wanted, redirect to app
    if @authenticateCheck()
      @navigate '#'
      return

    # set title
    @title __('Admin Password Login')
    @navupdate '#admin_password_auth'

    @render()

  render: (params) ->
    configure_attributes = [
      { name: 'username', display: __('Enter your username or email address'), tag: 'input', type: 'text', limit: 100, null: false, class: 'input span4' }
    ]

    @replaceWith(App.view('admin_password_auth/request')(params))

    @form = new App.ControllerForm(
      el:        @el.find('.js-adminPassword')
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
      id:          'admin_password_auth'
      type:        'POST'
      url:         "#{@apiPath}/users/admin_password_auth"
      data:        JSON.stringify(params)
      processData: true
      success:     @success
    )

  success: (data) =>
    @html(App.view('admin_password_auth/request_sent')())

App.Config.set('admin_password_auth', AdminPasswordAuth, 'Routes')
