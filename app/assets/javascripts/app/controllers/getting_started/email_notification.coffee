class GettingStartedEmailNotification extends App.ControllerWizardFullScreen
  events:
    'change .js-outbound [name=adapter]':  'toggleOutboundAdapter'
    'change [name="options::port"]':       'toggleSslVerifyVisibility'
    'change [name="options::ssl_verify"]': 'toggleSslVerifyAlert'
    'submit .js-outbound':                 'submit'

  constructor: ->
    super

    # redirect if we are not admin
    if !@permissionCheck('admin.wizard')
      @navigate '#'
      return

    # set title
    @title __('Email Notifications')

    @channelDriver =
      email:
        inbound: {}
        outbound: {}

    @fetch()

  fetch: =>

    # get data
    @ajax(
      id:    'getting_started'
      type:  'GET'
      url:   "#{@apiPath}/getting_started"
      processData: true
      success: (data, status, xhr) =>

        # check if import is active
        if data.import_mode == true
          @navigate "#import/#{data.import_backend}", { emptyEl: true }
          return

        @channelDriver = data.channel_driver

        # render page
        @render()
    )

  render: =>
    @replaceWith App.view('getting_started/email_notification')()
    configureAttributesOutbound = [
      { name: 'adapter', display: __('Send Mails via'), tag: 'select', multiple: false, null: false, options: @channelDriver.email.outbound, translate: true },
    ]
    new App.ControllerForm(
      el:    @$('.base-outbound-type')
      model:
        configure_attributes: configureAttributesOutbound
        className: ''
      params:
        adapter: 'sendmail'
    )
    @toggleOutboundAdapter()

  toggleOutboundAdapter: =>

    # show used backend
    @el.find('.base-outbound-settings').html('')
    adapter = @$('.js-outbound [name=adapter]').val()
    if adapter is 'smtp'
      configureAttributesOutbound = [
        { name: 'options::host',       display: __('Host'),     tag: 'input', type: 'text',     limit: 120, null: false, autocapitalize: false, autofocus: true },
        { name: 'options::user',       display: __('User'),     tag: 'input', type: 'text',     limit: 120, null: true, autocapitalize: false, autocomplete: 'off' },
        { name: 'options::password',   display: __('Password'), tag: 'input', type: 'password', limit: 120, null: true, autocapitalize: false, autocomplete: 'off', single: true },
        { name: 'options::port',       display: __('Port'),     tag: 'input', type: 'text',     limit: 6,   null: true, autocapitalize: false, item_class: 'formGroup--halfSize' },
        { name: 'options::ssl_verify', display: __('SSL verification'), tag: 'boolean', default: true, null: true, translate: true, item_class: 'formGroup--halfSize' },
      ]
      @form = new App.ControllerForm(
        el:    @$('.base-outbound-settings')
        model:
          configure_attributes: configureAttributesOutbound
          className: ''
      )

  submit: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)

    sslVerifyField = $(e.target).closest('form').find('[name="options::ssl_verify"]')

    if sslVerifyField[0]?.disabled
      params.options.ssl_verify = false

    @disable(e)

    @showSlide('js-test')

    @ajax(
      id:   'email_notification'
      type: 'POST'
      url:  "#{@apiPath}/channels_email_notification"
      data: JSON.stringify(params)
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'
          for key, value of data.settings
            App.Config.set(key, value)
          if App.Config.get('system_online_service')
            @navigate 'getting_started/channel/email_pre_configured', { emptyEl: true }
          else
            @navigate 'getting_started/channel', { emptyEl: true }
        else
          @showSlide('js-outbound')
          @showAlert('js-outbound', data.message_human || data.message )
          @showInvalidField('js-outbound', data.invalid_field)
          @enable(e)

      fail: =>
        @showSlide('js-outbound')
        @showAlert('js-outbound', data.message_human || data.message )
        @showInvalidField('js-outbound', data.invalid_field)
        @enable(e)
    )

  toggleSslVerifyVisibility: (e) ->
    elem      = $(e.target)
    isEnabled = elem.val() is '' or elem.val() is '465' or elem.val() is '587'

    sslVerifyField = elem.closest('form')
      .find('[name="options::ssl_verify"]')

    if isEnabled
      sslVerifyField.removeAttr('disabled')
    else
      sslVerifyField.attr('disabled', 'disabled')

    @toggleSslVerifyAlert(target: sslVerifyField, !isEnabled)

  toggleSslVerifyAlert: (e, forceInvisible) ->
    elem           = $(e.target)
    isAlertVisible = if forceInvisible then false else elem.val() != 'true'

    elem.closest('.wizard-slide')
      .find('.js-sslVerifyAlert')
      .toggleClass('hide', !isAlertVisible)

  showSlide: (className) ->
    super

    container      = @$('.'+className)
    sslVerifyField = container.find('[name="options::ssl_verify"]')

    return if sslVerifyField.length != 1
    return if sslVerifyField.val() == 'true'

    container
      .find('.js-sslVerifyAlert')
      .removeClass('hide')

App.Config.set('getting_started/email_notification', GettingStartedEmailNotification, 'Routes')
