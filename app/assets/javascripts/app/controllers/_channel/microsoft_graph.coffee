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
        controller: App.ChannelAccountOverview,
        params:
          channelKey:             'microsoft_graph'
          channelAreaName:        'MicrosoftGraph::Account'
          externalCredentialName: 'microsoft_graph'
          viewNamespace:          'microsoft_graph'
          hasAdminConsent:        true
          hasRollbackMigration:   false
          hasMailboxInfo:         true
          hasErrorCodeHandling:   true
          hasMigrationRedirect:   false
          hasInboundEditRedirect: true
          appConfigClass:         AppConfig
          groupEditClass:         ChannelGroupEdit
          inboundEditClass:       ChannelInboundEdit
          inboundNewClass:        ChannelInboundNew
          emailAddressNewStickyAlerts: [
            [
              'warning',
              [
                __('Please note that email aliases have to be configured on the Microsoft 365 side beforehand. %l'),
                'https://admin-docs.zammad.org/microsoft365-graph-account-aliases'
              ]
            ]
          ]
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
    'click .js-copy':   'copyInputToClipboard'
    'click .js-select': 'selectAll'

  content: ->
    @external_credential = App.ExternalCredential.findByAttribute('name', 'microsoft_graph')

    $(App.view('microsoft_graph/app_config')(
      external_credential: @external_credential
      callbackUrl: @callbackUrl
    ))

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
