class App.ControllerManageTwoFactor extends App.ControllerModal
  buttonClose: true
  buttonSubmit: false
  head: __('Manage Two-Factor Authentication')

  events:
    'click .js-remove':     'remove'
    'click .js-remove-all': 'removeAll'

  constructor: ->
    super

    @load()

  load: =>
    @startLoading()

    @ajax(
      type: 'GET'
      url: "#{@apiPath}/users/#{@user.id}/admin_two_factor/enabled_authentication_methods"
      success: (data, status, xhr) =>
        @stopLoading()

        @loaded = true
        @user_methods = _.map(data, (elem) ->
          method = App.TwoFactorMethods.methodByKey(elem.method)

          { name: method.label, value: elem.method }
        )

        @update()
      error: (xhr) =>
        @stopLoading()

        data = JSON.parse(xhr.responseText)

        message = data?.error || __('Could not load the two-factor authentication configuration for this user.')

        @showAlert message
    )

  content: ->
    return if !@loaded

    view = $(App.view('user/manage_two_factor')())

    @controller = new App.ControllerForm(
      el: view.find('.js-attributes')
      model:
        configure_attributes: [
          {
            name: 'method'
            display: __('Remove a configured two-factor authentication method')
            tag: 'select',
            multiple: false
            limit: 100
            null: false
            nulloption: true
            translate: true
            options: @user_methods
          }
        ],
      autofocus: false
    )

    view

  remove: (e) ->
    e.preventDefault()

    params = @formParam(e.target)

    errors = @controller.validate(params)
    if !_.isEmpty(errors)
      @formValidate( form: e.target, errors: errors )
      return false

    @formDisable(e)

    @ajax(
      type: 'DELETE'
      url: "#{@apiPath}/users/#{@user.id}/admin_two_factor/remove_authentication_method"
      data: JSON.stringify(
        method: params.method
      )
      processData: true,
      success: (data, status, xhr) =>
        @user.trigger('two_factor_changed')

        method = App.TwoFactorMethods.methodByKey(params.method)
        @notify
          type:    'success'
          msg:     App.i18n.translatePlain('The two-factor authentication method "%s" was removed for this user.', App.i18n.translatePlain(method.label))
          timeout: 4000

        @close()
      error: (xhr, statusText) =>
        data = JSON.parse(xhr.responseText)

        message = data?.error || __('Could not remove the two-factor authentication method for this user.')

        @showAlert(message)
        @formEnable(e)
    )

  removeAll: (e) ->
    e.preventDefault()

    @formDisable(e)

    new App.ControllerConfirm(
      head:        __('Confirmation')
      message:     __('Are you sure? The user will have to to reconfigure all two-factor authentication methods.')
      buttonClass: 'btn--danger'
      onCancel: =>
        @formEnable(e)
      onClose: =>
        @formEnable(e)
      callback: =>
        @ajax(
          type: 'DELETE'
          url: "#{@apiPath}/users/#{@user.id}/admin_two_factor/remove_all_authentication_methods"
          success: (data, status, xhr) =>
            @user.trigger('two_factor_changed')

            @notify
              type:    'success'
              msg:     __('All two-factor authentication methods were removed for this user.')
              timeout: 4000

            @close()
          error: (xhr, statusText) =>
            data = JSON.parse(xhr.responseText)

            message = data?.error || __('Could not remove all two-factor authentication methods for this user.')

            @showAlert(message)
            @formEnable(e)
        )
    )
