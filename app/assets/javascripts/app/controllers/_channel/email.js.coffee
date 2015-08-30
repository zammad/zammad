class App.ChannelEmail extends App.ControllerTabs
  header: 'Email'
  constructor: ->
    super

    @title 'Email', true

    @tabs = [
      {
        name:       'Accounts',
        target:     'c-account',
        controller: App.ChannelEmailAccountOverview,
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

class App.ChannelEmailFilter extends App.Controller
  events:
    'click [data-type=new]':  'new'

  constructor: ->
    super

    App.PostmasterFilter.subscribe( @render, initFetch: true )

  render: =>
    data = App.PostmasterFilter.search( sortBy: 'name' )

    template = $( '<div><div class="overview"></div><a data-type="new" class="btn btn--success">' + App.i18n.translateContent('New') + '</a></div>' )

    new App.ControllerTable(
      el:       template.find('.overview')
      model:    App.PostmasterFilter
      objects:  data
      bindRow:
        events:
          'click': @edit
    )
    @html template

  new: (e) =>
    e.preventDefault()
    new App.ChannelEmailFilterEdit(
      container: @el.closest('.content')
    )

  edit: (id, e) =>
    e.preventDefault()
    new App.ChannelEmailFilterEdit(
      object:    App.PostmasterFilter.find(id)
      container: @el.closest('.content')
    )

class App.ChannelEmailFilterEdit extends App.ControllerModal
  constructor: ->
    super

    @head   = 'Postmaster Filter'
    @button = true
    @close  = true
    @cancel = true

    if @object
      @form = new App.ControllerForm(
        model:     App.PostmasterFilter,
        params:    @object,
        autofocus: true,
      )
    else
      @form = new App.ControllerForm(
        model:     App.PostmasterFilter,
        autofocus: true,
      )

    @content = @form.form
    @show()

  onSubmit: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)
    params['channel'] = 'email'

    object = @object || new App.PostmasterFilter
    object.load(params)

    # validate form
    errors = @form.validate( params )

    # show errors in form
    if errors
      @log 'error', errors
      @formValidate( form: e.target, errors: errors )
      return false

    # disable form
    @formDisable(e)

    # save object
    object.save(
      done: =>
        @hide()
      fail: =>
        @hide()
    )

class App.ChannelEmailSignature extends App.Controller
  events:
    'click [data-type=new]':  'new'

  constructor: ->
    super

    App.Signature.subscribe( @render, initFetch: true )

  render: =>
    data = App.Signature.search( sortBy: 'name' )

    template = $( '<div><div class="overview"></div><a data-type="new" class="btn btn--success">' + App.i18n.translateContent('New') + '</a></div>' )
    new App.ControllerTable(
      el:       template.find('.overview')
      model:    App.Signature
      objects:  data
      bindRow:
        events:
          'click': @edit
    )
    @html template

  new: (e) =>
    e.preventDefault()
    new App.ChannelEmailSignatureEdit(
      container: @el.closest('.content')
    )

  edit: (id, e) =>
    e.preventDefault()
    item = App.Signature.find(id)
    new App.ChannelEmailSignatureEdit(
      object:    item
      container: @el.closest('.content')
    )

class App.ChannelEmailSignatureEdit extends App.ControllerModal
  constructor: ->
    super

    @head   = 'Signature'
    @button = true
    @close  = true
    @cancel = true

    if @object
      @form = new App.ControllerForm(
        model:     App.Signature
        params:    @object
        autofocus: true
      )
    else
      @form = new App.ControllerForm(
        model:     App.Signature
        autofocus: true
      )

    @content = @form.form

    @show()

  onSubmit: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)

    object = @object || new App.Signature
    object.load(params)

    # validate form
    errors = @form.validate( params )

    # show errors in form
    if errors
      @log 'error', errors
      @formValidate( form: e.target, errors: errors )
      return false

    # disable form
    @formDisable(e)

    # save object
    object.save(
      done: =>
        @hide()
      fail: =>
        @hide()
    )

class App.ChannelEmailAccountOverview extends App.Controller
  events:
    'click [data-type="new"]': 'wizard'
    'click [data-type="delete"]': 'delete'
    'click [data-type="edit-inbound"]': 'edit_inbound'
    'click [data-type="edit-outbound"]': 'edit_outbound'
    'click [data-type="email-address-new"]': 'email_address_new'
    'click [data-type="email-address-edit"]': 'email_address_edit'
    'click [data-type="edit-notification-outbound"]': 'edit_notification_outbound'

  constructor: ->
    super
    @interval(@load, 20000)

  load: =>
    @ajax(
      id:   'email_index'
      type: 'GET'
      url:  @apiPath + '/channels/email_index'
      processData: true
      success: (data, status, xhr) =>

        # load assets
        App.Collection.loadAssets(data.assets)

        @render(accounts_fixed: data.accounts_fixed)
    )

  render: (params = {}) =>

    # get channels
    channels = App.Channel.search( filter: { area: 'Email::Account' } )
    for channel in channels
      email_addresses = App.EmailAddress.search( filter: { channel_id: channel.id } )
      channel.email_addresses = email_addresses

    # get all unlinked email addresses
    email_addresses_all      = App.EmailAddress.all()
    email_addresses_not_used = []
    for email_address in email_addresses_all
      if !email_address.channel_id || email_address.channel_id is ''
        email_addresses_not_used.push email_address

    # get channels
    channel = App.Channel.search( filter: { area: 'Email::Notification', active: true } )[0]

    @html App.view('channel/email_account_overview')(
      channels:                 channels
      email_addresses_not_used: email_addresses_not_used
      channel:                  channel
      accounts_fixed:           params.accounts_fixed
    )

  wizard: (e) =>
    e.preventDefault()
    new App.ChannelEmailAccountWizard(
      container: @el.closest('.content')
      callback:  @load
    )

  edit_inbound: (e) =>
    e.preventDefault()
    id      = $(e.target).closest('tr').data('id')
    channel = App.Channel.find(id)
    slide   = 'js-inbound'
    new App.ChannelEmailAccountWizard(
      container: @el.closest('.content')
      slide:     slide
      channel:   channel
      callback:  @load
    )

  edit_outbound: (e) =>
    e.preventDefault()
    id      = $(e.target).closest('tr').data('id')
    channel = App.Channel.find(id)
    slide   = 'js-outbound'
    new App.ChannelEmailAccountWizard(
      container: @el.closest('.content')
      slide:     slide
      channel:   channel
      callback:  @load
    )

  delete: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('tr').data('id')
    item = App.Channel.find(id)
    new App.ControllerGenericDestroyConfirm(
      item:      item
      container: @el.closest('.content')
      callback:  @load
    )

  email_address_new: (e) =>
    e.preventDefault()
    channel_id = $(e.target).closest('tr').data('id')
    new App.ControllerGenericNew(
      pageData:
        object: 'Email Address'
      genericObject: 'EmailAddress'
      container: @el.closest('.content')
      item:
        channel_id: channel_id
      callback: @load
    )

  email_address_edit: (e) =>
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

  edit_notification_outbound: (e) =>
    e.preventDefault()
    id      = $(e.target).closest('tr').data('id')
    channel = App.Channel.find(id)
    slide   = 'js-outbound'
    new App.ChannelEmailNotificationWizard(
      container: @el.closest('.content')
      channel:   channel
      callback:  @load
    )

class App.ChannelEmailAccountWizard extends App.Wizard
  elements:
    '.modal-body': 'body'

  className: 'modal fade'

  events:
    'submit .js-intro':                   'probeBasedOnIntro'
    'submit .js-inbound':                 'probeInbound'
    'change .js-outbound [name=adapter]': 'toggleOutboundAdapter'
    'submit .js-outbound':                'probleOutbound'
    'click  .js-back':                    'goToSlide'
    'click  .js-close':                   'hide'

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
        inbound: @channel.options.inbound
        outbound: @channel.options.outbound
        meta:     {}

    if @container
      @el.addClass('modal--local')

    @render()

    @el.modal
      keyboard:  true
      show:      true
      backdrop:  true
      container: @container
    .on
      'hidden.bs.modal': =>
        if @callback
          @callback()
        @el.remove()

    if @slide
      @showSlide(@slide)

  render: =>
    @html App.view('channel/email_account_wizard')()
    @showSlide('js-intro')

    # outbound
    adapters =
      sendmail: 'Local MTA (Sendmail/Postfix/Exim/...) - use server setup'
      smtp:     'SMTP - configure your own outgoing SMTP settings'
    configureAttributesOutbound = [
      { name: 'adapter', display: 'Send Mails via', tag: 'select', multiple: false, null: false, options: adapters },
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
      { name: 'adapter',            display: 'Type',     tag: 'select', multiple: false, null: false, options: { imap: 'imap', pop3: 'pop3' } },
      { name: 'options::host',      display: 'Host',     tag: 'input',  type: 'text', limit: 120, null: false, autocapitalize: false },
      { name: 'options::user',      display: 'User',     tag: 'input',  type: 'text', limit: 120, null: false, autocapitalize: false, autocomplete: 'off', },
      { name: 'options::password',  display: 'Password', tag: 'input',  type: 'password', limit: 120, null: false, autocapitalize: false, autocomplete: 'new-password', single: true },
    ]
    new App.ControllerForm(
      el:    @$('.base-inbound-settings'),
      model:
        configure_attributes: configureAttributesInbound
        className: ''
      params: @account.inbound
    )

  toggleOutboundAdapter: =>

    # fill user / password based on intro info
    channel_used = { options: {} }
    if @account['meta']
      channel_used['options']['user']     = @account['meta']['email']
      channel_used['options']['password'] = @account['meta']['password']

    # show used backend
    @$('.base-outbound-settings').html('')
    adapter = @$('.js-outbound [name=adapter]').val()
    if adapter is 'smtp'
      configureAttributesOutbound = [
        { name: 'options::host',     display: 'Host',     tag: 'input', type: 'text',     limit: 120, null: false, autocapitalize: false, autofocus: true },
        { name: 'options::user',     display: 'User',     tag: 'input', type: 'text',     limit: 120, null: true, autocapitalize: false, autocomplete: 'off', },
        { name: 'options::password', display: 'Password', tag: 'input', type: 'password', limit: 120, null: true, autocapitalize: false, autocomplete: 'new-password', single: true },
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

    @disable(e)
    @$('.js-probe .js-email').text( params.email )
    @showSlide('js-probe')

    @ajax(
      id:   'email_probe'
      type: 'POST'
      url:  @apiPath + '/channels/email_probe'
      data: JSON.stringify( params )
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'
          if data.setting
            for key, value of data.setting
              @account[key] = value
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

    # let backend know about the channel
    if @channel
      params.channel_id = @channel.id

    @disable(e)

    @showSlide('js-test')

    @ajax(
      id:   'email_inbound'
      type: 'POST'
      url:  @apiPath + '/channels/email_inbound'
      data: JSON.stringify( params )
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'

          # remember account settings
          @account.inbound = params

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

  probleOutbound: (e) =>
    e.preventDefault()

    # get params
    params          = @formParam(e.target)
    params['email'] = @account['meta']['email']

    if !params['email'] && @channel
      email_addresses = App.EmailAddress.search( filter: { channel_id: @channel.id } )
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
      url:  @apiPath + '/channels/email_outbound'
      data: JSON.stringify( params )
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'

          # remember account settings
          @account.outbound = params

          @verify(@account)
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

  verify: (account, count = 0) =>
    @showSlide('js-verify')

    # let backend know about the channel
    if @channel
      account.channel_id = @channel.id

    if !account.email && @channel
      email_addresses = App.EmailAddress.search( filter: { channel_id: @channel.id } )
      if email_addresses && email_addresses[0]
        account.email = email_addresses[0].email

    @ajax(
      id:   'email_verify'
      type: 'POST'
      url:  @apiPath + '/channels/email_verify'
      data: JSON.stringify( account )
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'
          @el.modal('hide')
        else
          if data.source is 'inbound' || data.source is 'outbound'
              @showSlide("js-#{data.source}")
              @showAlert("js-#{data.source}", data.message_human || data.message )
              @showInvalidField("js-#{data.source}", data.invalid_field)
          else
            if count is 2
              @showAlert('js-verify', data.message_human || data.message )
              @delay(
                =>
                  @showSlide('js-intro')
                  @showAlert('js-intro', 'Unable to verify sending and receiving. Please check your settings.')

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

  hide: (e) =>
    e.preventDefault()
    @el.modal('hide')

class App.ChannelEmailNotificationWizard extends App.Wizard
  elements:
    '.modal-body': 'body'

  className: 'modal fade'

  events:
    'change .js-outbound [name=adapter]': 'toggleOutboundAdapter'
    'submit .js-outbound':                'probleOutbound'
    'click  .js-close':                   'hide'

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
        inbound: @channel.options.inbound
        outbound: @channel.options.outbound

    if @container
      @el.addClass('modal--local')

    @render()

    @el.modal
      keyboard:  true
      show:      true
      backdrop:  true
      container: @container
    .on
      'show.bs.modal':   @onShow
      'shown.bs.modal':  @onComplete
      'hidden.bs.modal': =>
        if @callback
          @callback()
        @el.remove()

    if @slide
      @showSlide(@slide)

  render: =>
    @html App.view('channel/email_notification_wizard')()
    @showSlide('js-outbound')

    # outbound
    adapters =
      sendmail: 'Local MTA (Sendmail/Postfix/Exim/...) - use server setup'
      smtp:     'SMTP - configure your own outgoing SMTP settings'
    configureAttributesOutbound = [
      { name: 'adapter', display: 'Send Mails via', tag: 'select', multiple: false, null: false, options: adapters },
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

    # let backend know about the channel
    params.channel_id = @channel.id

    @disable(e)

    @showSlide('js-test')

    @ajax(
      id:   'email_outbound'
      type: 'POST'
      url:  @apiPath + '/channels/email_notification'
      data: JSON.stringify( params )
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'
          @el.remove()
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
