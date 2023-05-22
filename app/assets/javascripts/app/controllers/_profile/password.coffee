class ProfilePassword extends App.ControllerSubContent
  @requiredPermission: 'user_preferences.password'
  header: __('Password & Authentication')
  events:
    'submit form': 'update'
    'click [data-type="setup"]':  'twoFactorMethodSetup'
    'click [data-type="remove"]': 'twoFactorMethodRemove'

  constructor: ->
    super

    @controllerBind('config_update', (data) =>
      return if data.name isnt 'two_factor_authentication_method_authenticator_app'

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
      id:   'profile_two_factor'
      type: 'GET'
      url:  @apiPath + "/users/#{App.User.current().id}/two_factor_enabled_methods"
      processData: true
      success: (data, status, xhr) =>
        @stopLoading()

        @render(data)
      error: (xhr) =>
        @stopLoading()
    )

  allowsChangePassword: ->
    App.Config.get('user_show_password_login') || @permissionCheck('admin.*')

  allowsTwoFactor: ->
    App.Config.get('two_factor_authentication_method_authenticator_app')

  render: (twoFactorMethods) =>

    # item
    html = $( App.view('profile/password')(
      allowsChangePassword: @allowsChangePassword(),
      allowsTwoFactor:      @allowsTwoFactor(),
      twoFactorMethods:     @transformTwoFactorMethods(twoFactorMethods)
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
        msg:       __('Can\'t update password, your entered passwords do not match. Please try again!')
        removeAll: true
      return
    if !params['password_new']
      @formEnable(e)
      @notify
        type:      'error'
        msg:       __('Please supply your new password!')
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
      msg:  App.i18n.translateContent( 'Password changed successfully!' )
    )

  error: (xhr, status, error) =>
    return if xhr.status != 422

    data = xhr.responseJSON

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

    key    = e.currentTarget.closest('tr').dataset.twoFactorKey
    method = App.TwoFactorMethods.methodByKey(key)

    new App["TwoFactorConfigurationMethod#{method.identifier}"](
      container: @el.closest('.content')
      successCallback: @load
    )

  twoFactorMethodRemove: (e) =>
    e.preventDefault()

    key     = e.currentTarget.closest('tr').dataset.twoFactorKey
    method  = App.TwoFactorMethods.methodByKey(key)

    new App.ControllerConfirm(
      head: __('Are you sure?')
      message: App.i18n.translatePlain('Two-factor authentication method "%s" will be removed.', App.i18n.translatePlain(method.label))
      container: @el.closest('.content')
      small: true
      callback: =>
        @ajax(
          id:   'profile_two_factor_removal'
          type: 'DELETE'
          url:  @apiPath + "/users/#{App.User.current().id}/two_factor_remove_method"
          processData: true
          data: JSON.stringify(
            method: key
          )
          success: (data, status, xhr) =>
            @notify
              type:      'success'
              msg:       App.i18n.translateContent('Two-factor authentication method was removed.')
              removeAll: true

            @load()
          error: (xhr, statusText) =>
            data = JSON.parse(xhr.responseText)

            message = data?.error || __('Could not remove two-factor authentication method')

            @notify
              type:      'error'
              msg:       App.i18n.translateContent(message)
              removeAll: true
        )
    )

App.Config.set('Password', {
  prio: 2000,
  name: __('Password & Authentication'),
  parent: '#profile',
  target: '#profile/password',
  controller: ProfilePassword,
  permission: (controller) ->
    canChangePassword = App.Config.get('user_show_password_login') || controller.permissionCheck('admin.*')
    twoFactorEnabled  = App.Config.get('two_factor_authentication_method_authenticator_app')

    return false if !canChangePassword && !twoFactorEnabled
    return controller.permissionCheck('user_preferences.password')
}, 'NavBarProfile')
