class App.ChannelGoogle extends App.ControllerTabs
  requiredPermission: 'admin.channel_google'
  header: 'Google'
  constructor: ->
    super

    @title 'Google', true

    @tabs = [
      {
        name:       'Accounts',
        target:     'c-account',
        controller: ChannelAccountOverview,
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

class ChannelAccountOverview extends App.ControllerSubContent
  requiredPermission: 'admin.channel_google'
  events:
    'click .js-new':                'new'
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
    'click .js-emailAddressDelete': 'emailAddressDelete',

  constructor: ->
    super

    @interval(@load, 30000)
    @load()

  load: (reset_channel_id = false) =>
    if reset_channel_id
      @channel_id = undefined
      @navigate '#channels/google'

    @startLoading()
    @ajax(
      id:   'google_index'
      type: 'GET'
      url:  "#{@apiPath}/channels_google"
      processData: true
      success: (data, status, xhr) =>
        @stopLoading()
        App.Collection.loadAssets(data.assets)
        @callbackUrl = data.callback_url
        @render(data)
    )

  render: (data) =>

    # if no google app is registered, show intro
    external_credential = App.ExternalCredential.findByAttribute('name', 'google')
    if !external_credential
      @html App.view('google/index')()
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

    # on a channel migration we need to auto redirect
    # the user to the "Add Account" functionality after
    # the filled up the external credentials
    if @channel_id
      item = App.Channel.find(@channel_id)
      if item && item.area != 'Google::Account'
        @new()
        return

    # get all unlinked email addresses
    not_used_email_addresses = []
    for email_address_id in data.not_used_email_address_ids
      not_used_email_addresses.push App.EmailAddress.find(email_address_id)

    @html App.view('google/list')(
      channels: channels
      external_credential: external_credential
      not_used_email_addresses: not_used_email_addresses
    )

    # on a channel creation we will auto open the edit
    # dialog after the redirect back to zammad to optional
    # change the inbound configuration, but not for
    # migrated channel because we guess that the inbound configuration
    # is already correct for them.
    if @channel_id
      item = App.Channel.find(@channel_id)
      if item && item.area == 'Google::Account' && item.options && item.options.backup_imap_classic is undefined
        @editInbound(undefined, @channel_id, true)
        @channel_id = undefined

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

  new: (e) ->
    window.location.href = "#{@apiPath}/external_credentials/google/link_account"

  delete: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    new App.ControllerConfirm(
      message: 'Sure?'
      callback: =>
        @ajax(
          id:   'google_delete'
          type: 'DELETE'
          url:  "#{@apiPath}/channels_google"
          data: JSON.stringify(id: id)
          processData: true
          success: =>
            @load()
        )
      container: @el.closest('.content')
    )

  reauthenticate: (e) =>
    e.preventDefault()
    id                   = $(e.target).closest('.action').data('id')
    window.location.href = "#{@apiPath}/external_credentials/google/link_account?channel_id=#{id}"

  disable: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    @ajax(
      id:   'google_disable'
      type: 'POST'
      url:  "#{@apiPath}/channels_google_disable"
      data: JSON.stringify(id: id)
      processData: true
      success: =>
        @load()
    )

  enable: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    @ajax(
      id:   'google_enable'
      type: 'POST'
      url:  "#{@apiPath}/channels_google_enable"
      data: JSON.stringify(id: id)
      processData: true
      success: =>
        @load()
    )

  editInbound: (e, channel_id, set_active) =>
    if !channel_id
      e.preventDefault()
      channel_id = $(e.target).closest('.action').data('id')
    item = App.Channel.find(channel_id)
    new ChannelInboundEdit(
      container: @el.closest('.content')
      item: item
      callback: @load
      set_active: set_active,
    )

  rollbackMigration: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    @ajax(
      id:   'google_rollback_migration'
      type: 'POST'
      url:  "#{@apiPath}/channels_google_rollback_migration"
      data: JSON.stringify(id: id)
      processData: true
      success: =>
        @load()
        @notify
          type: 'success'
          msg:  'Rollback of channel migration succeeded!'
      error: (data) =>
        @notify
          type: 'error'
          msg:  'Failed to rollback migration of the channel!'
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

class ChannelInboundEdit extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: 'Channel'

  content: =>
    configureAttributesBase = [
      { name: 'options::folder',          display: 'Folder',   tag: 'input',  type: 'text', limit: 120, null: true, autocapitalize: false, placeholder: 'optional' },
      { name: 'options::keep_on_server',  display: 'Keep messages on server', tag: 'boolean', null: true, options: { true: 'yes', false: 'no' }, translate: true, default: false },
    ]
    @form = new App.ControllerForm(
      model:
        configure_attributes: configureAttributesBase
        className: ''
      params: @item.options.inbound
    )
    @form.form

  onSubmit: (e) =>
    @startLoading()

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

    if @set_active
      params['active'] = true

    # update
    @ajax(
      id:   'channel_email_inbound'
      type: 'POST'
      url:  "#{@apiPath}/channels_google_inbound/#{@item.id}"
      data: JSON.stringify(params)
      processData: true
      success: (data, status, xhr) =>
        @callback(true)
        @close()
      error: (xhr) =>
        @stopLoading()
        @formEnable(e)
        details = xhr.responseJSON || {}
        @notify
          type:    'error'
          msg:     App.i18n.translateContent(details.error_human || details.error || 'Unable to save changes.')
          timeout: 6000
    )

class ChannelGroupEdit extends App.ControllerModal
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
      url:  "#{@apiPath}/channels_google_group/#{@item.id}"
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

class AppConfig extends App.ControllerModal
  head: 'Connect Google App'
  shown: true
  button: 'Connect'
  buttonCancel: true
  small: true

  content: ->
    @external_credential = App.ExternalCredential.findByAttribute('name', 'google')
    content = $(App.view('google/app_config')(
      external_credential: @external_credential
      callbackUrl: @callbackUrl
    ))
    content.find('.js-select').on('click', (e) =>
      @selectAll(e)
    )
    content

  onClosed: =>
    return if !@isChanged
    @isChanged = false
    @load()

  onSubmit: (e) =>
    @formDisable(e)

    # verify app credentials
    @ajax(
      id:   'google_app_verify'
      type: 'POST'
      url:  "#{@apiPath}/external_credentials/google/app_verify"
      data: JSON.stringify(@formParams())
      processData: true
      success: (data, status, xhr) =>
        if data.attributes
          if !@external_credential
            @external_credential = new App.ExternalCredential
          @external_credential.load(name: 'google', credentials: data.attributes)
          @external_credential.save(
            done: =>
              @isChanged = true
              @close()
            fail: =>
              @el.find('.alert').removeClass('hidden').text('Unable to create entry.')
          )
          return
        @formEnable(e)
        @el.find('.alert').removeClass('hidden').text(data.error || 'Unable to verify App.')
    )

App.Config.set('google', { prio: 5000, name: 'Google', parent: '#channels', target: '#channels/google', controller: App.ChannelGoogle, permission: ['admin.channel_google'] }, 'NavBarAdmin')
