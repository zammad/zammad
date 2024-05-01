class App.TwoFactorConfigurationModalSecurityKeys extends App.TwoFactorConfigurationModal
  buttonSubmit: __('Set Up')
  buttonClass: 'btn--success'
  head: __('Security Keys')

  content: ->
    false

  render: ->
    super

    $('.modal .js-loading').removeClass('hide')
    $('.modal .js-submit').prop('disabled', true)

    callback = (data) =>
      @config      = data?.configuration or {}
      @credentials = @config?.credentials or []

      content = $(App.view('widget/two_factor_configuration/security_keys/index')())

      $('.modal .js-loading').addClass('hide')
      $('.modal-body').html(content)
      $('.modal .js-submit').prop('disabled', false)

      return if not @credentials.length

      # Show the table with the keys only if there is at least one configured.
      $('.modal-body').find('.js-table').html(@renderTable().el)

    @fetchExistingSecurityKeys(callback)

  fetchExistingSecurityKeys: (callback) =>
    @ajax(
      id:      'two_factor_authentication_method_configuration'
      type:    'GET'
      url:     "#{@apiPath}/users/two_factor_authentication_method_configuration/security_keys"
      success: callback
      error:   callback
    )

  renderTable: =>
    new App.ControllerTable(
      customActions: [
        name: 'remove'
        display: __('Remove')
        icon: 'trash'
        class: 'btn--danger'
        callback: @removeSecurityKey
      ]
      overview: ['nickname', 'created_at']
      attribute_list: [
        { name: 'nickname',   display: __('Name'),       type: 'text' },
        { name: 'created_at', display: __('Created at'), tag:  'datetime' },
      ]
      objects: _.map(@credentials, (credential) ->
        _.extend(credential,
          id: credential.public_key
        )
      )
      pagerEnabled: false
    )

  confirmRemoval: (id) =>
    credential = @credentials.find((credential) -> credential.public_key is id)

    new App.ControllerConfirm(
      head:        __('Are you sure?')
      message:     App.i18n.translatePlain('Security key "%s" will be removed.', credential.nickname)
      buttonClass: 'btn--danger'
      container:   @el.closest('.content')
      small:       true
      callback: =>
        @removeSecurityKey(id)
    )

  removeSecurityKey: (id) =>
    data = { credential_id: id }

    @ajax(
      id:          'two_factor_authentication_method_configuration'
      type:        'DELETE'
      url:         "#{@apiPath}/users/two_factor_authentication_remove_credentials/security_keys"
      data:        JSON.stringify(data)
      processData: true
      success: =>
        # Refresh the table in the password profile screen.
        @successCallback()

        @render()
    )

  nextModalClass: ->
    App.TwoFactorConfigurationModalSecurityKeyConfig

  onSubmit: (e) ->

    # Pass the modal options to the next modal instance.
    @next(
      container: @container
      successCallback: @successCallback
    )

    # We are not calling `super`, since we do not want to call success callback yet.

class App.TwoFactorConfigurationModalSecurityKeyConfig extends App.TwoFactorConfigurationModal
  buttonSubmit: __('Next')
  buttonClass: 'btn--primary'
  head: __('Security Key')

  content: ->
    false

  render: ->
    super

    configure_attributes = [
        { name: 'nickname', display: __('Name for this security key'), tag: 'input', type: 'text', limit: 255, null: false, class: 'input' }
      ]

    @payloadForm = new App.ControllerForm(
      elReplace: $('.modal-body')
      model:     { configure_attributes: configure_attributes }
    )

  nextModalClass: ->
    App.TwoFactorConfigurationModalSecurityKeyRegister

  onSubmit: (e) ->
    params = @formParam(e.target)

    errors = @payloadForm.validate(params)
    if !_.isEmpty(errors)
      @formValidate(form: e.target, errors: errors)
      return false

    # Pass the modal options to the next modal instance.
    @next(
      container: @container
      nickname: params.nickname
      successCallback: @successCallback
    )

    # We are not calling `super`, since we do not want to call success callback yet.

class App.TwoFactorConfigurationModalSecurityKeyRegister extends App.TwoFactorConfigurationModal
  buttonSubmit: __('Retry')
  buttonClass: 'btn--primary hidden'
  head: __('Security Key')

  constructor: ->
    @method = App.Config.get('TwoFactorMethods').SecurityKeys

    super

  content: ->
    false

  render: ->
    super

    $('.modal .js-loading').removeClass('hide')

    callback = (data) =>
      @config = data.configuration

      content = $(App.view('widget/two_factor_configuration/security_keys/register')())

      $('.modal .js-loading').addClass('hide')
      $('.modal-body').html(content)

      @onSubmit()

    @fetchInitialConfiguration(callback)

  fetchInitialConfiguration: (callback) =>
    @ajax(
      id:      'two_factor_authentication_method_initiate_configuration'
      type:    'GET'
      url:     "#{@apiPath}/users/two_factor_authentication_method_initiate_configuration/#{@method.key}"
      success: callback
    )

  showError: (message = __('Security key setup failed.')) =>
    @el.find('.main').hide()
    @showAlert(message)
    @el.find('.js-submit').removeClass('hidden')

  hideError: =>
    @el.find('.js-submit').addClass('hidden')
    @clearAlerts()
    @el.find('.main').show()

  onSubmit: =>
    @hideError()

    if not window.isSecureContext
      @showError(__('The application is not running in a secure context.'))
      return

    webauthnJSON
      .create(publicKey: @config)
      .then((publicKeyCredential) =>
        data = JSON.stringify(
          method: @method.key
          payload:
            credential: publicKeyCredential
            challenge:  @config.challenge
          configuration: _.extend({}, @config, { nickname: @nickname, type: 'registration' })
        )

        @ajax
          id: 'two_factor_verify_configuration'
          type: 'POST'
          url: "#{@apiPath}/users/two_factor_verify_configuration"
          data: data
          processData: true
          success: (data, status, xhr) =>
            if data?.verified
              @finalizeConfigurationWizard(data)
              return

            App.Log.error('TwoFactorConfigurationModalSecurityKeyRegister', data, status)
            @showError()
        )
      .catch((e) =>
        App.Log.error('TwoFactorConfigurationModalSecurityKeyRegister', e)
        @showError()
      )
