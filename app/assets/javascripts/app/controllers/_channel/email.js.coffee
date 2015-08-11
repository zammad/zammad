class App.ChannelEmail extends App.ControllerTabs
  header: 'Email'
  constructor: ->
    super

    @title 'Email', true

    @tabs = [
      {
        name:       'Inbound',
        target:     'c-inbound',
        controller: App.ChannelEmailInbound,
      },
      {
        name:       'Outbound',
        target:     'c-outbound',
        controller: App.ChannelEmailOutbound,
      },
      {
        name:       'Adresses',
        target:     'c-address',
        controller: App.ChannelEmailAddress,
      },
      {
        name:       'Signatures',
        target:     'c-signature',
        controller: App.ChannelEmailSignature,
      },
      {
        name:       'Filter',
        target:     'c-filter',
        controller: App.ChannelEmailFilter,
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


class App.ChannelEmailAddress extends App.Controller
  events:
    'click [data-type=new]':  'new'

  constructor: ->
    super

    App.EmailAddress.subscribe( @render, initFetch: true )

  render: =>
    data = App.EmailAddress.search( sortBy: 'realname' )

    template = $( '<div><div class="overview"></div><a data-type="new" class="btn btn--success">' + App.i18n.translateContent('New') + '</a></div>' )

    new App.ControllerTable(
      el:       template.find('.overview')
      model:    App.EmailAddress
      objects:  data
      bindRow:
        events:
          'click': @edit
    )

    @html template

  new: (e) =>
    e.preventDefault()
    new App.ChannelEmailAddressEdit(
      container: @el.closest('.content')
    )

  edit: (id, e) =>
    e.preventDefault()
    item = App.EmailAddress.find(id)
    new App.ChannelEmailAddressEdit(
      object:    item
      container: @el.closest('.content')
    )

class App.ChannelEmailAddressEdit extends App.ControllerModal
  constructor: ->
    super

    @head   = 'Email-Address'
    @button = true
    @close  = true
    @cancel = true

    if @object
      @form = new App.ControllerForm(
        model:     App.EmailAddress
        params:    @object
        autofocus: true
      )
    else
      @form = new App.ControllerForm(
        model:     App.EmailAddress,
        autofocus: true,
      )

    @content = @form.form

    @show()

  onSubmit: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)

    object = @object || new App.EmailAddress
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

class App.ChannelEmailInbound extends App.Controller
  events:
    'click [data-type=new]':  'new'

  constructor: ->
    super
    App.Channel.subscribe( @render, initFetch: true )

  render: =>
    channels = App.Channel.search( filter: { area: 'Email::Inbound' } )

    template = $( '<div><div class="overview"></div><a data-type="new" class="btn btn--success">' + App.i18n.translateContent('New') + '</a></div>' )

    new App.ControllerTable(
      el:       template.find('.overview')
      model:    App.Channel
      objects:  channels
      bindRow:
        events:
          'click': @edit
    )
    @html template

  new: (e) =>
    e.preventDefault()
    new App.ChannelEmailInboundEdit(
      container: @el.closest('.content')
    )

  edit: (id, e) =>
    e.preventDefault()
    item = App.Channel.find(id)
    new App.ChannelEmailInboundEdit(
      object:    item
      container: @el.closest('.content')
    )


class App.ChannelEmailInboundEdit extends App.ControllerModal
  constructor: ->
    super

    @head   = 'Email Channel'
    @button = true
    @close  = true
    @cancel = true

    if @object
      @form = new App.ControllerForm(
        model:     App.Channel
        params:    @object
        autofocus: true
      )
    else
      @form = new App.ControllerForm(
        model:     App.Channel
        autofocus: true
      )

    @content = @form.form

    @show()

  onSubmit: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)
    params['area'] = 'Email::Inbound'

    object = @object || new App.Channel
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

class App.ChannelEmailOutbound extends App.Controller
  events:
    'change [name="adapter"]': 'toggle'
    'submit #mail_adapter':    'update'

  constructor: ->
    super

    App.Channel.subscribe( @render, initFetch: true )

  render: =>

    @html App.view('channel/email_outbound')()

    # get current Email::Outbound channel
    channels     = App.Channel.all()
    adapters     = {}
    adapter_used = undefined
    channel_used = undefined
    for channel in channels
      if channel.area is 'Email::Outbound'

        adapters[channel.adapter] = channel.adapter
        if @adapter_used
          if @adapter_used is channel.adapter
            adapter_used = channel.adapter
            channel_used = channel
        else if channel.active is true
            adapter_used = channel.adapter
            channel_used = channel

    configure_attributes = [
      { name: 'adapter', display: 'Send Mails via', tag: 'select', multiple: false, null: false, options: adapters , default: adapter_used },
    ]
    new App.ControllerForm(
      el: @el.find('#form-email-adapter'),
      model: { configure_attributes: configure_attributes, className: '' },
      autofocus: true,
    )

#    if adapter_used is 'Sendmail'
#      # some form

    if adapter_used is 'SMTP'
      configure_attributes = [
        { name: 'host',     display: 'Host',     tag: 'input',    type: 'text', limit: 120, null: false, autocapitalize: false, default: (channel_used['options']&&channel_used['options']['host']) },
        { name: 'user',     display: 'User',     tag: 'input',    type: 'text', limit: 120, null: true, autocapitalize: false, default: (channel_used['options']&&channel_used['options']['user']) },
        { name: 'password', display: 'Password', tag: 'input',    type: 'password', limit: 120, null: true, autocapitalize: false, default: (channel_used['options']&&channel_used['options']['password']) },
        { name: 'ssl',      display: 'SSL',      tag: 'select',   multiple: false, null: false, options: { true: 'yes', false: 'no' } , translate: true, default: (channel_used['options']&&channel_used['options']['ssl']) },
        { name: 'port',     display: 'Port',     tag: 'input',    type: 'text', limit: 5, null: false, class: 'span1', autocapitalize: false, default: ((channel_used['options']&&channel_used['options']['port']) || 25) },
      ]
      @form = new App.ControllerForm(
        el: @el.find('#form-email-adapter-settings'),
        model: { configure_attributes: configure_attributes, className: '' },
        autofocus: true,
      )

  toggle: (e) =>

    # get params
    params = @formParam(e.target)

    # render page with new selected adapter
    if @adapter_used isnt params['adapter']

      # set selected adapter
      @adapter_used = params['adapter']

      @render()

  update: (e) =>
    e.preventDefault()
    params   = @formParam(e.target)

#    errors = @form.validate( params )

    # update Email::Outbound adapter
    channels = App.Channel.all()
    for channel in channels
      if channel.area is 'Email::Outbound' && channel.adapter is params['adapter']
        channel.updateAttributes(
          options: {
            host:     params['host'],
            user:     params['user'],
            password: params['password'],
            ssl:      params['ssl'],
            port:     params['port'],
          },
          active: true,
        )

    # set all other Email::Outbound adapters to inactive
    channels = App.Channel.all()
    for channel in channels
      if channel.area is 'Email::Outbound' && channel.adapter isnt params['adapter']
        channel.updateAttributes( active: false )

