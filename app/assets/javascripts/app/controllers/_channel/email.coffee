class ChannelEmail extends App.ControllerTabs
  requiredPermission: 'admin.channel_email'
  header: 'Email'
  constructor: ->
    super

    @title 'Email', true

    @tabs = [
      {
        name:       'Accounts',
        target:     'c-account',
        controller: ChannelEmailAccountOverview,
      },
      {
        name:       'Filter',
        target:     'c-filter',
        controller: App.ChannelEmailFilter,
      },
      {
        name:       'Signatures',
        target:     'c-signature',
        controller: App.ChannelEmailSignature,
      },
      {
        name:       'Settings',
        target:     'c-setting',
        controller: App.SettingsArea,
        params:     { area: 'Email::Base' },
      },
    ]

    @render()

class ChannelEmailAccountOverview extends App.Controller
  events:
    'click .js-channelNew': 'wizard'
    'click .js-channelDelete': 'delete'
    'click .js-channelDisable': 'disable'
    'click .js-channelEnable': 'enable'
    'click .js-channelGroupChange': 'groupChange'
    'click .js-editInbound': 'editInbound'
    'click .js-editOutbound': 'editOutbound'
    'click .js-emailAddressNew': 'emailAddressNew'
    'click .js-emailAddressEdit': 'emailAddressEdit'
    'click .js-emailAddressDelete': 'emailAddressDelete',
    'click .js-editNotificationOutbound': 'editNotificationOutbound'
    'click .js-migrateGoogleMail': 'migrateGoogleMail'
    'click .js-migrateMicrosoft365Mail': 'migrateMicrosoft365Mail'

  constructor: ->
    super
    @interval(@load, 30000)
    #@load()

  load: =>

    @startLoading()

    @ajax(
      id:   'email_index'
      type: 'GET'
      url:  "#{@apiPath}/channels_email"
      processData: true
      success: (data, status, xhr) =>
        @stopLoading()
        App.Collection.loadAssets(data.assets)
        @render(data)
    )

  render: (data = {}) =>

    @channelDriver = data.channel_driver

    # get channels
    account_channels = []
    for channel_id in data.account_channel_ids
      account_channel = App.Channel.fullLocal(channel_id)
      if account_channel.group_id
        account_channel.group = App.Group.find(account_channel.group_id)
      else
        account_channel.group = '-'
      account_channels.push account_channel

    for channel in account_channels
      email_addresses = App.EmailAddress.search(filter: { channel_id: channel.id })
      channel.email_addresses = email_addresses

    # get all unlinked email addresses
    not_used_email_addresses = []
    for email_address_id in data.not_used_email_address_ids
      not_used_email_addresses.push App.EmailAddress.find(email_address_id)

    # get channels
    notification_channels = []
    for channel_id in data.notification_channel_ids
      notification_channels.push App.Channel.find(channel_id)

    @html App.view('channel/email_account_overview')(
      account_channels:         account_channels
      not_used_email_addresses: not_used_email_addresses
      notification_channels:    notification_channels
      accounts_fixed:           data.accounts_fixed
      config:                   data.config
    )

  wizard: (e) =>
    e.preventDefault()
    new ChannelEmailAccountWizard(
      container:     @el.closest('.content')
      callback:      @load
      channelDriver: @channelDriver
    )

  editInbound: (e) =>
    e.preventDefault()
    id      = $(e.target).closest('.action').data('id')
    channel = App.Channel.find(id)
    slide   = 'js-inbound'
    new ChannelEmailAccountWizard(
      container:     @el.closest('.content')
      slide:         slide
      channel:       channel
      callback:      @load
      channelDriver: @channelDriver
    )

  editOutbound: (e) =>
    e.preventDefault()
    id      = $(e.target).closest('.action').data('id')
    channel = App.Channel.find(id)
    slide   = 'js-outbound'
    new ChannelEmailAccountWizard(
      container:     @el.closest('.content')
      slide:         slide
      channel:       channel
      callback:      @load
      channelDriver: @channelDriver
    )

  delete: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    new App.ControllerConfirm(
      message: 'Sure?'
      callback: =>
        @ajax(
          id:   'email_delete'
          type: 'DELETE'
          url:  "#{@apiPath}/channels_email"
          data: JSON.stringify(id: id)
          processData: true
          success: =>
            @load()
        )
      container: @el.closest('.content')
    )

  disable: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    @ajax(
      id:   'email_disable'
      type: 'POST'
      url:  "#{@apiPath}/channels_email_disable"
      data: JSON.stringify(id: id)
      processData: true
      success: =>
        @load()
    )

  enable: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    @ajax(
      id:   'email_enable'
      type: 'POST'
      url:  "#{@apiPath}/channels_email_enable"
      data: JSON.stringify(id: id)
      processData: true
      success: =>
        @load()
    )

  groupChange: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    item = App.Channel.find(id)
    new ChannelEmailEdit(
      container: @el.closest('.content')
      item: item
      callback: @load
    )

  emailAddressNew: (e) =>
    e.preventDefault()
    channel_id = $(e.target).closest('.action').data('id')
    new App.ControllerGenericNew(
      pageData:
        object: 'Email Address'
      genericObject: 'EmailAddress'
      container: @el.closest('.content')
      item:
        channel_id: channel_id
      callback: @load
    )

  emailAddressEdit: (e) =>
    e.preventDefault()
    id = $(e.target).closest('li').data('id')
    new App.ControllerGenericEdit(
      pageData:
        object: 'Email Address'
      genericObject: 'EmailAddress'
      container: @el.closest('.content')
      id: id
      callback: @load
    )

  emailAddressDelete: (e) =>
    e.preventDefault()
    id = $(e.target).closest('li').data('id')
    item = App.EmailAddress.find(id)
    new App.ControllerGenericDestroyConfirm(
      item: item
      container: @el.closest('.content')
      callback: @load
    )

  editNotificationOutbound: (e) =>
    e.preventDefault()
    id      = $(e.target).closest('.action').data('id')
    channel = App.Channel.find(id)
    slide   = 'js-outbound'
    new ChannelEmailNotificationWizard(
      container:     @el.closest('.content')
      channel:       channel
      callback:      @load
      channelDriver: @channelDriver
    )

  migrateGoogleMail: (e) =>
    e.preventDefault()
    id = $(e.target).closest('.action').data('id')
    @navigate "#channels/google/#{id}"

  migrateMicrosoft365Mail: (e) =>
    e.preventDefault()
    id = $(e.target).closest('.action').data('id')
    @navigate "#channels/microsoft365/#{id}"


class ChannelEmailEdit extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: 'Channel'

  content: =>
    configureAttributesBase = [
      { name: 'group_id', display: 'Destination Group', tag: 'select', null: false, relation: 'Group', nulloption: true, filter: { active: true } },
    ]
    @form = new App.ControllerForm(
      model:
        configure_attributes: configureAttributesBase
        className: ''
      params: @item
    )
    @form.form

  onSubmit: (e) =>

    # get params
    params = @formParam(e.target)

    # validate form
    errors = @form.validate(params)

    # show errors in form
    if errors
      @log 'error', errors
      @formValidate(form: e.target, errors: errors)
      return false

    # disable form
    @formDisable(e)

    # update
    @ajax(
      id:   'channel_email_group'
      type: 'POST'
      url:  "#{@apiPath}/channels_email_group/#{@item.id}"
      data: JSON.stringify(params)
      processData: true
      success: (data, status, xhr) =>
        @callback()
        @close()
      error: (xhr) =>
        data = JSON.parse(xhr.responseText)
        @formEnable(e)
        @el.find('.alert').removeClass('hidden').text(data.error || 'Unable to save changes.')
    )

class ChannelEmailAccountWizard extends App.ControllerWizardModal
  elements:
    '.modal-body': 'body'
  events:
    'submit .js-intro':                   'probeBasedOnIntro'
    'submit .js-inbound':                 'probeInbound'
    'change .js-outbound [name=adapter]': 'toggleOutboundAdapter'
    'submit .js-outbound':                'probleOutbound'
    'click  .js-goToSlide':               'goToSlide'
    'click  .js-expert':                  'probeBasedOnIntro'
    'click  .js-close':                   'hide'
  inboundPassword: ''
  outboundPassword: ''
  passwordPlaceholder: '{{{{{{{{{{{{SECRTE_PASSWORD}}}}}}}}}}}}'

  constructor: ->
    super

    # store account settings
    @account =
      inbound:
        adapter: undefined
        options: undefined
      outbound:
        adapter: undefined
        options: undefined
      meta:     {}

    if @channel
      @account =
        inbound: clone(@channel.options.inbound)
        outbound: clone(@channel.options.outbound)
        meta: {}

      # remember passwords, do not show in ui
      if @account.inbound.options && @account.inbound.options.password
        @inboundPassword = @account.inbound.options.password
        @account.inbound.options.password = @passwordPlaceholder
      if @account.outbound.options && @account.outbound.options.password
        @outboundPassword = @account.outbound.options.password
        @account.outbound.options.password = @passwordPlaceholder

    if @container
      @el.addClass('modal--local')

    @render()

    if @channel
      @$('.js-goToSlide[data-slide=js-intro]').addClass('hidden')

    @el.modal(
      keyboard:  true
      show:      true
      backdrop:  true
      container: @container
    ).on(
      'hidden.bs.modal': =>
        if @callback
          @callback()
        @el.remove()
    )
    if @slide
      @showSlide(@slide)

  render: =>
    @html App.view('channel/email_account_wizard')()
    @showSlide('js-intro')

    # base
    configureAttributesBase = [
      { name: 'realname', display: 'Organization & Department Name', tag: 'input',  type: 'text', limit: 160, null: false, placeholder: 'Organization Support', autocomplete: 'off' },
      { name: 'email',    display: 'Email',    tag: 'input',  type: 'email', limit: 120, null: false, placeholder: 'support@example.com', autocapitalize: false, autocomplete: 'off' },
      { name: 'password', display: 'Password', tag: 'input',  type: 'password', limit: 120, null: false, autocapitalize: false, autocomplete: 'new-password', single: true },
      { name: 'group_id', display: 'Destination Group', tag: 'select', null: false, relation: 'Group', nulloption: true },
    ]
    @formMeta = new App.ControllerForm(
      el:    @$('.base-settings'),
      model:
        configure_attributes: configureAttributesBase
        className: ''
      params: @account.meta
    )

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
      { name: 'options::user',            display: 'User',     tag: 'input',  type: 'text', limit: 120, null: false, autocapitalize: false, autocomplete: 'off' },
      { name: 'options::password',        display: 'Password', tag: 'input',  type: 'password', limit: 120, null: false, autocapitalize: false, autocomplete: 'new-password', single: true },
      { name: 'options::ssl',             display: 'SSL/STARTTLS',      tag: 'boolean', null: true, options: { true: 'yes', false: 'no'  }, default: true, translate: true, item_class: 'formGroup--halfSize' },
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
      currentPort = @$('[name="options::port"]').val()
      if params.options.ssl is true
        if !currentPort
          @$('[name="options::port"]').val('993')
        return
      if params.options.ssl is false
        if !currentPort || currentPort is '993'
          @$('[name="options::port"]').val('143')
        return

    new App.ControllerForm(
      el:    @$('.base-inbound-settings'),
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
        { name: 'options::password', display: 'Password', tag: 'input', type: 'password', limit: 120, null: true, autocapitalize: false, autocomplete: 'new-password', single: true },
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

    # let backend know about the channel
    if @channel
      params.channel_id = @channel.id

    if $(e.currentTarget).hasClass('js-expert')

      # validate form
      errors = @formMeta.validate(params)
      if errors
        delete errors.password
      if !_.isEmpty(errors)
        @formValidate(form: e.target, errors: errors)
        return

      @showSlide('js-inbound')
      @$('.js-inbound [name="options::user"]').val(params.email)
      @$('.js-inbound [name="options::password"]').val(params.password)
      return

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
          @showAlert('js-intro', 'Account already exists!')
        else
          @showSlide('js-inbound')
          @showAlert('js-inbound', 'Unable to detect your server settings. Manual configuration needed.')
          @$('.js-inbound [name="options::user"]').val(@account['meta']['email'])
          @$('.js-inbound [name="options::password"]').val(@account['meta']['password'])

        @enable(e)
      error: =>
        @enable(e)
        @showSlide('js-intro')
    )

  probeInbound: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)

    if params.options && params.options.password is @passwordPlaceholder
      params.options.password = @inboundPassword

    # let backend know about the channel
    if @channel
      params.channel_id = @channel.id

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
            @probeInboundMessagesFound(data)
            @probeInboundArchive(data)
          else
            @showSlide('js-outbound')

          # fill user / password based on inbound settings
          if !@channel
            if @account['inbound']['options']
              @$('.js-outbound [name="options::host"]').val(@account['inbound']['options']['host'])
              @$('.js-outbound [name="options::user"]').val(@account['inbound']['options']['user'])
              @$('.js-outbound [name="options::password"]').val(@account['inbound']['options']['password'])
            else
              @$('.js-outbound [name="options::user"]').val(@account['meta']['email'])
              @$('.js-outbound [name="options::password"]').val(@account['meta']['password'])

        else
          @showSlide('js-inbound')
          @showAlert('js-inbound', data.message_human || data.message)
          @showInvalidField('js-inbound', data.invalid_field)
        @enable(e)
      error: (xhr) =>
        data = JSON.parse(xhr.responseText)
        @showSlide('js-inbound')
        @showAlert('js-inbound', data.message_human || data.message || data.error)
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

    if params.options && params.options.password is @passwordPlaceholder
      params.options.password = @outboundPassword

    if !params['email'] && @channel
      email_addresses = App.EmailAddress.search(filter: { channel_id: @channel.id })
      if email_addresses && email_addresses[0]
        params['email'] = email_addresses[0].email

    # let backend know about the channel
    if @channel
      params.channel_id = @channel.id

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
      error: (xhr) =>
        data = JSON.parse(xhr.responseText)
        @showSlide('js-outbound')
        @showAlert('js-outbound', data.message_human || data.message || data.error)
        @showInvalidField('js-outbound', data.invalid_field)
        @enable(e)
    )

  verify: (account, count = 0) =>
    @showSlide('js-verify')

    # let backend know about the channel
    if @channel
      account.channel_id = @channel.id

    if account.meta.group_id
      account.group_id = account.meta.group_id
    else if @channel.group_id
      account.group_id = @channel.group_id

    if !account.email && @channel
      email_addresses = App.EmailAddress.search(filter: { channel_id: @channel.id })
      if email_addresses && email_addresses[0]
        account.email = email_addresses[0].email

    @ajax(
      id:   'email_verify'
      type: 'POST'
      url:  "#{@apiPath}/channels_email_verify"
      data: JSON.stringify(account)
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'
          @el.modal('hide')
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
                  @showAlert('js-intro', 'Unable to verify sending and receiving. Please check your settings.')

                2300
              )
            else
              if data.subject && @account
                @account.subject = data.subject
              @verify(@account, count + 1)
      error: =>
        @showSlide('js-intro')
        @showAlert('js-intro', 'Unable to verify sending and receiving. Please check your settings.')
    )

  hide: (e) =>
    e.preventDefault()
    @el.modal('hide')

class ChannelEmailNotificationWizard extends App.ControllerWizardModal
  elements:
    '.modal-body': 'body'
  events:
    'change .js-outbound [name=adapter]': 'toggleOutboundAdapter'
    'submit .js-outbound':                'probleOutbound'
    'click  .js-close':                   'hide'
  inboundPassword: ''
  outboundPassword: ''
  passwordPlaceholder: '{{{{{{{{{{{{SECRTE_PASSWORD}}}}}}}}}}}}'

  constructor: ->
    super

    # store account settings
    @account =
      inbound:
        adapter: undefined
        options: undefined
      outbound:
        adapter: undefined
        options: undefined
      meta:     {}

    if @channel
      @account =
        inbound: clone(@channel.options.inbound)
        outbound: clone(@channel.options.outbound)

      # remember passwords, do not show in ui
      if @account.inbound && @account.inbound.options && @account.inbound.options.password
        @inboundPassword = @account.inbound.options.password
        @account.inbound.options.password = @passwordPlaceholder
      if @account.outbound && @account.outbound.options && @account.outbound.options.password
        @outboundPassword = @account.outbound.options.password
        @account.outbound.options.password = @passwordPlaceholder

    if @container
      @el.addClass('modal--local')

    @render()

    @el.modal(
      keyboard:  true
      show:      true
      backdrop:  true
      container: @container
    ).on(
      'show.bs.modal':   @onShow
      'shown.bs.modal':  @onShown
      'hidden.bs.modal': =>
        if @callback
          @callback()
        @el.remove()
    )
    if @slide
      @showSlide(@slide)

  render: =>
    @html App.view('channel/email_notification_wizard')()
    @showSlide('js-outbound')

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
        adapter: @account.outbound.adapter || 'sendmail'
    )
    @toggleOutboundAdapter()

  toggleOutboundAdapter: =>

    # show used backend
    @el.find('.base-outbound-settings').html('')
    adapter = @$('.js-outbound [name=adapter]').val()
    if adapter is 'smtp'
      configureAttributesOutbound = [
        { name: 'options::host',     display: 'Host',     tag: 'input', type: 'text',     limit: 120, null: false, autocapitalize: false, autofocus: true },
        { name: 'options::user',     display: 'User',     tag: 'input', type: 'text',     limit: 120, null: true, autocapitalize: false, autocomplete: 'off' },
        { name: 'options::password', display: 'Password', tag: 'input', type: 'password', limit: 120, null: true, autocapitalize: false, autocomplete: 'new-password', single: true },
        { name: 'options::port',     display: 'Port',     tag: 'input', type: 'text',     limit: 6,   null: true, autocapitalize: false },
      ]
      @form = new App.ControllerForm(
        el:    @$('.base-outbound-settings')
        model:
          configure_attributes: configureAttributesOutbound
          className: ''
        params: @account.outbound
      )

  probleOutbound: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)

    if params.options && params.options.password is @passwordPlaceholder
      params.options.password = @outboundPassword

    # let backend know about the channel
    params.channel_id = @channel.id

    @disable(e)

    @showSlide('js-test')

    @ajax(
      id:   'email_outbound'
      type: 'POST'
      url:  "#{@apiPath}/channels_email_notification"
      data: JSON.stringify(params)
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'
          @el.modal('hide')
        else
          @showSlide('js-outbound')
          @showAlert('js-outbound', data.message_human || data.message)
          @showInvalidField('js-outbound', data.invalid_field)
        @enable(e)
      error: (xhr) =>
        data = JSON.parse(xhr.responseText)
        @showSlide('js-outbound')
        @showAlert('js-outbound', data.message_human || data.message || data.error)
        @showInvalidField('js-outbound', data.invalid_field)
        @enable(e)
    )

App.Config.set('Email', { prio: 3000, name: 'Email', parent: '#channels', target: '#channels/email', controller: ChannelEmail, permission: ['admin.channel_email'] }, 'NavBarAdmin')
