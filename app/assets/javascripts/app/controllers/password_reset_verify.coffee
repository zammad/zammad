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
    @title __('Reset Password')
    @navupdate '#password_reset_verify'

    @publicLinksSubscribeId = App.PublicLink.subscribe(=>
      @verify_token()
    )

    @verify_token()

  release: =>
    if @publicLinksSubscribeId
      App.PublicLink.unsubscribe(@publicLinksSubscribeId)

  renderChange: (data) =>
    public_links = App.PublicLink.search(
      filter:
        screen: ['password_reset']
      sortBy: 'prio'
    )

    if data.message is 'ok'
      configure_attributes = [
        { name: 'password', display: __('Password'), tag: 'input', type: 'password', limit: 100, null: false, class: 'input' }
      ]

      @replaceWith(App.view('password/reset_change')(
        public_links: public_links
      ))

      new App.ControllerForm(
        el:        @el.find('.js-password')
        model:     { configure_attributes: configure_attributes }
        autofocus: true
      )
    else
      @replaceWith(App.view('password/reset_failed')(
        head:    __('Reset Password failed!')
        message: __('Token is invalid!')
        public_links: public_links
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
        msg:       __("Can't update password, your entered passwords do not match. Please try again.")
        removeAll: true
      )
      return
    if !params['password']
      @formEnable(e)
      @notify(
        type:      'error'
        msg:       __('Please provide your new password.')
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
      @notify(
        type:      'success'
        msg:       __('Woo hoo! Your password has been changed!')
        removeAll: true
      )

      App.Auth.login(
        data:
          username: data.user_login
          password: @password
        success: =>

          # redirect to #
          @navigate '#'

        error: =>
          # The user may have an active 2FA method on their account, which will prevent an automatic login (#4989).
          #   Instead, silently redirect to login screen and allow the user to login manually
          #   and complete their 2FA challenge.
          @navigate '#'
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
          msg:       __('The password could not be set. Please contact your administrator.')
          removeAll: true
        )
      @formEnable(@$('form'))

  verify_token: ->
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

App.Config.set('password_reset_verify/:token', PasswordResetVerify, 'Routes')
