class ProfilePassword extends App.ControllerSubContent
  @requiredPermission: ['user_preferences.password', 'user_preferences.two_factor_authentication']
  header: __('Password & Authentication')
  events:
    'submit form':                       'update'
    'click .js-generate-recovery-codes': 'twoFactorMethodGenerateRecoveryCodes'
    'click [data-type="setup"]':         'twoFactorMethodSetup'
    'click [data-type="edit"]':          'twoFactorMethodSetup'
    'click [data-type="remove"]':        'twoFactorMethodRemove'
    'click [data-type="default"]':       'twoFactorMethodDefault'

  constructor: ->
    super

    @controllerBind('config_update', (data) =>
      return if not /^two_factor_authentication_method_/.test(data.name)

      @preRender()
    )

    @preRender()

  preRender: =>
    if !@allowsTwoFactor()
      @render()
      return

    @load()

    @listenTo App.User.current(), 'two_factor_changed', =>
      @load()

  load: =>
    @startLoading()

    @ajax(
      id:   'profile_two_factor_personal_configuration'
      type: 'GET'
      url:  @apiPath + '/users/two_factor/personal_configuration'
      processData: true
      success: (data, status, xhr) =>
        @stopLoading()

        @render(data)
      error: (xhr) =>
        @stopLoading()
    )

  allowsChangePassword: ->
    return false if !@permissionCheck('user_preferences.password')

    App.Config.get('user_show_password_login') || @permissionCheck('admin.*')

  allowsTwoFactor: ->
    return false if !@permissionCheck('user_preferences.two_factor_authentication')

    _.some(
      App.Config.all(),
      (state, setting) -> /^two_factor_authentication_method_/.test(setting) and state
    )

  render: (data = {}) =>

    # item
    html = $( App.view('profile/password')(
      allowsChangePassword:   @allowsChangePassword(),
      allowsTwoFactor:        @allowsTwoFactor(),
      hasConfiguredTwoFactor: _.any(data.enabled_authentication_methods, (elem) -> elem.configured)
      twoFactorMethods:       @transformTwoFactorMethods(data.enabled_authentication_methods)
      recoveryCodesEnabled:   App.Config.get('two_factor_authentication_recovery_codes')
      recoveryCodesExist:     data.recovery_codes_exist
    ) )

    configure_attributes = [
      { name: 'password_old', display: __('Current password'), tag: 'input', type: 'password', limit: 100, null: false, class: 'input', single: true  },
      { name: 'password_new', display: __('New password'),     tag: 'input', type: 'password', limit: 100, null: false, class: 'input',  },
    ]

    @form = new App.ControllerForm(
      el:        html.find('.password_item')
      model:     { configure_attributes: configure_attributes }
      autofocus: false
    )
    @html html

  update: (e) =>
    e.preventDefault()
    params = @formParam(e.target)
    @formDisable(e)

    # validate
    if params['password_new_confirm'] isnt params['password_new']
      @formEnable(e)
      @$('[name=password_new]').val('')
      @$('[name=password_new_confirm]').val('')
      @notify
        type:      'error'
        msg:       __("Can't update password, your entered passwords do not match. Please try again.")
        removeAll: true
      return
    if !params['password_new']
      @formEnable(e)
      @notify
        type:      'error'
        msg:       __('Please provide your new password.')
        removeAll: true
      return

    # get data
    @ajax(
      id:          'password_reset'
      type:        'POST'
      url:         @apiPath + '/users/password_change'
      data:        JSON.stringify(params)
      processData: true
      success:     @success
      error:       @error
    )

  success: =>
    @render()

    @notify(
      type: 'success'
      msg:  __('Password changed successfully!')
    )

  error: (xhr, status, error) =>
    return if xhr.status != 422

    data    = xhr.responseJSON
    message = if data.notice
                App.i18n.translateContent( data.notice[0], data.notice[1] )
              else
                __('The password could not be set. Please contact your administrator.')

    @notify
      type:      'error'
      msg:       message
      removeAll: true

    @formEnable( @$('form') )

  transformTwoFactorMethods: (data) ->
    return [] if _.isEmpty(data)

    for elem in data
      elem.details = App.TwoFactorMethods.methodByKey(elem.method) || {}

      if elem.configured
        elem.active_icon_class = 'checkmark'
        elem.active_icon_parent_class = 'is-done'
      else
        elem.active_icon_class = 'small-dot'

    _.sortBy data, (elem) -> elem.details.order

  twoFactorMethodSetup: (e) ->
    e.preventDefault()

    key    = e.currentTarget.closest('[data-two-factor-key]').dataset.twoFactorKey
    method = App.TwoFactorMethods.methodByKey(key)

    new App["TwoFactorConfigurationMethod#{method.identifier}"](
      container: @el.closest('.content')
      successCallback: @load
    )

  twoFactorMethodRemove: (e) ->
    e.preventDefault()

    key     = e.currentTarget.closest('tr').dataset.twoFactorKey
    method  = App.TwoFactorMethods.methodByKey(key)

    new App.TwoFactorConfigurationModalPasswordCheck(
      headPrefix: __('Remove two-factor authentication')
      buttonSubmit: 'Remove'
      successCallback: (data) =>
        @ajax(
          id:   'profile_two_factor_removal'
          type: 'DELETE'
          url:  @apiPath + '/users/two_factor/remove_authentication_method'
          processData: true
          data: JSON.stringify(
            method: key
            token: data.token
          )
          success: (data, status, xhr) =>
            @notify
              type:      'success'
              msg:       __('Two-factor authentication method was removed.')
              removeAll: true

            @load()
          error: (xhr, statusText) =>
            data = JSON.parse(xhr.responseText)

            message = data?.error || __('Could not remove two-factor authentication method')

            @notify
              type:      'error'
              msg:       message
              removeAll: true
        )
    )

  twoFactorMethodDefault: (e) =>
    e.preventDefault()

    @ajax(
      id:   'profile_two_factor_default_authentication_method'
      type: 'POST'
      url:  @apiPath + '/users/two_factor/default_authentication_method'
      processData: true
      data: JSON.stringify(
        method: e.currentTarget.closest('tr').dataset.twoFactorKey
      )
      success: (data, status, xhr) =>
        @notify
          type:      'success'
          msg:       __('Two-factor authentication method was set as default.')
          removeAll: true

        @load()
      error: (xhr, statusText) =>
        data = JSON.parse(xhr.responseText)

        message = data?.error || __('Could not set two-factor authentication method as default')

        @notify
          type:      'error'
          msg:       message
          removeAll: true
    )

  twoFactorMethodGenerateRecoveryCodes: (e) =>
    e.preventDefault()

    new App.TwoFactorConfigurationMethodRecoveryCodes(
      container: @el.closest('.content')
      overrideHeadPrefix: __('Generate recovery codes')
      successCallback: @load
    )

App.Config.set('Password', {
  prio: 2000,
  name: __('Password & Authentication'),
  parent: '#profile',
  target: '#profile/password',
  controller: ProfilePassword,
  permission: (controller) ->
    canChangePassword = App.Config.get('user_show_password_login') ||
      controller.permissionCheck('admin.*')

    twoFactorEnabled  = App.TwoFactorMethods.isAnyAuthenticationMethodEnabled() &&
      controller.permissionCheck('user_preferences.two_factor_authentication')

    return false if !canChangePassword && !twoFactorEnabled
    return controller.permissionCheck('user_preferences.password') || twoFactorEnabled
}, 'NavBarProfile')
