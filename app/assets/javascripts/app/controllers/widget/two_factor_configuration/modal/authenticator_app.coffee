class App.TwoFactorConfigurationModalAuthenticatorApp extends App.TwoFactorConfigurationModal
  buttonSubmit: __('Set Up')
  buttonClass: 'btn--success'
  head: __('Authenticator App')

  constructor: ->
    @method = App.Config.get('TwoFactorMethods').AuthenticatorApp

    super

  content: ->
    false

  render: ->
    super

    $('.modal .js-loading').removeClass('hide')
    $('.modal .js-submit').prop('disabled', true)

    callback = (data) =>
      if data?.invalid_password_token
        @invalidPasswordToken()
        return

      @config = data.configuration

      content = $(App.view('widget/two_factor_configuration/authenticator_app')(
        config: @config
      ))

      configure_attributes = [
        { name: 'payload', display: __('Security Code'), tag: 'input', type: 'text', limit: 100, null: false, class: 'input', label_class: 'hidden', placeholder: __('Security Code') }
      ]

      @payloadForm = new App.ControllerForm(
        el:    content.find('.js-payload-form')
        model: { configure_attributes: configure_attributes }
      )

      qr_code_canvas = content.find('.js-qr-code-canvas')
      qr_code = qrcodegen.QrCode.encodeText(@config.provisioning_uri, qrcodegen.QrCode.Ecc.MEDIUM)

      @drawCanvas(qr_code, 6, 1, 'white', 'black', qr_code_canvas.get(0))

      # Toggle authenticator app secret on click.
      qr_code_canvas.on('click.authenticator_app', ->
        content.find('.js-secret')
          .show()
          .on('click.authenticator_app', ->
            $(@).hide()
          )
      )

      $('.modal .js-loading').addClass('hide')
      $('.modal-body').html(content)
      $('.modal .js-submit').prop('disabled', false)
      $('.modal input[name="payload"]').focus()

    @fetchInitialConfiguration(callback)

  fetchInitialConfiguration: (callback) =>
    @ajax(
      id:          'two_factor_authentication_method_initiate_configuration'
      type:        'POST'
      url:         "#{@apiPath}/users/two_factor/authentication_method_initiate_configuration/#{@method.key}"
      data:        JSON.stringify(token: @token)
      processData: true
      success:     callback
    )

  onSubmit: (e) =>
    params = @formParam(e.target)

    errors = @payloadForm.validate(params)
    if !_.isEmpty(errors)
      @formValidate(form: e.target, errors: errors)
      return false

    data = JSON.stringify(
      method: @method.key
      token: @token
      payload: params.payload
      configuration: @config
    )

    @formDisable(e)

    @ajax
      id: 'two_factor_verify_configuration'
      type: 'POST'
      url: "#{@apiPath}/users/two_factor/verify_configuration"
      data: data
      processData: true
      success: (data, status, xhr) =>
        if data?.invalid_password_token
          @invalidPasswordToken()
          return

        if data?.verified
          @finalizeConfigurationWizard(data)
          return

        @formValidate( form: e.target, errors:
          payload: __('Invalid security code! Please try again with a new code.')
        )

        @formEnable(e)

  # CoffeeScript re-implementation of:
  #   https://github.com/nayuki/QR-Code-generator/blob/master/typescript-javascript/qrcodegen-input-demo.ts?ts=4#L153
  drawCanvas: (qr, scale, border, lightColor, darkColor, canvas) ->
    if scale <= 0 or border < 0
      # coffeelint: disable=detect_translatable_string
      throw new RangeError('Value out of range')
      # coffeelint: enable=detect_translatable_string

    width = (qr.size + border * 2) * scale
    canvas.width = width
    canvas.height = width
    ctx = canvas.getContext('2d')

    for y in [-border..(qr.size + border)]
      for x in [-border..(qr.size + border)]
        ctx.fillStyle = if qr.getModule(x, y) then darkColor else lightColor
        ctx.fillRect (x + border) * scale, (y + border) * scale, scale, scale
