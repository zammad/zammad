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
      id:      'two_factor_enabled_authentication_methods'
      type:    'GET'
      url:     "#{@apiPath}/users/#{App.User.current().id}/two_factor_enabled_authentication_methods"
      success: @renderAvailableMethods
      error: (xhr, status, error) =>
        return if xhr.status != 403

        @message = __("Two-factor authentication is required, but you don't have sufficient permissions to set it up. Please contact your administrator.")
        @update()
      )

  renderAvailableMethods: (data, status, xhr) =>
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
      successCallback: =>
        @fetchAfterAuth()
        App.User.current().trigger('two_factor_changed')
    )
