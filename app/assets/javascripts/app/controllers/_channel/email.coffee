class ChannelEmail extends App.ControllerTabs
  @requiredPermission: 'admin.channel_email'
  header: __('Email')
  constructor: ->
    super

    @title __('Email'), true

    @tabs = [
      {
        name:       __('Accounts'),
        target:     'c-account',
        controller: ChannelEmailAccountOverview,
      },
      {
        name:       __('Filter'),
        target:     'c-filter',
        controller: App.ChannelEmailFilter,
      },
      {
        name:       __('Signatures'),
        target:     'c-signature',
        controller: App.ChannelEmailSignature,
      },
      {
        name:       __('Settings'),
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
      message:     __('Are you sure?')
      buttonClass: 'btn--danger'
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
    new ChannelGroupEdit(
      container: @el.closest('.content')
      item: item
      callback: @load
    )

  emailAddressNew: (e) =>
    e.preventDefault()
    channel_id = $(e.target).closest('.action').data('id')
    new App.ControllerGenericNew(
      pageData:
        object: __('Email Address')
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
        object: __('Email Address')
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

class ChannelGroupEdit extends App.ControllerModal
  @include App.DestinationGroupEmailAddressesMixin

  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: __('Channel')

  content: =>
    configureAttributesBase = [
      { name: 'group_id',               display: __('Destination Group'), tag: 'tree_select', null: false, relation: 'Group', filter: { active: true } },
      { name: 'group_email_address_id', display: __('Destination group > Sending email address'), tag: 'select', options: @emailAddressOptions(@item.id, @item.group_id), note: __("This will adjust the corresponding setting of the destination group within the group management. A group's email address determines which address should be used for outgoing mails, e.g. when an agent is composing an email or a trigger is sending an auto-reply.") },
    ]

    @form = new App.ControllerForm(
      model:
        configure_attributes: configureAttributesBase
        className: ''
      params: @item
      handlers: [@destinationGroupEmailAddressFormHandler(@item)]
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

    @processDestinationGroupEmailAddressParams(params)

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
        @el.find('.alert').removeClass('hidden').text(data.error || __('The changes could not be saved.'))
    )

class ChannelEmailAccountWizard extends App.ControllerWizardModal
  @include App.DestinationGroupEmailAddressesMixin

  elements:
    '.modal-body': 'body'
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
    'click  .js-expert':                   'probeBasedOnIntro'
    'click  .js-close':                    'hide'
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
      'shown.bs.modal': =>
        @el.addClass('modal--ready')
    )

    if @slide
      @showSlide(@slide)

  render: =>
    @html App.view('channel/email_account_wizard')()
    @showSlide('js-intro')

    # base
    configureAttributesBase = [
      { name: 'realname',               display: __('Organization & Department Name'), tag: 'input',  type: 'text', limit: 160, null: false, placeholder: __('Organization Support'), autocomplete: 'off' },
      { name: 'email',                  display: __('Email'),    tag: 'input',  type: 'email', limit: 120, null: false, placeholder: 'support@example.com', autocapitalize: false, autocomplete: 'off' },
      { name: 'password',               display: __('Password'), tag: 'input',  type: 'password', limit: 120, null: false, autocapitalize: false, autocomplete: 'new-password', single: true },
      { name: 'group_id',               display: __('Destination Group'), tag: 'tree_select', null: false, relation: 'Group', filter: { active: true } },
      { name: 'group_email_address_id', display: __('Destination group > Sending email address'), tag: 'select', null: false, options: @emailAddressOptions(@channel?.id, @channel?.group_id), note: __("This will adjust the corresponding setting of the destination group within the group management. A group's email address determines which address should be used for outgoing mails, e.g. when an agent is composing an email or a trigger is sending an auto-reply.") },
    ]

    @formMeta = new App.ControllerForm(
      el:    @$('.base-settings'),
      model:
        configure_attributes: configureAttributesBase
        className: ''
      params: @account.meta
      handlers: [@destinationGroupEmailAddressFormHandler()]
    )

    # outbound
    configureAttributesOutbound = [
      { name: 'adapter', display: __('Send Mails via'), tag: 'select', multiple: false, null: false, options: @channelDriver.email.outbound, translate: true },
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

    @initializeInboundForm(@account)

  initializeInboundForm: (params) =>
    configureAttributesInbound = [
      { name: 'group_id',                display: __('Destination Group'), tag: 'tree_select', null: false, relation: 'Group', filter: { active: true } },
      { name: 'group_email_address_id',  display: __('Destination group > Sending email address'), tag: 'select', null: false, options: @emailAddressOptions(@channel?.id, @channel?.group_id), note: __("This will adjust the corresponding setting of the destination group within the group management. A group's email address determines which address should be used for outgoing mails, e.g. when an agent is composing an email or a trigger is sending an auto-reply.") },
      { name: 'adapter',                 display: __('Type'),     tag: 'select', multiple: false, null: false, options: @channelDriver.email.inbound, translate: true },
      { name: 'options::host',           display: __('Host'),     tag: 'input',  type: 'text', limit: 120, null: false, autocapitalize: false },
      { name: 'options::user',           display: __('User'),     tag: 'input',  type: 'text', limit: 120, null: false, autocapitalize: false, autocomplete: 'off' },
      { name: 'options::password',       display: __('Password'), tag: 'input',  type: 'password', limit: 120, null: false, autocapitalize: false, autocomplete: 'new-password', single: true },
      { name: 'options::ssl',            display: __('SSL/STARTTLS'), tag: 'select', null: true, options: { 'off': __('No SSL'), 'ssl': __('SSL'), 'starttls': __('STARTTLS')  }, default: 'ssl', translate: true, item_class: 'formGroup--halfSize' },
      { name: 'options::ssl_verify',     display: __('SSL verification'), tag: 'boolean', default: true, null: true, translate: true, item_class: 'formGroup--halfSize' },
      { name: 'options::port',           display: __('Port'),     tag: 'input',  type: 'text', limit: 6,   null: true, autocapitalize: false,  default: '993', item_class: 'formGroup--halfSize' },
      { name: 'options::folder',         display: __('Folder'),   tag: 'input',  type: 'text', limit: 120, null: true, autocapitalize: false, item_class: 'formGroup--halfSize' },
      { name: 'options::keep_on_server', display: __('Keep messages on server'), tag: 'boolean', null: true, options: { true: 'yes', false: 'no' }, translate: true, default: false, item_class: 'formGroup--halfSize' },
    ]

    # If email inbound form is opened from the new email wizard, show additional fields on top.
    if !@channel
      configureAttributesInbound = [
        { name: 'options::realname', display: __('Organization & Department Name'), tag: 'input',  type: 'text', limit: 160, null: false, placeholder: __('Organization Support'), autocomplete: 'off' },
        { name: 'options::email',    display: __('Email'),    tag: 'input',  type: 'email', limit: 120, null: false, placeholder: 'support@example.com', autocapitalize: false, autocomplete: 'off' },
      ].concat(configureAttributesInbound)

    showHideFolder = (params, attribute, attributes, classname, form, ui) ->
      return if !params
      if params.adapter is 'imap'
        ui.show('options::folder')
        ui.show('options::keep_on_server')
        return
      ui.hide('options::folder')
      ui.hide('options::keep_on_server')

    @form = new App.ControllerForm(
      elReplace: @$('.base-inbound-settings'),
      model:
        configure_attributes: configureAttributesInbound
        className: ''
      params: _.extend(
        params.inbound or {
          options:
            user: params.email
            password: params.password
            email: params.email
            realname: params.realname
        }
        group_id: params?.meta?.group_id or params.group_id or @channel?.group_id
        group_email_address_id: params?.meta?.group_email_address_id or params.group_email_address_id
      )
      handlers: [
        showHideFolder
        @destinationGroupEmailAddressFormHandler(@channel)
      ]
    )

    @toggleInboundAdapter()
    @toggleInboundPort()

  toggleInboundPort: =>
    form = @$('.base-inbound-settings')

    form.find("select[name='options::ssl']").off('change').on('change', (e) ->
      if $(e.target).val() is 'ssl'
        form.find("[name='options::port']").val('993')
      else if $(e.target).val() is 'off'
        form.find("[name='options::port']").val('143')
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
        { name: 'options::host',       display: __('Host'),       tag: 'input',  type: 'text',     limit: 120, null: false, autocapitalize: false, autofocus: true },
        { name: 'options::user',       display: __('User'),       tag: 'input',  type: 'text',     limit: 120, null: true, autocapitalize: false, autocomplete: 'off', },
        { name: 'options::password',   display: __('Password'),   tag: 'input',  type: 'password', limit: 120, null: true, autocapitalize: false, autocomplete: 'new-password', single: true },
        { name: 'options::port',       display: __('Port'),       tag: 'input',  type: 'text',     limit: 6,   null: true, autocapitalize: false, item_class: 'formGroup--halfSize' },
        { name: 'options::ssl_verify', display: __('SSL verification'), tag: 'boolean', default: true, null: true, translate: true, item_class: 'formGroup--halfSize' },
      ]
      @form = new App.ControllerForm(
        el:    @$('.base-outbound-settings')
        model:
          configure_attributes: configureAttributesOutbound
          className: ''
        params: @account.outbound
      )

  toggleSslVerifyVisibility: (e) ->
    elem      = $(e.target)

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

    elem.closest('.modal-content')
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

  probeBasedOnIntro: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)

    if not $(e.currentTarget).hasClass('js-expert')

      # validate form
      errors = @formMeta.validate(params)

      # show errors in form
      if errors
        @log 'error', errors
        @formValidate(form: e.target, errors: errors)
        return false

    # remember account settings
    @account.meta = params

    # let backend know about the channel
    if @channel
      params.channel_id = @channel.id

    if $(e.currentTarget).hasClass('js-expert')
      @initializeInboundForm(params)
      @showSlide('js-inbound')
      return

    @disable(e)
    @$('.js-probe .js-email').text(params.email)
    @showSlide('js-probe')

    data = _.pick(params, 'email', 'password')

    @ajax(
      id:   'email_probe'
      type: 'POST'
      url:  "#{@apiPath}/channels_email_probe"
      data: JSON.stringify(data)
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
          @showAlert('js-intro', __('Account already exists!'))
        else
          @initializeInboundForm(params)
          @showSlide('js-inbound')
          @showAlert('js-inbound', __('The server settings could not be automatically detected. Please configure them manually.'))

        @enable(e)
      error: =>
        @enable(e)
        @showSlide('js-intro')
    )

  probeInbound: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)

    # validate form
    errors = @form.validate(params)

    # show errors in form
    if errors
      @log 'error', errors
      @formValidate(form: e.target, errors: errors)
      return false

    if params.options && params.options.password is @passwordPlaceholder
      params.options.password = @inboundPassword

    # Update meta as the one from AttributesBase could be outdated
    @account.meta.realname = params.options.realname
    @account.meta.email = params.options.email
    @account.meta.group_id = params.group_id
    @account.meta.group_email_address_id = params.group_email_address_id
    delete params.group_id
    delete params.group_email_address_id

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

          if data.content_messages or @channel
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

  probeInboundArchive: (data, verify = false) =>
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

    options =
      archive_before: @channel?.options.inbound.options.archive_before
      archive_state_id: if @channel?.options.inbound.options.archive_state_id then parseInt(@channel.options.inbound.options.archive_state_id, 10)

    # Honour the archive flag, if channel is already configured.
    options.archive = @channel.options?.inbound?.options?.archive or false if @channel

    form = new App.ControllerForm(
      elReplace: @$('.js-archiveSettings'),
      model:
        configure_attributes: configureAttributesAcknowledge
        className: ''
      handlers: [
        App.FormHandlerChannelAccountArchiveMode.run
        App.FormHandlerChannelAccountArchiveBefore.run
      ]
      params: options
    )

    verifyCallback = =>
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
      @account.inbound.options = _.extend(@account.inbound.options, params)

      verifyCallback()
    )

    @$('.js-inbound-acknowledge .js-skip').off('click.skip').on('click.skip', (e) =>
      e.preventDefault()

      @account.inbound         ||= {}
      @account.inbound.options ||= {}
      @account.inbound.options = _.extend(@account.inbound.options, options)

      verifyCallback()
    )

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

    sslVerifyField = $(e.target).closest('form').find('[name="options::ssl_verify"]')

    if sslVerifyField[0]?.disabled
      params.options.ssl_verify = false

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

    # use jquery instead of ._clone() because we need a deep copy of the obj
    params = $.extend({}, account)

    # let backend know about the channel
    if @channel
      params.channel_id = @channel.id

    if params.meta?.group_id
      params.group_id = params.meta.group_id
    else if @channel?.group_id
      params.group_id = @channel.group_id

    # Copy group email address parameter from meta key to the root.
    if not _.isUndefined(params.meta?.group_email_address_id)
      params.group_email_address = params.meta.group_email_address_id isnt 'false'

      if params.group_email_address and params.meta.group_email_address_id isnt 'true'
        params.group_email_address_id = params.meta.group_email_address_id

    if !params.email && @channel
      email_addresses = App.EmailAddress.search(filter: { channel_id: @channel.id })
      if email_addresses && email_addresses[0]
        params.email = email_addresses[0].email

    if params.inbound?.options?.password is @passwordPlaceholder
      params.inbound.options.password = @inboundPassword
    if params.outbound?.options?.password is @passwordPlaceholder
      params.outbound.options.password = @outboundPassword

    @ajax(
      id:   'email_verify'
      type: 'POST'
      url:  "#{@apiPath}/channels_email_verify"
      data: JSON.stringify(params)
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
                  nextSlide = if @channel then 'js-inbound' else 'js-intro'

                  @showSlide(nextSlide)
                  @showAlert(nextSlide, __('Email sending and receiving could not be verified. Please check your settings.'))

                2300
              )
            else
              if data.subject && @account
                @account.subject = data.subject
              @verify(@account, count + 1)
      error: =>
        nextSlide = if @channel then 'js-inbound' else 'js-intro'

        @showSlide('js-intro')
        @showAlert('js-intro', __('Email sending and receiving could not be verified. Please check your settings.'))
    )

  hide: (e) =>
    e.preventDefault()
    @el.modal('hide')

class ChannelEmailNotificationWizard extends App.ControllerWizardModal
  elements:
    '.modal-body': 'body'
  events:
    'change [name="options::ssl_verify"]': 'toggleSslVerifyAlert'
    'change [name="options::port"]':       'toggleSslVerifyVisibility'
    'change .js-outbound [name=adapter]':  'toggleOutboundAdapter'
    'submit .js-outbound':                 'probleOutbound'
    'click  .js-close':                    'hide'
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
    @toggleSslVerifyAlert(target: @el.find('[name="options::ssl_verify"]'))

    @el.modal(
      keyboard:  true
      show:      true
      backdrop:  true
      container: @container
    ).on(
      'show.bs.modal':   @onShow
      'shown.bs.modal': =>
        @el.addClass('modal--ready')
        @onShown() if @onShown
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
      { name: 'adapter', display: __('Send Mails via'), tag: 'select', multiple: false, null: false, options: @channelDriver.email.outbound, translate: true },
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
        { name: 'options::host',       display: __('Host'),     tag: 'input', type: 'text',     limit: 120, null: false, autocapitalize: false, autofocus: true },
        { name: 'options::user',       display: __('User'),     tag: 'input', type: 'text',     limit: 120, null: true, autocapitalize: false, autocomplete: 'off' },
        { name: 'options::password',   display: __('Password'), tag: 'input', type: 'password', limit: 120, null: true, autocapitalize: false, autocomplete: 'new-password', single: true },
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

    elem.closest('.modal-content')
      .find('.js-sslVerifyAlert')
      .toggleClass('hide', !isAlertVisible)

  probleOutbound: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)

    if params.options && params.options.password is @passwordPlaceholder
      params.options.password = @outboundPassword

    # let backend know about the channel
    params.channel_id = @channel.id

    sslVerifyField = $(e.target).closest('form').find('[name="options::ssl_verify"]')

    if sslVerifyField[0]?.disabled
      params.options.ssl_verify = false

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

App.Config.set('Email', { prio: 3000, name: __('Email'), parent: '#channels', target: '#channels/email', controller: ChannelEmail, permission: ['admin.channel_email'] }, 'NavBarAdmin')
