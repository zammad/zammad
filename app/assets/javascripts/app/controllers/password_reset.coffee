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
    @title __('Reset Password')
    @navupdate '#password_reset'

    @publicLinksSubscribeId = App.PublicLink.subscribe(=>
      @render()
    )

    @render()

  release: =>
    if @publicLinksSubscribeId
      App.PublicLink.unsubscribe(@publicLinksSubscribeId)

  render: (params = {}) ->
    configure_attributes = [
      { name: 'username', display: __('Enter your username or email address'), tag: 'input', type: 'text', limit: 100, null: false, class: 'input span4' }
    ]

    params['public_links'] = App.PublicLink.search(
      filter:
        screen: ['password_reset']
      sortBy: 'prio'
    )

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
      error:       @error
    )

  success: (data) =>
    public_links = App.PublicLink.search(
      filter:
        screen: ['password_reset']
      sortBy: 'prio'
    )

    @html(App.view('password/reset_sent')(
      public_links: public_links
    ))

  error: (data, statusText, error) =>
    @formEnable(@form.el)

    details = data.responseJSON || {}
    @notify(
      type: 'error'
      msg:  details.error_human || details.error || __('Loading failed.')
    )

App.Config.set('password_reset', PasswordReset, 'Routes')
