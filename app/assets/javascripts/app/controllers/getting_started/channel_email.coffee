class GettingStartedChannelEmail extends App.ControllerWizardFullScreen
  events:
    'submit .js-intro':                    'probeBasedOnIntro'
    'submit .js-inbound':                  'probeInbound'
    'change .js-inbound [name=adapter]':   'toggleInboundAdapter'
    'change .js-outbound [name=adapter]':  'toggleOutboundAdapter'
    'change [name="options::ssl"]':        'toggleSslVerifyVisibility'
    'change [name="options::port"]':       'toggleSslVerifyVisibility'
    'change [name="options::ssl_verify"]': 'toggleSslVerifyAlert'
    'submit .js-outbound':                 'probleOutbound'
    'click  .js-goToSlide':                'goToSlide'

  constructor: ->
    super

    # redirect if we are not admin
    if !@permissionCheck('admin.wizard')
      @navigate '#'
      return

    # set title
    @title __('Email Account')

    # store account settings
    @account =
      inbound:  {}
      outbound: {}
      meta:     {}

    @channelDriver =
      email:
        inbound: {}
        outbound: {}

    @fetch()

  fetch: ->

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

  render: ->

    @replaceWith App.view('getting_started/email')()
    @showSlide('js-intro')

    # outbound
    configureAttributesOutbound = [
      { name: 'adapter', display: __('Send Mails via'), tag: 'select', multiple: false, null: false, options: @channelDriver.email.outbound },
    ]
    new App.ControllerForm(
      el:    @$('.base-outbound-type')
      model:
        configure_attributes: configureAttributesOutbound
        className: ''
      params:
        adapter: @account.outbound.adapter || 'smtp'
    )
    @toggleOutboundAdapter()

    # inbound
    configureAttributesInbound = [
      { name: 'adapter',                  display: __('Type'),     tag: 'select', multiple: false, null: false, options: @channelDriver.email.inbound },
      { name: 'options::host',            display: __('Host'),     tag: 'input',  type: 'text', limit: 120, null: false, autocapitalize: false },
      { name: 'options::user',            display: __('User'),     tag: 'input',  type: 'text', limit: 120, null: false, autocapitalize: false, autocomplete: 'off', },
      { name: 'options::password',        display: __('Password'), tag: 'input',  type: 'password', limit: 120, null: false, autocapitalize: false, autocomplete: 'off', single: true },
      { name: 'options::ssl',             display: __('SSL/STARTTLS'), tag: 'select', null: true, options: { 'off': __('No SSL'), 'ssl': __('SSL'), 'starttls': __('STARTTLS')  }, default: 'ssl', translate: true, item_class: 'formGroup--halfSize' },
      { name: 'options::ssl_verify',      display: __('SSL verification'), tag: 'boolean', default: true, null: true, translate: true, item_class: 'formGroup--halfSize' },
      { name: 'options::port',            display: __('Port'),     tag: 'input',  type: 'text', limit: 6,   null: true, autocapitalize: false,  default: '993', item_class: 'formGroup--halfSize' },
      { name: 'options::folder',          display: __('Folder'),   tag: 'input',  type: 'text', limit: 120, null: true, autocapitalize: false, item_class: 'formGroup--halfSize' },
      { name: 'options::keep_on_server',  display: __('Keep messages on server'), tag: 'boolean', null: true, options: { true: 'yes', false: 'no' }, translate: true, default: false, item_class: 'formGroup--halfSize' },
    ]

    showHideFolder = (params, attribute, attributes, classname, form, ui) ->
      return if !params
      if params.adapter is 'imap'
        ui.show('options::folder')
        ui.show('options::keep_on_server')
        return
      ui.hide('options::folder')
      ui.hide('options::keep_on_server')

    form = new App.ControllerForm(
      el:    @$('.base-inbound-settings')
      model:
        configure_attributes: configureAttributesInbound
        className: ''
      params: @account.inbound
      handlers: [
        showHideFolder,
      ]
    )
    @toggleInboundAdapter()

    form.el.find("select[name='options::ssl']").off('change').on('change', (e) ->
      if $(e.target).val() is 'ssl'
        form.el.find("[name='options::port']").val('993')
      else if $(e.target).val() is 'off'
        form.el.find("[name='options::port']").val('143')
    )

  toggleInboundAdapter: =>
    form     = @$('.base-inbound-settings')
    adapter  = form.find("select[name='adapter']")
    starttls = form.find("select[name='options::ssl'] option[value='starttls']")

    if adapter.val() isnt 'imap'
      starttls.remove()
    else if starttls.length < 1
      starttls = $('<option/>').attr('value', 'starttls').text(__('STARTTLS'))
      form.find("select[name='options::ssl']").append(starttls)

  toggleOutboundAdapter: =>

    # fill user / password based on intro info
    channel_used = { options: {} }
    if @account['meta']
      channel_used['options']['user']           = @account['meta']['email']
      channel_used['options']['password']       = @account['meta']['password']
      channel_used['options']['folder']         = @account['meta']['folder']
      channel_used['options']['keep_on_server'] = @account['meta']['keep_on_server']

    # show used backend
    @$('.base-outbound-settings').html('')
    adapter = @$('.js-outbound [name=adapter]').val()
    if adapter is 'smtp'
      configureAttributesOutbound = [
        { name: 'options::host',       display: __('Host'),     tag: 'input', type: 'text',     limit: 120, null: false, autocapitalize: false, autofocus: true },
        { name: 'options::user',       display: __('User'),     tag: 'input', type: 'text',     limit: 120, null: true, autocapitalize: false, autocomplete: 'off', },
        { name: 'options::password',   display: __('Password'), tag: 'input', type: 'password', limit: 120, null: true, autocapitalize: false, autocomplete: 'off', single: true },
        { name: 'options::port',       display: __('Port'),     tag: 'input', type: 'text',     limit: 6,   null: true, autocapitalize: false, item_class: 'formGroup--halfSize' },
        { name: 'options::ssl_verify', display: __('SSL verification'), tag: 'boolean', default: true, null: true, translate: true, item_class: 'formGroup--halfSize' },
      ]
      @form = new App.ControllerForm(
        el:    @$('.base-outbound-settings')
        model:
          configure_attributes: configureAttributesOutbound
          className: ''
        params: @account.outbound
      )

      @form.el.find("select[name='options::ssl']").off('change').on('change', (e) =>
        if $(e.target).val() is 'ssl'
          @form.el.find("[name='options::port']").val('465')
        else if $(e.target).val() is 'starttls'
          @form.el.find("[name='options::port']").val('587')
        else if $(e.target).val() is 'off'
          @form.el.find("[name='options::port']").val('25')
      )

  probeBasedOnIntro: (e) =>
    e.preventDefault()
    params = @formParam(e.target)

    # remember account settings
    @account.meta = params

    @disable(e)
    @$('.js-probe .js-email').text(params.email)
    @showSlide('js-probe')

    @ajax(
      id:   'email_probe'
      type: 'POST'
      url:  "#{@apiPath}/channels_email_probe"
      data: JSON.stringify(params)
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'
          if data.setting
            for key, value of data.setting
              @account[key] = value

          if data.content_messages
            @probeInboundArchive(data, true)
          else
            @verify(@account)

        else if data.result is 'duplicate'
          @showSlide('js-intro')
          @showAlert('js-intro', __('Account already exists!') )
        else
          @showSlide('js-inbound')
          @showAlert('js-inbound', __('The server settings could not be automatically detected. Please configure them manually.') )
          @$('.js-inbound [name="options::user"]').val( @account['meta']['email'] )
          @$('.js-inbound [name="options::password"]').val( @account['meta']['password'] )

        @enable(e)
      fail: =>
        @enable(e)
        @showSlide('js-intro')
    )

  probeInbound: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)
    @disable(e)

    @showSlide('js-test')

    @ajax(
      id:   'email_inbound'
      type: 'POST'
      url:  "#{@apiPath}/channels_email_inbound"
      data: JSON.stringify(params)
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'

          # remember account settings
          @account.inbound = params

          if data.content_messages
            @probeInboundArchive(data)
          else
            @showSlide('js-outbound')

          # fill user / password based on inbound settings
          if !@channel
            if @account['inbound']['options']
              @$('.js-outbound [name="options::host"]').val( @account['inbound']['options']['host'] )
              @$('.js-outbound [name="options::user"]').val( @account['inbound']['options']['user'] )
              @$('.js-outbound [name="options::password"]').val( @account['inbound']['options']['password'] )
            else
              @$('.js-outbound [name="options::user"]').val( @account['meta']['email'] )
              @$('.js-outbound [name="options::password"]').val( @account['meta']['password'] )

        else
          @showSlide('js-inbound')
          @showAlert('js-inbound', data.message_human || data.message )
          @showInvalidField('js-inbound', data.invalid_field)
        @enable(e)
      fail: =>
        @showSlide('js-inbound')
        @showAlert('js-inbound', data.message_human || data.message )
        @showInvalidField('js-inbound', data.invalid_field)
        @enable(e)
    )

  probeInboundArchive: (data, verify) =>
    if data.content_messages
      message = App.i18n.translateContent('%s email(s) were found in your mailbox. They will all be moved from your mailbox into Zammad.', data.content_messages)
      @$('.js-inbound-acknowledge .js-messageFound').html(message)
    else
      @$('.js-inbound-acknowledge .js-messageFound').remove()

    @showSlide('js-inbound-acknowledge')

    targetStateTypeIds = _.map(
      App.TicketStateType.search(filter:
        name: ['closed', 'open', 'new']
      ),
      (stateType) -> stateType.id
    )

    targetStateOptions = _.map(
      App.TicketState.search(filter:
        state_type_id: targetStateTypeIds
        active: true
      ),
      (targetState) ->
        value: targetState.id
        name: targetState.name
    )

    stateTypeClosed = App.TicketStateType.findByAttribute('name', 'closed')
    targetStateDefault = App.TicketState.findByAttribute('state_type_id', stateTypeClosed.id)

    configureAttributesAcknowledge = [
      { name: 'archive', display: __('Archive emails'), tag: 'switch', label_class: 'hidden', default: true },
      { name: 'archive_before', display: __('Archive cut-off time'), tag: 'datetime', null: false, help: __('Emails before the cut-off time are imported as archived tickets. Emails after the cut-off time are imported as regular tickets.') },
      { name: 'archive_state_id', display: __('Archive ticket target state'), tag: 'select', null: true, options: targetStateOptions, default: targetStateDefault.id },
    ]

    form = new App.ControllerForm(
      elReplace: @$('.js-archiveSettings'),
      model:
        configure_attributes: configureAttributesAcknowledge
        className: ''
      handlers: [
        App.FormHandlerChannelAccountArchiveMode.run
        App.FormHandlerChannelAccountArchiveBefore.run
      ]
    )

    @$('.js-inbound-acknowledge .js-next').off('click.continue').on('click.continue', (e) =>
      e.preventDefault()

      # get params
      params = @formParam(e.target)

      # validate form
      errors = form.validate(params)

      # show errors in form
      if errors
        @log 'error', errors
        @formValidate(form: @$('.js-archiveSettings'), errors: errors)
        return false

      @account.inbound         ||= {}
      @account.inbound.options ||= {}

      if params.archive
        @account.inbound.options = _.extend(@account.inbound.options, params)
      else
        delete @account.inbound.options.archive
        delete @account.inbound.options.archive_before
        delete @account.inbound.options.archive_state_id

      if !verify
        @$('.js-inbound-acknowledge .js-back').attr('data-slide', 'js-inbound')
        @$('.js-inbound-acknowledge .js-next').off('click.verify')
      else
        @$('.js-inbound-acknowledge .js-back').attr('data-slide', 'js-intro')
        @$('.js-inbound-acknowledge .js-next').attr('data-slide', '')
        @$('.js-inbound-acknowledge .js-next').off('click.verify').on('click.verify', (e) =>
          e.preventDefault()
          @verify(@account)
        )
    )

  probleOutbound: (e) =>
    e.preventDefault()

    # get params
    params          = @formParam(e.target)
    params['email'] = @account['meta']['email']

    sslVerifyField = $(e.target).closest('form').find('[name="options::ssl_verify"]')

    if sslVerifyField[0]?.disabled
      params.options.ssl_verify = false

    @disable(e)

    @showSlide('js-test')

    @ajax(
      id:   'email_outbound'
      type: 'POST'
      url:  "#{@apiPath}/channels_email_outbound"
      data: JSON.stringify(params)
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'

          # remember account settings
          @account.outbound = params

          @verify(@account)
        else
          @showSlide('js-outbound')
          @showAlert('js-outbound', data.message_human || data.message)
          @showInvalidField('js-outbound', data.invalid_field)
        @enable(e)
      fail: =>
        @showSlide('js-outbound')
        @showAlert('js-outbound', data.message_human || data.message)
        @showInvalidField('js-outbound', data.invalid_field)
        @enable(e)
    )

  verify: (account, count = 0) =>
    @showSlide('js-verify')

    @ajax(
      id:   'email_verify'
      type: 'POST'
      url:  "#{@apiPath}/channels_email_verify"
      data: JSON.stringify(account)
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'
          @navigate 'getting_started/agents', { emptyEl: true }
        else
          if data.source is 'inbound' || data.source is 'outbound'
            @showSlide("js-#{data.source}")
            @showAlert("js-#{data.source}", data.message_human || data.message)
            @showInvalidField("js-#{data.source}", data.invalid_field)
          else
            if count is 2
              @showAlert('js-verify', data.message_human || data.message)
              @delay(
                =>
                  @showSlide('js-intro')
                  @showAlert('js-intro', __('Email sending and receiving could not be verified. Please check your settings.') )

                2300
              )
            else
              if data.subject && @account
                @account.subject = data.subject
              @verify( @account, count + 1 )
      fail: =>
        @showSlide('js-intro')
        @showAlert('js-intro', __('Email sending and receiving could not be verified. Please check your settings.'))
    )

  toggleSslVerifyVisibility: (e) ->
    elem = $(e.target)

    # Skip the handler for port field in inbound dialog.
    return if elem.attr('name') is 'options::port' and elem.closest('form').find('[name="options::ssl"]').length

    isEnabled = if elem.attr('name') is 'options::port' then (elem.val() is '' or elem.val() is '465' or elem.val() is '587') else elem.val() isnt 'off'

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

App.Config.set('getting_started/channel/email', GettingStartedChannelEmail, 'Routes')
