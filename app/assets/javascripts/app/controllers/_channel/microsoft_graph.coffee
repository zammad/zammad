class App.ChannelMicrosoftGraph extends App.ControllerTabs
  @requiredPermission: 'admin.channel_microsoft_graph'

  header: __('Microsoft 365 Graph Email')

  constructor: ->
    super

    @title __('Microsoft 365 Graph Email'), true

    @tabs = [
      {
        name:       __('Accounts'),
        target:     'c-account',
        controller: ChannelAccountOverview,
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


class ChannelAccountOverview extends App.ControllerSubContent
  @requiredPermission: 'admin.channel_microsoft_graph'

  events:
    'click .js-new':                'new'
    'click .js-admin-consent':      'adminConsent'
    'click .js-editInbound':        'editInbound'
    'click .js-configApp':          'configApp'
    'click .js-delete':             'delete'
    'click .js-reauthenticate':     'reauthenticate'
    'click .js-disable':            'disable'
    'click .js-enable':             'enable'
    'click .js-emailAddressNew':    'emailAddressNew'
    'click .js-emailAddressEdit':   'emailAddressEdit'
    'click .js-emailAddressDelete': 'emailAddressDelete',
    'click .js-channelGroupChange': 'groupChange'

  constructor: ->
    super

    @interval(@load, 30000)
    @load()

  load: (reset_channel_id = false) =>
    if reset_channel_id
      @channel_id = undefined
      @navigate '#channels/microsoft_graph'

    @startLoading()
    @ajax(
      id:   'microsoft_graph_index'
      type: 'GET'
      url:  "#{@apiPath}/channels/admin/microsoft_graph"
      processData: true
      success: (data, status, xhr) =>
        @stopLoading()
        App.Collection.loadAssets(data.assets)
        @callbackUrl = data.callback_url
        @render(data)
    )

  new: (e) ->
    new ChannelInboundNew(
      container: @el.closest('.content')
    )

  adminConsent: (e) ->
    window.location.href = "#{@apiPath}/external_credentials/microsoft_graph/link_account?prompt=consent"

  delete: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    new App.ControllerConfirm(
      message:     __('Are you sure?')
      buttonClass: 'btn--danger'
      callback: =>
        @ajax(
          id:   'microsoft_graph_delete'
          type: 'DELETE'
          url:  "#{@apiPath}/channels/admin/microsoft_graph/#{id}"
          processData: true
          success: =>
            @load()
        )
      container: @el.closest('.content')
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

  groupChange: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    item = App.Channel.find(id)
    new ChannelGroupEdit(
      container: @el.closest('.content')
      item: item
      callback: @load
    )

  reauthenticate: (e) =>
    e.preventDefault()
    id                   = $(e.target).closest('.action').data('id')
    window.location.href = "#{@apiPath}/external_credentials/microsoft_graph/link_account?channel_id=#{id}"

  disable: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    @ajax(
      id:   'microsoft_graph_disable'
      type: 'POST'
      url:  "#{@apiPath}/channels/admin/microsoft_graph/#{id}/disable"
      processData: true
      success: =>
        @load()
    )

  enable: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    @ajax(
      id:   'microsoft_graph_enable'
      type: 'POST'
      url:  "#{@apiPath}/channels/admin/microsoft_graph/#{id}/enable"
      processData: true
      success: =>
        @load()
    )

  render: (data) =>
    # if no microsoft graph app is registered, show intro
    external_credential = App.ExternalCredential.findByAttribute('name', 'microsoft_graph')

    if !external_credential
      @html App.view('microsoft_graph/index')()
      if @channel_id
        @configApp()
      return

    channels = []

    for channel_id in data.channel_ids
      channel = App.Channel.find(channel_id)
      if channel.group_id
        channel.group = App.Group.find(channel.group_id)
      else
        channel.group = '-'

      email_addresses = App.EmailAddress.search(filter: { channel_id: channel.id })
      channel.email_addresses = email_addresses

      channels.push channel

    # get all unlinked email addresses
    not_used_email_addresses = []
    for email_address_id in data.not_used_email_address_ids
      not_used_email_addresses.push App.EmailAddress.find(email_address_id)

    @html App.view('microsoft_graph/list')(
      channels: channels
      external_credential: external_credential
      not_used_email_addresses: not_used_email_addresses
    )

    # On a channel creation we will auto open the edit dialog after the redirect back to zammad to optional
    # change the inbound configuration.
    if @channel_id
      item = App.Channel.find(@channel_id)
      if item && item.area == 'MicrosoftGraph::Account' && item.options && item.options.backup_imap_classic is undefined && not @error_code
        @editInbound(undefined, @channel_id, true, true)
        @channel_id = undefined

    if @error_code is 'AADSTS65004'
      @error_code = undefined
      new App.AdminConsentInfo(container: @container, type: 'microsoft_graph')

    if @error_code is 'user_mismatch'
      @error_code = undefined
      new App.UserMismatchInfo(container: @container, type: 'microsoft_graph', item: item)

    if @error_code is 'duplicate_email_address'
      @error_code = undefined
      new App.DuplicateEmailAddressInfo(container: @container, type: 'microsoft_graph', emailAddress: if @param then decodeURIComponent(@param))

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

  configApp: =>
    new AppConfig(
      container: @el.parents('.content')
      callbackUrl: @callbackUrl
      load: @load
    )

  editInbound: (e, channel_id, set_active, redirect = false) =>
    if !channel_id
      e.preventDefault()
      channel_id = $(e.target).closest('.action').data('id')
    item = App.Channel.find(channel_id)
    new ChannelInboundEdit(
      container: @el.closest('.content')
      item: item
      callback: @load
      set_active: set_active
      redirect: redirect
    )

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
      url:  "#{@apiPath}/channels/admin/microsoft_graph/group/#{@item.id}"
      data: JSON.stringify(params)
      processData: true
      success: (data, status, xhr) =>
        @callback()
        @close()
      error: (xhr) =>
        data = JSON.parse(xhr.responseText)
        @formEnable(e)
        @el.find('.alert--danger').removeClass('hide').text(data.error || __('The changes could not be saved.'))
    )

class AppConfig extends App.ControllerModal
  head: __('Connect Microsoft 365 App')
  shown: true
  button: __('Connect')
  buttonCancel: true
  small: true
  events:
    'click .js-copy': 'copyToClipboard'

  content: ->
    @external_credential = App.ExternalCredential.findByAttribute('name', 'microsoft_graph')
    content = $(App.view('microsoft_graph/app_config')(
      external_credential: @external_credential
      callbackUrl: @callbackUrl
    ))
    content.find('.js-select').on('click', (e) =>
      @selectAll(e)
    )
    content

  copyToClipboard: (e) =>
    e.preventDefault()

    button = $(e.target).parents('[role="button"]')
    field_name = button.data('targetField')
    value = $(@container).find("input[name='#{jQuery.escapeSelector(field_name)}']").val()

    @copyToClipboardWithTooltip(value, e.target,'.modal-body', true)

  onClosed: =>
    return if !@isChanged
    @isChanged = false
    @load()

  onSubmit: (e) =>
    @formDisable(e)

    # verify app credentials
    @ajax(
      id:   'microsoft_graph_app_verify'
      type: 'POST'
      url:  "#{@apiPath}/external_credentials/microsoft_graph/app_verify"
      data: JSON.stringify(@formParams())
      processData: true
      success: (data, status, xhr) =>
        if data.attributes
          if !@external_credential
            @external_credential = new App.ExternalCredential
          @external_credential.load(name: 'microsoft_graph', credentials: data.attributes)
          @external_credential.save(
            done: =>
              @isChanged = true
              @close()
            fail: =>
              @el.find('.alert--danger').removeClass('hide').text(__('The entry could not be created.'))
          )
          return
        @formEnable(e)
        @el.find('.alert--danger').removeClass('hide').text((data && data.error) || __('App could not be verified.'))
    )

class ChannelInboundNew extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: __('Authenticate')
  head: __('Channel')

  content: =>
    configureAttributesBase = [
      { name: 'mailbox_type',   display: __('Mailbox type'),   tag: 'select', options: { user: __('User mailbox'), shared: __('Shared mailbox') }, translate: true, null: false, value: 'user' },
      { name: 'shared_mailbox', display: __('Shared mailbox'), tag: 'input', type: 'email', limit: 120, null: true, placeholder: __('user@your-organization.tld'), hide: true },
    ]
    @form = new App.ControllerForm(
      model:
        configure_attributes: configureAttributesBase
        className: ''
      handlers: [
        App.FormHandlerChannelAccountMailboxType.run
      ]
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

    query_string = if params.shared_mailbox then "?shared_mailbox=#{encodeURIComponent(params.shared_mailbox)}" else ''

    window.location.href = "#{@apiPath}/external_credentials/microsoft_graph/link_account#{query_string}"

class ChannelInboundEdit extends App.ControllerModal
  @include App.DestinationGroupEmailAddressesMixin

  buttonClose: true
  buttonCancel: true
  buttonSubmit: __('Save')
  head: __('Channel')

  constructor: ->
    super
    @fetch()

  fetch: =>
    @startLoading()
    @ajax(
      id:   'microsoft_graph_folders'
      type: 'GET'
      url:  "#{@apiPath}/channels/admin/microsoft_graph/#{@item.id}/folders"
      processData: true
      success: (data, status, xhr) =>
        @folderOptions = if data.folders then _.reduce(data.folders, @transformFolders, []) else []

        @error = if data.error
                   message: data.error.message,
                   hint: @errorCodeLookup(data.error.code)

        @stopLoading()
        @render()
      error: (error) =>
        @stopLoading()
        @close()
    )

  transformFolders: (memo, folder) =>
    children = if _.isArray(folder.childFolders) and folder.childFolders.length then _.reduce(folder.childFolders, @transformFolders, [])

    memo.push({
      value: folder.id,
      name: folder.displayName,
      children: children,
    })

    memo

  errorCodeLookup: (code) ->
    switch code
      when 'MailboxNotEnabledForRESTAPI'
        __('Did you verify that the user has access to the mailbox? Or consider removing this channel and switch to using a different mailbox type. %l')
      when 'ErrorItemNotFound'
        __('Did you confirm that the user has delegation permissions for the mailbox? Or consider removing this channel and switch to using a different mailbox type. %l')
      when 'ErrorInvalidUser'
        __('Did you check the validity of the configured mailbox? Or consider removing this channel and switch to using a different mailbox type. %l')
      else
        null

  content: =>
    if @error
      @buttonSubmit = false
      return App.view('microsoft_graph/error_message')(error: @error)

    configureAttributesBase = [
      { name: 'group_id',                display: __('Destination Group'),       tag: 'tree_select', null: false, relation: 'Group', filter: { active: true } },
      { name: 'group_email_address_id',  display: __('Destination group > Sending email address'), tag: 'select', null: false, options: @emailAddressOptions(@item.id, @item.group_id), note: __("This will adjust the corresponding setting of the destination group within the group management. A group's email address determines which address should be used for outgoing mails, e.g. when an agent is composing an email or a trigger is sending an auto-reply.") },
      { name: 'options::folder_id',      display: __('Folder'),                  tag: 'tree_select', null: true, options: @folderOptions, nulloption: true, default: '', help: __('Specify which folder to fetch from, or leave empty to fetch from ||inbox||.') },
      { name: 'options::keep_on_server', display: __('Keep messages on server'), tag: 'boolean', null: true, options: { true: 'yes', false: 'no' }, translate: true, default: false },
    ]
    @form = new App.ControllerForm(
      model:
        configure_attributes: configureAttributesBase
        className: ''
      params:
        group_id: @item.group_id,
        options:
          folder_id: @item.options.inbound.options.folder_id,
          keep_on_server: @item.options.inbound.options.keep_on_server,
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

    data =
      options: params.options

    # disable form
    @formDisable(e)

    @startLoading()

    # probe
    @ajax(
      id:   'channel_email_inbound'
      type: 'POST'
      url:  "#{@apiPath}/channels/admin/microsoft_graph/inbound/#{@item.id}"
      data: JSON.stringify(data)
      processData: true
      success: (data, status, xhr) =>
        if data.content_messages or not @set_active
          new App.ChannelInboundEmailArchive(
            container: @el.closest('.content')
            item: @item
            set_active: @set_active
            content_messages: data.content_messages
            inboundParams: params
            callback: @verify
          )
          @close()
          return

        @verify(params)

      error: (xhr) =>
        data = JSON.parse(xhr.responseText)
        @stopLoading()
        @formEnable(e)
        @el.find('.alert--danger').removeClass('hide').text(data.error_human || data.error || __('The changes could not be saved.'))
    )

  verify: (params = {}) =>
    @startLoading()

    if @set_active
      params['active'] = true

    @processDestinationGroupEmailAddressParams(params)

    # update
    @ajax(
      id:   'channel_email_verify'
      type: 'POST'
      url:  "#{@apiPath}/channels/admin/microsoft_graph/verify/#{@item.id}"
      data: JSON.stringify(params)
      processData: true
      success: (data, status, xhr) =>
        @callback(true)
        @close()
      error: (xhr) =>
        data = JSON.parse(xhr.responseText)
        @stopLoading()
        @el.find('.alert--danger').removeClass('hide').text(data.error_human || data.error || __('The changes could not be saved.'))
    )

  onCancel: =>
    return if not @redirect

    @navigate '#channels/microsoft_graph'

App.Config.set('microsoftGraph', { prio: 5100, name: __('Microsoft 365 Graph Email'), parent: '#channels', target: '#channels/microsoft_graph', controller: App.ChannelMicrosoftGraph, permission: ['admin.channel_microsoft_graph'] }, 'NavBarAdmin')
