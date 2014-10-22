class Index extends App.ControllerContent
  className: 'getstarted fit'

  constructor: ->
    super

    if @authenticate(true)
      @navigate '#'

    # set title
    @title 'Get Started'

    @fetch()

  release: =>
    @el.removeClass('fit').removeClass('getstarted')

  fetch: ->

    # get data
    @ajax(
      id:    'getting_started',
      type:  'GET',
      url:   @apiPath + '/getting_started',
      processData: true,
      success: (data, status, xhr) =>

        # redirect to login if master user already exists
        if data.setup_done
          @navigate '#login'
          return

        # render page
        @render()
    )

  render: ->

    @html App.view('getting_started/index')()

App.Config.set( 'getting_started', Index, 'Routes' )


class Base extends App.ControllerContent
  className: 'getstarted fit'
  events:
    'change [name=adapter]':     'toggleAdapter'
    'submit .base':              'storeUrl'
    'submit .base-outbound':     'storeOutbound'
    'submit .base-inbound':      'storeInbound'
    'click  .js-next':           'submit'

  constructor: ->
    super

    if @authenticate(true)
      @navigate '#'

    # set title
    @title 'Configure Base'

    @fetch()

  release: =>
    @el.removeClass('fit').removeClass('getstarted')

  fetch: ->

    # get data
    @ajax(
      id:    'getting_started',
      type:  'GET',
      url:   @apiPath + '/getting_started',
      processData: true,
      success: (data, status, xhr) =>

        # redirect to login if master user already exists
        if data.setup_done
          @navigate '#login'
          return

        # render page
        @render()
    )

  render: ->

    @html App.view('getting_started/base')()

    # url
    configureAttributesBase = [
      { name: 'url', display: 'System URL (where the system can be reached)', tag: 'input', null: false, placeholder: 'http://yourhost' },
    ]
    new App.ControllerForm(
      el: @$('.base-url'),
      model: { configure_attributes: configureAttributesBase, className: '' },
    )

    # outbound
    adapters =
      sendmail: 'Local MTA (Sendmail/Postfix/Exim/...)'
      smtp: 'SMTP'
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
      { name: 'email',              display: 'Email',    tag: 'input',    type: 'text', limit: 200, null: false, autocapitalize: false, default: '' },
      { name: 'adapter',            display: 'Type',     tag: 'select',   multiple: false, null: false, options: { IMAP: 'IMAP', POP3: 'POP3' } },
      { name: 'options::host',      display: 'Host',     tag: 'input',    type: 'text', limit: 120, null: false, autocapitalize: false },
      { name: 'options::user',      display: 'User',     tag: 'input',    type: 'text', limit: 120, null: false, autocapitalize: false },
      { name: 'options::password',  display: 'Password', tag: 'input',    type: 'text', limit: 120, null: false, autocapitalize: false },
      { name: 'options::ssl',       display: 'SSL',      tag: 'select',   multiple: false, null: false, options: { true: 'yes', false: 'no' }, translate: true, default: true},
    ]
    new App.ControllerForm(
      el: @$('.base-inbound-settings'),
      model: { configure_attributes: configureAttributesInbound, className: '' },
    )

  toggleAdapter: (channel_used = {}) =>
    adapter = @$('[name=adapter]').val()
    if adapter is 'smtp'
      configureAttributesOutbound = [
        { name: 'options::host',     display: 'Host',     tag: 'input',    type: 'text', limit: 120, null: false, autocapitalize: false, default: (channel_used['options']&&channel_used['options']['host']) },
        { name: 'options::user',     display: 'User',     tag: 'input',    type: 'text', limit: 120, null: true, autocapitalize: false, default: (channel_used['options']&&channel_used['options']['user']) },
        { name: 'options::password', display: 'Password', tag: 'input',    type: 'text', limit: 120, null: true, autocapitalize: false, default: (channel_used['options']&&channel_used['options']['password']) },
        { name: 'options::ssl',      display: 'SSL',      tag: 'select',   multiple: false, null: false, options: { true: 'yes', false: 'no' } , translate: true, default: (channel_used['options']&&channel_used['options']['ssl']||true) },
        { name: 'options::port',     display: 'Port',     tag: 'input',    type: 'text', limit: 5, null: false, class: 'span1', autocapitalize: false, default: ((channel_used['options']&&channel_used['options']['port']) || 25) },
      ]
      @form = new App.ControllerForm(
        el: @$('.base-outbound-settings')
        model: { configure_attributes: configureAttributesOutbound, className: '' }
        autofocus: true
      )
    else
      @el.find('.base-outbound-settings').html('')

  submit: (e) =>
    e.preventDefault()
    form = $(e.target).attr('data-form')
    console.log('submit', form)
    @$(".#{form}").trigger('submit')

  showOutbound: =>
    @$('.base').addClass('hide')
    @$('.base-outbound').removeClass('hide')
    @$('.base-inbound').addClass('hide')
    @$('.wizard-controls .btn').text('Check').attr('data-form', 'base-outbound').addClass('btn--primary').removeClass('btn--danger').removeClass('btn--success')
    @enable( @$('.btn') )

  showInbound: =>
    @$('.base').addClass('hide')
    @$('.base-outbound').addClass('hide')
    @$('.base-inbound').removeClass('hide')
    @$('.wizard-controls .btn').text('Check').attr('data-form', 'base-inbound').addClass('btn--primary').removeClass('btn--danger').removeClass('btn--success')
    @enable( @$('.btn') )

  storeUrl: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)
    console.log('submit', params, e)
    @disable(e)

    @ajax(
      id:   'base_url'
      type: 'POST'
      url:  @apiPath + '/getting_started/base_url'
      data: JSON.stringify( {url:params.url} )
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'
          @$('.wizard-controls .btn').text('Done').removeClass('btn--primary').removeClass('btn--danger').addClass('btn--success')
          @delay( @showOutbound, 1500 )
        else
          @$('.wizard-controls .btn').text( data.message_human || data.message ).addClass('btn--danger').removeClass('btn--primary').removeClass('btn--success')
          @enable(e)
      fail: =>
        @enable(e)
    )

  storeOutbound: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)
    @disable(e)

    @ajax(
      id:   'base_outbound'
      type: 'POST'
      url:  @apiPath + '/getting_started/base_outbound'
      data: JSON.stringify( params )
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'
          @$('.wizard-controls .btn').text('Done').removeClass('btn--primary').removeClass('btn--danger').addClass('btn--success')
          @delay( @showInbound, 1500 )
        else
          @$('.wizard-controls .btn').text( data.message_human || data.message ).addClass('btn--danger').removeClass('btn--primary').removeClass('btn--success')
          @enable(e)
      fail: =>
        @enable(e)
    )

  storeInbound: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)
    @disable(e)

    console.log('PA', params)

    @ajax(
      id:   'base_inbound'
      type: 'POST'
      url:  @apiPath + '/getting_started/base_inbound'
      data: JSON.stringify( params )
      processData: true
      success: (data, status, xhr) =>

        if data.result is 'ok'
          @$('.wizard-controls .btn').text('Done').removeClass('btn--primary').removeClass('btn--danger').addClass('btn--success')
          @delay( @goToAdmin, 1500 )
        else
          @$('.wizard-controls .btn').text( data.message_human || data.message ).addClass('btn--danger').removeClass('btn--primary').removeClass('btn--success')
        @enable(e)
      fail: =>
        @enable(e)
    )

  disable: (e) =>
    @formDisable(e)
    @$('.wizard-controls .btn').attr('disabled', true)

  enable: (e) =>
    @formEnable(e)
    @$('.wizard-controls .btn').attr('disabled', false)

  goToAdmin: =>
    @navigate 'getting_started/admin'

App.Config.set( 'getting_started/base', Base, 'Routes' )


class Admin extends App.ControllerContent
  className: 'getstarted fit'
  events:
    'submit .js-admin':         'submit'

  constructor: ->
    super

    if @authenticate(true)
      @navigate '#'

    # set title
    @title 'Create Admin'

    @fetch()

  release: =>
    @el.removeClass('fit').removeClass('getstarted')

  fetch: ->

    # get data
    @ajax(
      id:    'getting_started',
      type:  'GET',
      url:   @apiPath + '/getting_started',
      data:  {
#        view:       @view,
      }
      processData: true,
      success: (data, status, xhr) =>

        # redirect to login if master user already exists
        if data.setup_done
          @navigate '#login'
          return

        # load group collection
        App.Collection.load( type: 'Group', data: data.groups )

        # render page
        @render()
    )

  render: ->

    @html App.view('getting_started/admin')()

    new App.ControllerForm(
      el:        @$('.js-admin')
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

    # add notify
    App.Event.trigger 'notify:removeall'

    @navigate 'getting_started/agents'

App.Config.set( 'getting_started/admin', Admin, 'Routes' )

class Agent extends App.ControllerContent
  className: 'getstarted'
  events:
    'submit .js-agent':         'submit'

  constructor: ->
    super

    return if !@authenticate()

    # set title
    @title 'Invite Agents'

    @fetch()


  release: =>
    @el.removeClass('fit').removeClass('getstarted')

  fetch: ->

    # get data
    @ajax(
      id:    'getting_started',
      type:  'GET',
      url:   @apiPath + '/getting_started',
      data:  {
#        view:       @view,
      }
      processData: true,
      success: (data, status, xhr) =>

        # redirect to login if master user already exists
        if !data.setup_done
          @navigate '#getting_started/admin'
          return

        # load group collection
        App.Collection.load( type: 'Group', data: data.groups )

        # render page
        @render()
    )

  render: ->

    @html App.view('getting_started/agent')()

    new App.ControllerForm(
      el:        @$('.js-agent')
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

class Import extends App.ControllerContent
  className: 'getstarted fit'

  constructor: ->
    super

    # set title
    @title 'Import'

    @fetch()

  fetch: ->

    # get data
    @ajax(
      id:    'getting_started',
      type:  'GET',
      url:   @apiPath + '/getting_started',
      data:  {
#        view:       @view,
      }
      processData: true,
      success: (data, status, xhr) =>

        # redirect to login if master user already exists
        if data.setup_done
          @navigate '#login'
          return

        # render page
        @render()
    )

  render: ->

    @html App.view('getting_started/import')()

App.Config.set( 'getting_started/import', Import, 'Routes' )
