class GettingStartedChannelEmail extends App.ControllerWizardFullScreen
  events:
    'submit .js-intro':                   'probeBasedOnIntro'
    'submit .js-inbound':                 'probeInbound'
    'change .js-outbound [name=adapter]': 'toggleOutboundAdapter'
    'submit .js-outbound':                'probleOutbound'
    'click  .js-goToSlide':               'goToSlide'

  constructor: ->
    super

    # redirect if we are not admin
    if !@permissionCheck('admin.wizard')
      @navigate '#'
      return

    # set title
    @title 'Email Account'

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
      { name: 'adapter', display: 'Send Mails via', tag: 'select', multiple: false, null: false, options: @channelDriver.email.outbound },
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
      { name: 'adapter',                  display: 'Type',     tag: 'select', multiple: false, null: false, options: @channelDriver.email.inbound },
      { name: 'options::host',            display: 'Host',     tag: 'input',  type: 'text', limit: 120, null: false, autocapitalize: false },
      { name: 'options::user',            display: 'User',     tag: 'input',  type: 'text', limit: 120, null: false, autocapitalize: false, autocomplete: 'off', },
      { name: 'options::password',        display: 'Password', tag: 'input',  type: 'password', limit: 120, null: false, autocapitalize: false, autocomplete: 'off', single: true },
      { name: 'options::ssl',             display: 'SSL/STARTTLS', tag: 'boolean', null: true, options: { true: 'yes', false: 'no'  }, default: true, translate: true, item_class: 'formGroup--halfSize' },
      { name: 'options::port',            display: 'Port',     tag: 'input',  type: 'text', limit: 6,   null: true, autocapitalize: false,  default: '993', item_class: 'formGroup--halfSize' },
      { name: 'options::folder',          display: 'Folder',   tag: 'input',  type: 'text', limit: 120, null: true, autocapitalize: false, item_class: 'formGroup--halfSize' },
      { name: 'options::keep_on_server',  display: 'Keep messages on server', tag: 'boolean', null: true, options: { true: 'yes', false: 'no' }, translate: true, default: false, item_class: 'formGroup--halfSize' },
    ]

    showHideFolder = (params, attribute, attributes, classname, form, ui) ->
      return if !params
      if params.adapter is 'imap'
        ui.show('options::folder')
        ui.show('options::keep_on_server')
        return
      ui.hide('options::folder')
      ui.hide('options::keep_on_server')

    handlePort = (params, attribute, attributes, classname, form, ui) ->
      return if !params
      return if !params.options
      currentPort = @$('.base-inbound-settings [name="options::port"]').val()
      if params.options.ssl is true
        if !currentPort
          @$('.base-inbound-settings [name="options::port"]').val('993')
        return
      if params.options.ssl is false
        if !currentPort || currentPort is '993'
          @$('.base-inbound-settings [name="options::port"]').val('143')
        return

    new App.ControllerForm(
      el:    @$('.base-inbound-settings')
      model:
        configure_attributes: configureAttributesInbound
        className: ''
      params: @account.inbound
      handlers: [
        showHideFolder,
        handlePort,
      ]
    )

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
        { name: 'options::host',     display: 'Host',     tag: 'input', type: 'text',     limit: 120, null: false, autocapitalize: false, autofocus: true },
        { name: 'options::user',     display: 'User',     tag: 'input', type: 'text',     limit: 120, null: true, autocapitalize: false, autocomplete: 'off', },
        { name: 'options::password', display: 'Password', tag: 'input', type: 'password', limit: 120, null: true, autocapitalize: false, autocomplete: 'off', single: true },
        { name: 'options::port',     display: 'Port',     tag: 'input', type: 'text',     limit: 6,   null: true, autocapitalize: false },
      ]
      @form = new App.ControllerForm(
        el:    @$('.base-outbound-settings')
        model:
          configure_attributes: configureAttributesOutbound
          className: ''
        params: @account.outbound
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

          if data.content_messages && data.content_messages > 0 && (!@account['inbound']['options'] || @account['inbound']['options']['keep_on_server'] isnt true)
            @probeInboundMessagesFound(data, true)
            @probeInboundArchive(data)
          else
            @verify(@account)

        else if data.result is 'duplicate'
          @showSlide('js-intro')
          @showAlert('js-intro', 'Account already exists!' )
        else
          @showSlide('js-inbound')
          @showAlert('js-inbound', 'Unable to detect your server settings. Manual configuration needed.' )
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

          if data.content_messages && data.content_messages > 0 && (!@account['inbound']['options'] || @account['inbound']['options']['keep_on_server'] isnt true)
            @probeInboundMessagesFound(data, true)
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

  probeInboundMessagesFound: (data, verify) =>
    message = App.i18n.translateContent('We have already found %s email(s) in your mailbox. Zammad will move it all from your mailbox into Zammad.', data.content_messages)
    @$('.js-inbound-acknowledge .js-messageFound').html(message)

    if !verify
      @$('.js-inbound-acknowledge .js-back').attr('data-slide', 'js-inbound')
      @$('.js-inbound-acknowledge .js-next').unbind('click.verify')
    else
      @$('.js-inbound-acknowledge .js-back').attr('data-slide', 'js-intro')
      @$('.js-inbound-acknowledge .js-next').attr('data-slide', '')
      @$('.js-inbound-acknowledge .js-next').unbind('click.verify').bind('click.verify', (e) =>
        e.preventDefault()
        @verify(@account)
      )
    @showSlide('js-inbound-acknowledge')

  probeInboundArchive: (data) =>
    if data.archive_possible isnt true
      @$('.js-archiveMessage').addClass('hide')
      return

    @$('.js-archiveMessage').removeClass('hide')
    message = App.i18n.translateContent('In addition, we have found emails in your mailbox that are older than %s weeks. You can import such emails as an "archive", which means that no notifications are sent and the tickets have the status "closed". However, you can find them in Zammad anytime using the search function.', data.archive_week_range)
    @$('.js-inbound-acknowledge .js-archiveMessageCount').html(message)

    configureAttributesAcknowledge = [
      {
        name: 'archive'
        tag: 'boolean'
        null: true
        default: no
        options: {
          true: 'archive'
          false: 'regular'
        }
        translate: true
      },
    ]

    new App.ControllerForm(
      elReplace: @$('.js-importTypeSelect'),
      model:
        configure_attributes: configureAttributesAcknowledge
        className: ''
      noFieldset: true
    )
    @$('.js-importTypeSelect select[name=archive]').on('change', (e) =>
      value                      = $(e.target).val()
      @account.inbound         ||= {}
      @account.inbound.options ||= {}
      if value is 'true'
        @account.inbound.options.archive        = true
        @account.inbound.options.archive_before = (new Date()).toISOString()
      else
        delete @account.inbound.options.archive
        delete @account.inbound.options.archive_before
    )
    @$('.js-importTypeSelect select[name=archive]').trigger('change')

  probleOutbound: (e) =>
    e.preventDefault()

    # get params
    params          = @formParam(e.target)
    params['email'] = @account['meta']['email']
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
                  @showAlert('js-intro', 'Unable to verify sending and receiving. Please check your settings.' )

                2300
              )
            else
              if data.subject && @account
                @account.subject = data.subject
              @verify( @account, count + 1 )
      fail: =>
        @showSlide('js-intro')
        @showAlert('js-intro', 'Unable to verify sending and receiving. Please check your settings.')
    )

App.Config.set('getting_started/channel/email', GettingStartedChannelEmail, 'Routes')
