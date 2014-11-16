class Index extends App.ControllerContent
  className: 'getstarted fit'

  constructor: ->
    super

    if @authenticate(true)
      @navigate '#'
      return

    # set title
    @title 'Get Started'

    # if not import backend exists, go ahead
    if !App.Config.get('ImportPlugins')
      @navigate 'getting_started/admin'
      return

    @fetch()

  release: =>
    @el.removeClass('fit getstarted')

  fetch: ->

    # get data
    @ajax(
      id:    'getting_started',
      type:  'GET',
      url:   @apiPath + '/getting_started',
      processData: true,
      success: (data, status, xhr) =>

        # redirect to login if master user already exists
        if @Config.get('system_init_done')
          @navigate '#login'
          return

        # check if import is active
        if data.import_mode == true
          @navigate '#import/' + data.import_backend
          return

        # render page
        @render()
    )

  render: ->

    @html App.view('getting_started/index')()

App.Config.set( 'getting_started', Index, 'Routes' )

class Admin extends App.ControllerContent
  className: 'getstarted fit'
  events:
    'submit form': 'submit'

  constructor: ->
    super

    if @authenticate(true)
      @navigate '#'
      return

    # set title
    @title 'Create Admin'

    @fetch()

  release: =>
    @el.removeClass('fit getstarted')

  fetch: ->

    # get data
    @ajax(
      id:    'getting_started'
      type:  'GET'
      url:   @apiPath + '/getting_started'
      processData: true
      success: (data, status, xhr) =>

        # redirect to login if master user already exists
        if @Config.get('system_init_done')
          @navigate '#login'
          return

        # check if import is active
        if data.import_mode == true
          @navigate '#import/' + data.import_backend
          return

        # load group collection
        App.Collection.load( type: 'Group', data: data.groups )

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
    @params.role_ids = [0]

    user = new App.User
    user.load(@params)

    errors = user.validate(
      screen: 'signup'
    )
    if errors
      @log 'error new', errors
      @formValidate( form: e.target, errors: errors )
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
          error: =>
            App.Event.trigger 'notify', {
              type:    'error'
              msg:     App.i18n.translateContent( 'Signin failed! Please contact the support team!' )
              timeout: 2500
            }
        )
        @Config.set('system_init_done', true)
        App.Event.trigger 'notify', {
          type:    'success'
          msg:     App.i18n.translateContent( 'Welcome to %s!', @Config.get('product_name') )
          timeout: 2500
        }

      fail: (data) =>
        @formEnable(e)
        App.Event.trigger 'notify', {
          type:    'error'
          msg:     App.i18n.translateContent( 'Can\'t create user!' )
          timeout: 2500
        }
    )

  relogin: (data, status, xhr) =>
    @log 'notice', 'relogin:success', data

    App.Event.trigger 'notify:removeall'

    @navigate 'getting_started/base'

App.Config.set( 'getting_started/admin', Admin, 'Routes' )


class Base extends App.ControllerContent
  className: 'getstarted fit'
  elements:
    '.logo-preview': 'logoPreview'

  events:
    'submit form':       'submit'
    'change .js-upload': 'onLogoPick'

  constructor: ->
    super

    # redirect if we are not admin
    if !@authenticate(true)
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
      url:   @apiPath + '/getting_started',
      processData: true,
      success: (data, status, xhr) =>

        # check if import is active
        if data.import_mode == true
          @navigate '#import/' + data.import_backend
          return

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
      organization: organization
    )

  onLogoPick: (event) =>
    reader = new FileReader()

    reader.onload = (e) =>
      @logoPreview.attr('src', e.target.result)

    file = event.target.files[0]

    @hideAlerts()

    # if no file is given, about in file upload was used
    if !file
      return

    maxSiteInMb = 3
    if file.size && file.size > 1024 * 1024 * maxSiteInMb
      @showAlert( 'logo', App.i18n.translateInline( 'File too big, max. %s MB allowed.', maxSiteInMb ) )
      @logoPreview.attr( 'src', '' )
      return

    reader.readAsDataURL(file)

  submit: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)
    params['logo'] = @logoPreview.attr('src')

    @hideAlerts()
    @disable(e)

    @ajax(
      id:   'getting_started_base'
      type: 'POST'
      url:  @apiPath + '/getting_started/base'
      data: JSON.stringify( params )
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'
          for key, value of data.settings
            App.Config.set( key, value )
          @navigate 'getting_started/channel'
        else
          for key, value of data.messages
            @showAlert( key, value )
          @enable(e)
      fail: =>
        @enable(e)
    )

  hideAlerts: =>
    @$('.form-group').removeClass('has-error')
    @$('.alert').addClass('hide')

  showAlert: (field, message) =>
    @$("[name=#{field}]").closest('.form-group').addClass('has-error')
    @$("[name=#{field}]").closest('.form-group').find('.alert').removeClass('hide').text( App.i18n.translateInline( message ) )

  disable: (e) =>
    @formDisable(e)
    @$('.wizard-controls .btn').attr('disabled', true)

  enable: (e) =>
    @formEnable(e)
    @$('.wizard-controls .btn').attr('disabled', false)

App.Config.set( 'getting_started/base', Base, 'Routes' )

class Channel extends App.ControllerContent
  className: 'getstarted fit'

  constructor: ->
    super

    # redirect if we are not admin
    if !@authenticate(true)
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
      id:    'getting_started',
      type:  'GET',
      url:   @apiPath + '/getting_started',
      processData: true,
      success: (data, status, xhr) =>

        # check if import is active
        if data.import_mode == true
          @navigate '#import/' + data.import_backend
          return

        # render page
        @render()
    )

  render: ->
    @html App.view('getting_started/channel')(
      adapters: @adapters
    )

App.Config.set( 'getting_started/channel', Channel, 'Routes' )


class ChannelEmail extends App.ControllerContent
  className: 'getstarted fit'
  events:
    'submit .js-intro':                   'emailProbe'
    'submit .js-inbound':                 'storeInbound'
    'change .js-outbound [name=adapter]': 'toggleAdapter'
    'submit .js-outbound':                'storeOutbound'

  constructor: ->
    super

    # redirect if we are not admin
    if !@authenticate(true)
      @navigate '#'
      return

    # set title
    @title 'Email Account'

    # store account settings
    @account =
      inbound:  {}
      outbound: {}
      meta:     {}

    @fetch()

  release: =>
    @el.removeClass('fit getstarted')

  fetch: ->

    # get data
    @ajax(
      id:    'getting_started',
      type:  'GET',
      url:   @apiPath + '/getting_started',
      processData: true,
      success: (data, status, xhr) =>

        # check if import is active
        if data.import_mode == true
          @navigate '#import/' + data.import_backend
          return

        # render page
        @render()
    )

  render: ->

    @html App.view('getting_started/email')()

    # outbound
    adapters =
      sendmail: 'Local MTA (Sendmail/Postfix/Exim/...) - use server setup'
      smtp:     'SMTP - configure your own outgoing SMTP settings'
    adapter_used = 'sendmail'
    configureAttributesOutbound = [
      { name: 'adapter', display: 'Send Mails via', tag: 'select', multiple: false, null: false, options: adapters , default: adapter_used },
    ]
    new App.ControllerForm(
      el:    @$('.base-outbound-type'),
      model: { configure_attributes: configureAttributesOutbound, className: '' },
    )
    @toggleAdapter()

    # inbound
    configureAttributesInbound = [
      { name: 'adapter',            display: 'Type',     tag: 'select',   multiple: false, null: false, options: { imap: 'IMAP', pop3: 'POP3' } },
      { name: 'options::host',      display: 'Host',     tag: 'input',    type: 'text', limit: 120, null: false, autocapitalize: false },
      { name: 'options::user',      display: 'User',     tag: 'input',    type: 'text', limit: 120, null: false, autocapitalize: false },
      { name: 'options::password',  display: 'Password', tag: 'input',    type: 'text', limit: 120, null: false, autocapitalize: false },
      { name: 'options::ssl',       display: 'SSL',      tag: 'select',   multiple: false, null: false, options: { true: 'yes', false: 'no' }, translate: true, default: true},
    ]
    new App.ControllerForm(
      el:    @$('.base-inbound-settings'),
      model: { configure_attributes: configureAttributesInbound, className: '' },
    )

  toggleAdapter: (channel_used = {}) =>
    adapter = @$('.js-outbound [name=adapter]').val()
    if adapter is 'smtp'
      configureAttributesOutbound = [
        { name: 'options::host',     display: 'Host',     tag: 'input',    type: 'text', limit: 120, null: false, autocapitalize: false, default: (channel_used['options']&&channel_used['options']['host']) },
        { name: 'options::user',     display: 'User',     tag: 'input',    type: 'text', limit: 120, null: true, autocapitalize: false, default: (channel_used['options']&&channel_used['options']['user']) },
        { name: 'options::password', display: 'Password', tag: 'input',    type: 'text', limit: 120, null: true, autocapitalize: false, default: (channel_used['options']&&channel_used['options']['password']) },
        { name: 'options::ssl',      display: 'SSL',      tag: 'select',   multiple: false, null: false, options: { true: 'yes', false: 'no' } , translate: true, default: (channel_used['options']&&channel_used['options']['ssl']||true) },
        { name: 'options::port',     display: 'Port',     tag: 'input',    type: 'text', limit: 5, null: false, class: 'span1', autocapitalize: false, default: ((channel_used['options']&&channel_used['options']['port']) || 25) },
      ]
      @form = new App.ControllerForm(
        el:    @$('.base-outbound-settings')
        model: { configure_attributes: configureAttributesOutbound, className: '' }
      )
    else
      @el.find('.base-outbound-settings').html('')

  emailProbe: (e) =>
    e.preventDefault()
    params = @formParam(e.target)

    # remember account settings
    @account.meta = params

    @disable(e)
    @$('.js-probe .js-email').text( params.email )
    @showSlide('js-probe')

    @ajax(
      id:   'email_probe'
      type: 'POST'
      url:  @apiPath + '/getting_started/email_probe'
      data: JSON.stringify( params )
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'
          if data.setting
            for key, value of data.setting
              @account[key] = value
          @verify(@account)
        else
          @showSlide('js-inbound')
        @enable(e)
      fail: =>
        @enable(e)
        @showSlide('js-intro')
    )

  showSlide: (name) =>
    @$('.setup.wizard').addClass('hide')
    @$(".setup.wizard.#{name}").removeClass('hide')

  storeOutbound: (e) =>
    e.preventDefault()

    # get params
    params          = @formParam(e.target)
    params['email'] = @account['meta']['email']
    @disable(e)

    @hideAlert('js-outbound')

    @ajax(
      id:   'email_outbound'
      type: 'POST'
      url:  @apiPath + '/getting_started/email_outbound'
      data: JSON.stringify( params )
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'

          # remember account settings
          @account.outbound = params

          @verify(@account)
        else
          @showAlert('js-outbound', data.message_human || data.message )
        @enable(e)
      fail: =>
        @enable(e)
    )

  storeInbound: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)
    @disable(e)

    @hideAlert('js-inbound')

    @ajax(
      id:   'email_inbound'
      type: 'POST'
      url:  @apiPath + '/getting_started/email_inbound'
      data: JSON.stringify( params )
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'
          @showSlide('js-outbound')

          # remember account settings
          @account.inbound = params
        else
          @showAlert('js-inbound', data.message_human || data.message )
        @enable(e)
      fail: =>
        @enable(e)
    )

  verify: (account) =>
    @showSlide('js-verify')

    @hideAlert('js-verify')

    @ajax(
      id:   'email_verify'
      type: 'POST'
      url:  @apiPath + '/getting_started/email_verify'
      data: JSON.stringify( account )
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'
          @navigate 'getting_started/agents'
        else
          @showAlert('js-verify', data.message_human || data.message )
        @enable(e)
      fail: =>
        @enable(e)
    )

  showAlert: (screen, message) =>
    @$(".#{screen}").find('.alert').removeClass('hide').text( App.i18n.translateInline( message ) )

  hideAlert: (screen) =>
    @$(".#{screen}").find('.alert').addClass('hide')

  disable: (e) =>
    @formDisable(e)
    @$('.wizard-controls .btn').attr('disabled', true)

  enable: (e) =>
    @formEnable(e)
    @$('.wizard-controls .btn').attr('disabled', false)

App.Config.set( 'getting_started/channel/email', ChannelEmail, 'Routes' )


class Agent extends App.ControllerContent
  className: 'getstarted fit'
  events:
    'submit form': 'submit'

  constructor: ->
    super

    return if !@authenticate()

    # set title
    @title 'Invite Agents'

    @fetch()

  release: =>
    @el.removeClass('fit getstarted')

  fetch: ->

    # get data
    @ajax(
      id:    'getting_started',
      type:  'GET',
      url:   @apiPath + '/getting_started',
      processData: true,
      success: (data, status, xhr) =>

        # check if import is active
        if data.import_mode == true
          @navigate '#import/' + data.import_backend
          return

        # load group collection
        App.Collection.load( type: 'Group', data: data.groups )

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
    @params.role_ids = [0]

    # set invite flag
    @params.invite = true

    # find agent role
    role = App.Role.findByAttribute( 'name', 'Agent' )
    if role
      @params.role_ids = role.id

    user = new App.User
    user.load(@params)

    errors = user.validate(
      screen: 'invite_agent'
    )
    if errors
      @log 'error new', errors
      @formValidate( form: e.target, errors: errors )
      @formEnable(e)
      return false

    # save user
    user.save(
      done: (r) =>
        App.Event.trigger 'notify', {
          type:    'success'
          msg:     App.i18n.translateContent( 'Invitation sent!' )
          timeout: 3500
        }

        # rerender page
        @render()

      fail: (data) =>
        @formEnable(e)
        App.Event.trigger 'notify', {
          type:    'error'
          msg:     App.i18n.translateContent( 'Can\'t create user!' )
          timeout: 2500
        }
    )

App.Config.set( 'getting_started/agents', Agent, 'Routes' )

class Channel extends App.ControllerContent
  className: 'getstarted fit'

  constructor: ->
    super

    return if !@authenticate()

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

App.Config.set( 'getting_started/finish', Channel, 'Routes' )