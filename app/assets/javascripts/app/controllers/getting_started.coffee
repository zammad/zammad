class Index extends App.WizardFullScreen
  constructor: ->
    super

    if @authenticateCheck() && !@permissionCheck('admin.wizard')
      @navigate '#'
      return

    # set title
    @title 'Get Started'

    # redirect to login if master user already exists
    if @Config.get('system_init_done')
      @navigate '#login'
      return

    # if not import backend exists, go ahead
    if !@Config.get('ImportPlugins')
      @navigate 'getting_started/admin'
      return

    @fetch()

  release: =>
    @el.removeClass('fit getstarted')

  fetch: ->

    # get data
    @ajax(
      id:          'getting_started'
      type:        'GET'
      url:         "#{@apiPath}/getting_started"
      processData: true
      success:     (data, status, xhr) =>

        # check if auto wizard is executed
        if data.auto_wizard == true

          # show message, auto wizard is enabled
          @renderAutoWizard()
          return

        # check if import is active
        if data.import_mode == true
          @navigate "#import/#{data.import_backend}"
          return

        # render page
        @render()
    )

  render: ->
    @html App.view('getting_started/intro')()

  renderAutoWizard: ->
    @html App.view('getting_started/auto_wizard_enabled')()

App.Config.set('getting_started', Index, 'Routes')

class AutoWizard extends App.WizardFullScreen
  constructor: ->
    super

    # if already logged in, got to #
    if @authenticateCheck() && !@permissionCheck('admin.wizard')
      @navigate '#'
      return

    # redirect to login if master user already exists
    if @Config.get('system_init_done')
      @navigate '#login'
      return

    # set title
    @title 'Auto Wizard'
    @renderSplash()
    @fetch()

  release: =>
    @el.removeClass('fit getstarted')

  fetch: ->

    url = "#{@apiPath}/getting_started/auto_wizard"
    if @token
      url += "/#{@token}"

    # get data
    @ajax(
      id:          'auto_wizard'
      type:        'GET'
      url:         url
      processData: true
      success:     (data, status, xhr) =>

        # check if auto wizard enabled
        if data.auto_wizard is false
          @navigate '#'
          return

        # auto wizard setup was successful
        if data.auto_wizard_success is true

          # login check / get session user
          delay = =>
            App.Auth.loginCheck()
            @navigate '#'
          @delay(delay, 800)
          return

        if data.auto_wizard_success is false
          if data.message
            @renderFailed(data)
          else
            @renderToken()
          return

        # redirect to login if master user already exists
        @navigate '#login'
    )

  renderFailed: (data) ->
    @html App.view('getting_started/auto_wizard_failed')(data)

  renderSplash: ->
    @html App.view('getting_started/auto_wizard_splash')()

  renderToken: ->
    @html App.view('getting_started/auto_wizard_enabled')()

App.Config.set('getting_started/auto_wizard', AutoWizard, 'Routes')
App.Config.set('getting_started/auto_wizard/:token', AutoWizard, 'Routes')

class Admin extends App.WizardFullScreen
  events:
    'submit form': 'submit'

  constructor: ->
    super

    if @authenticateCheck() && !@permissionCheck('admin.wizard')
      @navigate '#'
      return

    # set title
    @title 'Create Admin'

    # redirect to login if master user already exists
    if @Config.get('system_init_done')
      @navigate '#login'
      return

    @fetch()

  release: =>
    @el.removeClass('fit getstarted')

  fetch: ->

    # get data
    @ajax(
      id:    'getting_started'
      type:  'GET'
      url:   "#{@apiPath}/getting_started"
      processData: true
      success: (data, status, xhr) =>

        # check if user got created right now
        #if true
        #  @navigate '#getting_started/base'
        #  return

        # check if import is active
        if data.import_mode == true
          @navigate "#import/#{data.import_backend}"
          return

        # load group collection
        App.Collection.load(type: 'Group', data: data.groups)

        # render page
        @render()
    )

  render: ->

    @html App.view('getting_started/admin')()

    new App.ControllerForm(
      el:        @$('.js-admin-form')
      model:     App.User
      screen:    'signup'
      autofocus: true
    )

  submit: (e) =>
    e.preventDefault()
    @formDisable(e)
    @params          = @formParam(e.target)
    @params.role_ids = []

    user = new App.User
    user.load(@params)

    errors = user.validate(
      screen: 'signup'
    )
    if errors
      @log 'error new', errors
      @formValidate(form: e.target, errors: errors)
      @formEnable(e)
      return false

    # save user
    user.save(
      done: (r) =>
        App.Auth.login(
          data:
            username: @params.email
            password: @params.password
          success: @relogin
          error: ->
            App.Event.trigger 'notify', {
              type:    'error'
              msg:     App.i18n.translateContent('Signin failed! Please contact the support team!')
              timeout: 2500
            }
        )
        @Config.set('system_init_done', true)

      fail: (settings, details) =>
        @formEnable(e)
        App.Event.trigger 'notify', {
          type:    'error'
          msg:     App.i18n.translateContent(details.error_human || 'Can\'t create user!')
          timeout: 2500
        }
    )

  relogin: (data, status, xhr) =>
    @log 'notice', 'relogin:success', data
    App.Event.trigger 'notify:removeall'
    @navigate 'getting_started/base'

App.Config.set('getting_started/admin', Admin, 'Routes')

class Base extends App.WizardFullScreen
  elements:
    '.logo-preview': 'logoPreview'

  events:
    'submit form':       'submit'
    'change .js-upload': 'onLogoPick'

  constructor: ->
    super

    # redirect if we are not admin
    if !@permissionCheck('admin.wizard')
      @navigate '#'
      return

    # set title
    @title 'Configure Base'

    @fetch()

  release: =>
    @el.removeClass('fit getstarted')

  fetch: ->

    # get data
    @ajax(
      id:    'getting_started',
      type:  'GET',
      url:   "#{@apiPath}/getting_started",
      processData: true,
      success: (data, status, xhr) =>

        # check if import is active
        if data.import_mode == true
          @navigate "#import/#{data.import_backend}"
          return

        # import config options
        if data.config
          for key, value of data.config
            App.Config.set(key, value)

        # render page
        @render()
    )

  render: ->

    fqdn      = App.Config.get('fqdn')
    http_type = App.Config.get('http_type')
    if !fqdn || fqdn is 'zammad.example.com'
      url = window.location.origin
    else
      url = "#{http_type}://#{fqdn}"

    organization = App.Config.get('organization')
    @html App.view('getting_started/base')(
      url:          url
      logoUrl:      @logoUrl()
      organization: organization
    )
    @$('input, select').first().focus()

  onLogoPick: (event) =>
    reader = new FileReader()

    reader.onload = (e) =>
      @logoPreview.attr('src', e.target.result)

    file = event.target.files[0]

    @hideAlerts()

    # if no file is given, about in file upload was used
    if !file
      return

    maxSiteInMb = 8
    if file.size && file.size > 1024 * 1024 * maxSiteInMb
      @showAlert( 'logo', App.i18n.translateInline('File too big, max. %s MB allowed.', maxSiteInMb ))
      @logoPreview.attr('src', '')
      return

    reader.readAsDataURL(file)

  submit: (e) =>
    e.preventDefault()
    @hideAlerts()
    @disable(e)

    @params = @formParam(e.target)
    @params.logo = @logoPreview.attr('src')
    @params.locale_default = App.i18n.detectBrowserLocale()
    @params.timezone_default = App.i18n.detectBrowserTimezone()

    store = (logoResizeDataUrl) =>
      @params.logo_resize = logoResizeDataUrl
      @ajax(
        id:          'getting_started_base'
        type:        'POST'
        url:         "#{@apiPath}/getting_started/base"
        data:        JSON.stringify(@params)
        processData: true
        success:     (data, status, xhr) =>
          if data.result is 'ok'
            for key, value of data.settings
              App.Config.set(key, value)
            if App.Config.get('system_online_service')
              @navigate 'getting_started/channel/email_pre_configured'
            else
              @navigate 'getting_started/email_notification'
          else
            for key, value of data.messages
              @showAlert(key, value)
            @enable(e)
        fail: =>
          @enable(e)
      )

    # add resized image
    App.ImageService.resizeForApp(@params.logo, @logoPreview.width(), @logoPreview.height(), store)

  hideAlerts: =>
    @$('.form-group').removeClass('has-error')
    @$('.alert').addClass('hide')

  showAlert: (field, message) =>
    @$("[name=#{field}]").closest('.form-group').addClass('has-error')
    @$("[name=#{field}]").closest('.form-group').find('.alert').removeClass('hide').text( App.i18n.translateInline( message ) )

App.Config.set('getting_started/base', Base, 'Routes')

class EmailNotification extends App.WizardFullScreen
  events:
    'change .js-outbound [name=adapter]': 'toggleOutboundAdapter'
    'submit .js-outbound':                'submit'

  constructor: ->
    super

    # redirect if we are not admin
    if !@permissionCheck('admin.wizard')
      @navigate '#'
      return

    # set title
    @title 'Email Notifications'

    @channelDriver =
      email:
        inbound: {}
        outbound: {}

    @fetch()

  release: =>
    @el.removeClass('fit getstarted')

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
          @navigate "#import/#{data.import_backend}"
          return

        @channelDriver = data.channel_driver

        # render page
        @render()
    )

  render: ->
    @html App.view('getting_started/email_notification')()
    configureAttributesOutbound = [
      { name: 'adapter', display: 'Send Mails via', tag: 'select', multiple: false, null: false, options: @channelDriver.email.outbound },
    ]
    new App.ControllerForm(
      el:    @$('.base-outbound-type')
      model:
        configure_attributes: configureAttributesOutbound
        className: ''
      params:
        adapter: 'sendmail'
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
        { name: 'options::password', display: 'Password', tag: 'input', type: 'password', limit: 120, null: true, autocapitalize: false, autocomplete: 'off', single: true },
        { name: 'options::port',     display: 'Port',     tag: 'input', type: 'text',     limit: 6,   null: true, autocapitalize: false },
      ]
      @form = new App.ControllerForm(
        el:    @$('.base-outbound-settings')
        model:
          configure_attributes: configureAttributesOutbound
          className: ''
      )

  submit: (e) =>
    e.preventDefault()

    # get params
    params          = @formParam(e.target)
    params['email'] = 'me@localhost'
    @disable(e)

    @showSlide('js-test')

    @ajax(
      id:   'email_notification'
      type: 'POST'
      url:  "#{@apiPath}/channels_email_notification"
      data: JSON.stringify(params)
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'
          for key, value of data.settings
            App.Config.set(key, value)
          if App.Config.get('system_online_service')
            @navigate 'getting_started/channel/email_pre_configured'
          else
            @navigate 'getting_started/channel'
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

App.Config.set('getting_started/email_notification', EmailNotification, 'Routes')

class Channel extends App.WizardFullScreen
  constructor: ->
    super

    # redirect if we are not admin
    if !@permissionCheck('admin.wizard')
      @navigate '#'
      return

    # set title
    @title 'Connect Channels'

    @adapters = [
      {
        name: 'Email'
        class: 'email'
        link: '#getting_started/channel/email'
      },
    ]

    @fetch()

  release: =>
    @el.removeClass('fit getstarted')

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
          @navigate "#import/#{data.import_backend}"
          return

        # render page
        @render()
    )

  render: ->
    @html App.view('getting_started/channel')(
      adapters: @adapters
    )

App.Config.set('getting_started/channel', Channel, 'Routes')

class ChannelEmailPreConfigured extends App.WizardFullScreen
  constructor: ->
    super

    # redirect if we are not admin
    if !@permissionCheck('admin.wizard')
      @navigate '#'
      return

    # set title
    @title 'Connect Channels'

    @fetch()

  release: =>
    @el.removeClass('fit getstarted')

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
          @navigate "#import/#{data.import_backend}"
          return

        # render page
        @render(data)
    )

  render: (data) ->
    @html App.view('getting_started/email_pre_configured')(
      data
    )

App.Config.set('getting_started/channel/email_pre_configured', ChannelEmailPreConfigured, 'Routes')

class ChannelEmail extends App.WizardFullScreen
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

  release: =>
    @el.removeClass('fit getstarted')

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
          @navigate "#import/#{data.import_backend}"
          return

        @channelDriver = data.channel_driver

        # render page
        @render()
    )

  render: ->

    @html App.view('getting_started/email')()
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
            message = App.i18n.translateContent('We have already found %s email(s) in your mailbox. Zammad will move it all from your mailbox into Zammad.', data.content_messages)
            @$('.js-inbound-acknowledge .js-message').html(message)
            @$('.js-inbound-acknowledge .js-back').attr('data-slide', 'js-intro')
            @$('.js-inbound-acknowledge .js-next').attr('data-slide', '')
            @$('.js-inbound-acknowledge .js-next').unbind('click.verify').bind('click.verify', (e) =>
              e.preventDefault()
              @verify(@account)
            )
            @showSlide('js-inbound-acknowledge')
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
            message = App.i18n.translateContent('We have already found %s emails in your mailbox. Zammad will move it all from your mailbox into Zammad.', data.content_messages)
            @$('.js-inbound-acknowledge .js-message').html(message)
            @$('.js-inbound-acknowledge .js-back').attr('data-slide', 'js-inbound')
            @$('.js-inbound-acknowledge .js-next').unbind('click.verify')
            @showSlide('js-inbound-acknowledge')
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
          @navigate 'getting_started/agents'
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

App.Config.set('getting_started/channel/email', ChannelEmail, 'Routes')

class Agent extends App.WizardFullScreen
  events:
    'submit form': 'submit'

  constructor: ->
    super
    @authenticateCheckRedirect()

    # set title
    @title 'Invite Agents'
    @fetch()

  release: =>
    @el.removeClass('fit getstarted')

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
          @navigate "#import/#{data.import_backend}"
          return

        # load group collection
        App.Collection.load(type: 'Group', data: data.groups)

        # render page
        @render()
    )

  render: ->

    @html App.view('getting_started/agent')()

    new App.ControllerForm(
      el:        @$('.js-agent-form')
      model:     App.User
      screen:    'invite_agent'
      autofocus: true
    )

  submit: (e) =>
    e.preventDefault()
    @formDisable(e)
    @params          = @formParam(e.target)
    @params.role_ids = []

    # set invite flag
    @params.invite = true

    # find agent role
    role = App.Role.findByAttribute('name', 'Agent')
    if role
      @params.role_ids = role.id

    user = new App.User
    user.load(@params)

    errors = user.validate(
      screen: 'invite_agent'
    )
    if errors
      @log 'error new', errors
      @formValidate(form: e.target, errors: errors)
      @formEnable(e)
      return false

    # save user
    user.save(
      done: (r) =>
        App.Event.trigger 'notify', {
          type:    'success'
          msg:     App.i18n.translateContent('Invitation sent!')
          timeout: 3500
        }

        # rerender page
        @render()

      fail: (settings, details) =>
        @formEnable(e)
        App.Event.trigger 'notify', {
          type:    'error'
          msg:     App.i18n.translateContent(details.error_human || 'Can\'t create user!')
          timeout: 2500
        }
    )

App.Config.set('getting_started/agents', Agent, 'Routes')

class Channel extends App.WizardFullScreen
  constructor: ->
    super
    @authenticateCheckRedirect()

    # set title
    @title 'Setup Finished'
    @render()

  release: =>
    @el.removeClass('fit getstarted')

  render: ->
    @html App.view('getting_started/finish')()
    @delay(
      => @$('.wizard-slide').addClass('hide')
      2300
    )
    @delay(
      => @navigate '#'
      4300
    )

App.Config.set('getting_started/finish', Channel, 'Routes')
