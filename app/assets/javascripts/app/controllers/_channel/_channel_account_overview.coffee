# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class App.ChannelAccountOverview extends App.ControllerSubContent
  events:
    'click .js-new':                'new'
    'click .js-admin-consent':      'adminConsent'
    'click .js-delete':             'delete'
    'click .js-reauthenticate':     'reauthenticate'
    'click .js-configApp':          'configApp'
    'click .js-disable':            'disable'
    'click .js-enable':             'enable'
    'click .js-channelGroupChange': 'groupChange'
    'click .js-editInbound':        'editInbound'
    'click .js-rollbackMigration':  'rollbackMigration'
    'click .js-emailAddressNew':    'emailAddressNew'
    'click .js-emailAddressEdit':   'emailAddressEdit'
    'click .js-emailAddressDelete': 'emailAddressDelete'

  constructor: ->
    super

    if !@channelKey
      throw 'App.ChannelAccountOverview requires a channelKey param'

    @interval(@load, 30000)

  # URL builders -------------------------------------------------------------

  indexUrl: ->
    if @legacyUrls
      "#{@apiPath}/channels_#{@channelKey}"
    else
      "#{@apiPath}/channels/admin/#{@channelKey}"

  deleteUrl: (id) ->
    if @legacyUrls
      "#{@apiPath}/channels_#{@channelKey}"
    else
      "#{@apiPath}/channels/admin/#{@channelKey}/#{id}"

  disableUrl: (id) ->
    if @legacyUrls
      "#{@apiPath}/channels_#{@channelKey}_disable"
    else
      "#{@apiPath}/channels/admin/#{@channelKey}/#{id}/disable"

  enableUrl: (id) ->
    if @legacyUrls
      "#{@apiPath}/channels_#{@channelKey}_enable"
    else
      "#{@apiPath}/channels/admin/#{@channelKey}/#{id}/enable"

  rollbackUrl: ->
    "#{@apiPath}/channels_#{@channelKey}_rollback_migration"

  linkAccountUrl: (queryString = '') ->
    "#{@apiPath}/external_credentials/#{@channelKey}/link_account#{queryString}"

  # Data loading & rendering -------------------------------------------------

  load: (reset_channel_id = false) =>
    if reset_channel_id
      @channel_id = undefined
      @navigate "#channels/#{@channelKey}"

    @startLoading()
    @ajax(
      id:   "#{@channelKey}_index"
      type: 'GET'
      url:  @indexUrl()
      processData: true
      success: (data, status, xhr) =>
        @stopLoading()
        App.Collection.loadAssets(data.assets)
        @callbackUrl = data.callback_url
        @render(data)
    )

  shouldRenderIntro: (external_credential, data) ->
    !external_credential

  channelNeedsReauthentication: (channel, external_credential) ->
    current_client_id = external_credential?.credentials?.client_id
    return false if !current_client_id
    current_client_id isnt channel.options?.auth?.client_id

  render: (data) =>

    # If no app is registered, show the intro page.
    external_credential = App.ExternalCredential.findByAttribute('name', @externalCredentialName)
    if @shouldRenderIntro(external_credential, data)
      @html App.view("#{@viewNamespace}/index")()
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

      channel.needs_reauthentication = @channelNeedsReauthentication(channel, external_credential)

      channels.push channel

    # On a channel migration, redirect to the "Add Account" flow after
    # the external credentials have been provided.
    if @hasMigrationRedirect and @channel_id
      item = App.Channel.find(@channel_id)
      if item && item.area != @channelAreaName
        @new()
        return

    not_used_email_addresses = []
    for email_address_id in data.not_used_email_address_ids
      not_used_email_addresses.push App.EmailAddress.find(email_address_id)

    @html App.view('channel_account/list')(
      channels: channels
      external_credential: external_credential
      not_used_email_addresses: not_used_email_addresses
      has_admin_consent: @hasAdminConsent
      has_mailbox_info: @hasMailboxInfo
      rollback_button_first: @rollbackButtonFirst
    )

    # On a channel creation, auto-open the edit dialog so the user can
    # adjust the inbound configuration. Skip for migrated channels — their
    # configuration is assumed to be correct.
    if @channel_id
      item = App.Channel.find(@channel_id)
      if item && item.area == @channelAreaName && item.options && item.options.backup_imap_classic is undefined && not @error_code
        @editInbound(undefined, @channel_id, true, @hasInboundEditRedirect)
        @channel_id = undefined

    return if !@hasErrorCodeHandling

    switch @error_code
      when 'AADSTS65004'
        @error_code = undefined
        new App.AdminConsentInfo(container: @container, type: @channelKey)
      when 'user_mismatch'
        @error_code = undefined
        new App.UserMismatchInfo(container: @container, type: @channelKey, item: item)
      when 'duplicate_email_address'
        @error_code = undefined
        new App.DuplicateEmailAddressInfo(container: @container, type: @channelKey, emailAddress: if @param then decodeURIComponent(@param))

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

  configApp: =>
    new @appConfigClass(
      container: @el.parents('.content')
      callbackUrl: @callbackUrl
      load: @load
    )

  # Actions ------------------------------------------------------------------

  new: (e) =>
    if @inboundNewClass
      new @inboundNewClass(
        container: @el.closest('.content')
      )
      return

    window.location.href = @linkAccountUrl()

  adminConsent: (e) =>
    window.location.href = @linkAccountUrl('?prompt=consent')

  delete: (e) =>
    e.preventDefault()
    id = $(e.target).closest('.action').data('id')
    new App.ControllerConfirm(
      message:     __('Are you sure?')
      buttonClass: 'btn--danger'
      callback: =>
        ajaxOptions =
          id:          "#{@channelKey}_delete"
          type:        'DELETE'
          url:         @deleteUrl(id)
          processData: true
          success: =>
            @load()
        if @legacyUrls
          ajaxOptions.data = JSON.stringify(id: id)
        @ajax(ajaxOptions)
      container: @el.closest('.content')
    )

  reauthenticate: (e) =>
    e.preventDefault()
    id = $(e.target).closest('.action').data('id')
    window.location.href = @linkAccountUrl("?channel_id=#{id}")

  disable: (e) =>
    e.preventDefault()
    id = $(e.target).closest('.action').data('id')
    ajaxOptions =
      id:          "#{@channelKey}_disable"
      type:        'POST'
      url:         @disableUrl(id)
      processData: true
      success: =>
        @load()
    if @legacyUrls
      ajaxOptions.data = JSON.stringify(id: id)
    @ajax(ajaxOptions)

  enable: (e) =>
    e.preventDefault()
    id = $(e.target).closest('.action').data('id')
    ajaxOptions =
      id:          "#{@channelKey}_enable"
      type:        'POST'
      url:         @enableUrl(id)
      processData: true
      success: =>
        @load()
    if @legacyUrls
      ajaxOptions.data = JSON.stringify(id: id)
    @ajax(ajaxOptions)

  editInbound: (e, channel_id, set_active, redirect = false) =>
    if !channel_id
      e.preventDefault()
      channel_id = $(e.target).closest('.action').data('id')
    item = App.Channel.find(channel_id)
    new @inboundEditClass(
      container:  @el.closest('.content')
      item:       item
      callback:   @load
      set_active: set_active
      redirect:   redirect
    )

  rollbackMigration: (e) =>
    e.preventDefault()
    id = $(e.target).closest('.action').data('id')
    @ajax(
      id:          "#{@channelKey}_rollback_migration"
      type:        'POST'
      url:         @rollbackUrl()
      data:        JSON.stringify(id: id)
      processData: true
      success: =>
        @load()
        @notify
          type: 'success'
          msg:  __('Rollback of channel migration succeeded!')
      error: =>
        @notify
          type: 'error'
          msg:  __('Failed to roll back the migration of the channel!')
    )

  groupChange: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    item = App.Channel.find(id)
    new @groupEditClass(
      container: @el.closest('.content')
      item:      item
      callback:  @load
    )

  emailAddressNew: (e) =>
    e.preventDefault()
    channel_id = $(e.target).closest('.action').data('id')
    params =
      pageData:
        object: __('Email Address')
      genericObject: 'EmailAddress'
      container: @el.closest('.content')
      item:
        channel_id: channel_id
      callback: @load
    if @emailAddressNewStickyAlerts
      params.stickyAlerts = @emailAddressNewStickyAlerts
    new App.ControllerGenericNew(params)

  emailAddressEdit: (e) =>
    e.preventDefault()
    id = $(e.target).closest('li').data('id')
    new App.ControllerGenericEdit(
      pageData:
        object: __('Email Address')
      genericObject: 'EmailAddress'
      container: @el.closest('.content')
      id:        id
      callback:  @load
    )

  emailAddressDelete: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('li').data('id')
    item = App.EmailAddress.find(id)
    new App.ControllerGenericDestroyConfirm(
      item:      item
      container: @el.closest('.content')
      callback:  @load
    )

class App.AdminConsentInfo extends App.ControllerModal
  buttonClose: true
  small: true
  buttonSubmit: __('Close')
  head: __('Admin Consent')

  content: ->
    App.view('channel_account/admin_consent')()

  onSubmit: =>
    @close()

  onClosed: =>
    return if not @type

    @navigate "#channels/#{@type}"

class App.UserMismatchInfo extends App.ControllerModal
  buttonClose: true
  small: true
  buttonSubmit: __('Close')
  head: __('User Mismatch')

  content: ->
    App.view('channel_account/user_mismatch')(item: @item)

  onSubmit: =>
    @close()

  onClosed: =>
    return if not @type

    @navigate "#channels/#{@type}"

class App.DuplicateEmailAddressInfo extends App.ControllerModal
  buttonClose: true
  small: true
  buttonSubmit: __('Close')
  head: __('Duplicate Email Address')

  content: ->
    App.view('channel_account/duplicate_email_address')(emailAddress: @emailAddress)

  onSubmit: =>
    @close()

  onClosed: =>
    return if not @type

    @navigate "#channels/#{@type}"
