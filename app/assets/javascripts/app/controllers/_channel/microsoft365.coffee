class App.ChannelMicrosoft365 extends App.ControllerTabs
  @requiredPermission: 'admin.channel_microsoft365'
  header: __('Microsoft 365 IMAP Email')
  constructor: ->
    super

    @title __('Microsoft 365 IMAP Email'), true

    @tabs = [
      {
        name:       __('Accounts'),
        target:     'c-account',
        controller: App.ChannelAccountOverview,
        params:
          channelKey:             'microsoft365'
          channelAreaName:        'Microsoft365::Account'
          externalCredentialName: 'microsoft365'
          viewNamespace:          'microsoft365'
          legacyUrls:             true
          hasAdminConsent:        true
          hasRollbackMigration:   true
          hasErrorCodeHandling:   true
          hasMigrationRedirect:   true
          hasInboundEditRedirect: true
          appConfigClass:         AppConfig
          groupEditClass:         ChannelGroupEdit
          inboundEditClass:       ChannelInboundEdit
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

    @alert = {
      variant: 'info'
      message: App.i18n.translateContent('Compared to the Microsoft 365 Graph API Email Channel, this is the traditional implementation using OAuth and IMAP. When setting up new channels, we suggest using the Graph API implementation instead. More information can be found here %l.', 'https://admin-docs.zammad.org/en/latest/channels/microsoft365/index.html')
    }

    @render()

class ChannelInboundEdit extends App.ControllerModal
  @include App.DestinationGroupEmailAddressesMixin

  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: __('Channel')

  content: =>
    configureAttributesBase = [
      { name: 'group_id',                display: __('Destination Group'), tag: 'tree_select', null: false, relation: 'Group', filter: { active: true } },
      { name: 'group_email_address_id',  display: __('Destination group > Sending email address'), tag: 'select', null: false, options: @emailAddressOptions(@item.id, @item.group_id), note: __("This will adjust the corresponding setting of the destination group within the group management. A group's email address determines which address should be used for outgoing mails, e.g. when an agent is composing an email or a trigger is sending an auto-reply.") },
      { name: 'options::folder',         display: __('Folder'),   tag: 'input',  type: 'text', limit: 120, null: true, autocapitalize: false },
      { name: 'options::keep_on_server', display: __('Keep messages on server'), tag: 'boolean', null: true, options: { true: 'yes', false: 'no' }, translate: true, default: false },
    ]
    @form = new App.ControllerForm(
      model:
        configure_attributes: configureAttributesBase
        className: ''
      params: _.extend(
        @item.options.inbound
        group_id: @item.group_id
      )
      handlers: [@destinationGroupEmailAddressFormHandler(@item)]
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

    data =
      options: params.options

    # disable form
    @formDisable(e)

    # probe
    @ajax(
      id:   'channel_email_inbound'
      type: 'POST'
      url:  "#{@apiPath}/channels_microsoft365_inbound/#{@item.id}"
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
      url:  "#{@apiPath}/channels_microsoft365_verify/#{@item.id}"
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

    @navigate '#channels/microsoft365'

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
      url:  "#{@apiPath}/channels_microsoft365_group/#{@item.id}"
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
  button: 'Connect'
  buttonCancel: true
  small: true
  events:
    'click .js-copy':   'copyInputToClipboard'
    'click .js-select': 'selectAll'

  content: ->
    @external_credential = App.ExternalCredential.findByAttribute('name', 'microsoft365')

    $(App.view('microsoft365/app_config')(
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
      id:   'microsoft365_app_verify'
      type: 'POST'
      url:  "#{@apiPath}/external_credentials/microsoft365/app_verify"
      data: JSON.stringify(@formParams())
      processData: true
      success: (data, status, xhr) =>
        if data.attributes
          if !@external_credential
            @external_credential = new App.ExternalCredential
          @external_credential.load(name: 'microsoft365', credentials: data.attributes)
          @external_credential.save(
            done: =>
              @isChanged = true
              @close()
            fail: =>
              @el.find('.alert--danger').removeClass('hide').text(__('The entry could not be created.'))
          )
          return
        @formEnable(e)
        @el.find('.alert--danger').removeClass('hide').text(data.error || __('App could not be verified.'))
    )

App.Config.set('microsoft365', { prio: 5200, name: __('Microsoft 365 IMAP Email'), parent: '#channels', target: '#channels/microsoft365', controller: App.ChannelMicrosoft365, permission: ['admin.channel_microsoft365'] }, 'NavBarAdmin')
