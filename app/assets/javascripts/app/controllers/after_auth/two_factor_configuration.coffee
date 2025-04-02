class App.AfterAuthTwoFactorConfiguration extends App.ControllerAfterAuthModal
  head: __('Set up two-factor authentication')
  buttonCancel: __('Cancel & Sign out')
  buttonSubmit: false

  events:
    'click .js-configuration-method': 'selectConfigurationMethod'

  constructor: (params) ->

    # Remove the fade transition if requested.
    if params.noFadeTransition
      params.className = 'modal'

    if not params.data?.token
      @invalidPasswordToken()
      return

    super(params)

  content: ->
    content = $(App.view('after_auth/two_factor_configuration')())

    @fetchAvailableMethods()

    content

  fetchAvailableMethods: ->
    # If user clicks cancel & sign out, modal may try to re-render during logout
    # Since current user is no longer avaialble, it would throw a javascript error
    return if !App.User.current()

    @ajax(
      id:          'two_factor_enabled_authentication_methods'
      type:        'POST'
      url:         "#{@apiPath}/users/two_factor/enabled_authentication_methods"
      data:        JSON.stringify(token: @data?.token)
      processData: true
      success:     @renderAvailableMethods
      error: (xhr, status, error) =>
        return if xhr.status != 403

        @message = __("Two-factor authentication is required, but you don't have sufficient permissions to set it up. Please contact your administrator.")
        @update()
      )

  renderAvailableMethods: (data, status, xhr) =>
    if data?.invalid_password_token
      @closeWithoutFade()
      @invalidPasswordToken(true)
      return

    methodButtons = $(App.view('after_auth/two_factor_configuration/method_buttons')(
      enabledMethods: @transformTwoFactorMethods(data)
    ))

    @$('.two-factor-auth-method-buttons').html(methodButtons)

  transformTwoFactorMethods: (data) ->
    return [] if _.isEmpty(data)

    iteratee = (memo, item) ->
      method = App.TwoFactorMethods.methodByKey(item.method)

      return memo if !method

      memo.push(_.extend(
        {},
        method,
        disabled: item.configured
      ))

      memo

    _.reduce(data, iteratee, [])

  closeWithoutFade: =>
    @el.removeClass('fade')
    @close()

  selectConfigurationMethod: (e) =>
    e.preventDefault()

    @closeWithoutFade()

    configurationMethod = $(e.currentTarget).data('method')

    return if _.isEmpty(configurationMethod)

    new App['TwoFactorConfigurationMethod' + configurationMethod](
      mode: 'after_auth'
      token: @data?.token
      successCallback: =>
        @fetchAfterAuth()
        App.User.current().trigger('two_factor_changed')
    )

  invalidPasswordToken: (notify = false) =>
    if notify
      @notify(
        type:      'error'
        msg:       __('Invalid password revalidation token, please confirm your password again.')
        removeAll: true
      )

    new App.TwoFactorConfigurationModalPasswordCheck(
      logoutOnCancel: @logoutOnCancel
      backdrop: @backdrop
      keyboard: @keyboard
      buttonClose: @buttonClose
      buttonCancel: @buttonCancel
      onCancel: @onCancel
      successCallback: (data) ->
        new App.AfterAuthTwoFactorConfiguration(
          data: data
          className: 'modal' # no automatic fade transitions
        )
    )
