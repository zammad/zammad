$ = jQuery.sub()

$.fn.item = (genericObject) ->
  elementID   = $(@).data('id')
  elementID or= $(@).parents('[data-id]').data('id')
  genericObject.find(elementID)

class App.ChannelEmail extends App.ControllerTabs
  constructor: ->
    super

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
        name:   'Adresses',
        target: 'c-address',
      },
      {
        name:   'Filter',
        target: 'c-filter',
      },
      {
        name:       'Settings',
        target:     'c-setting',
        controller: App.SettingsArea, params: { area: 'Email::Base' },
      },
    ]

    @render()
    
class App.ChannelEmailInboundEdit extends App.ControllerModal
  constructor: ->
    super
    @render(@object)

  render: (data = {}) ->

    configure_attributes = [
      { name: 'adapter',  display: 'Type',     tag: 'select',   multiple: false, null: false, options: { IMAP: 'IMAP', POP3: 'POP3' } , class: 'span4', default: data['adapter'] },
      { name: 'host',     display: 'Host',     tag: 'input',    type: 'text', limit: 120, null: false, class: 'span4', autocapitalize: false, default: (data['options']&&data['options']['host']) },
      { name: 'user',     display: 'User',     tag: 'input',    type: 'text', limit: 120, null: false, class: 'span4', autocapitalize: false, default: (data['options']&&data['options']['user']) },
      { name: 'password', display: 'Password', tag: 'input',    type: 'password', limit: 120, null: false, class: 'span4', autocapitalize: false, default: (data['options']&&data['options']['password']) },
      { name: 'ssl',      display: 'SSL',      tag: 'select',   multiple: false, null: false, options: { true: 'yes', false: 'no' } , class: 'span4', default: (data['options']&&data['options']['ssl']) },
      { name: 'group_id', display: 'Group',    tag: 'select',   multiple: false, null: false, filter: @edit_form, nulloption: false, relation: 'Group', class: 'span4', default: data['group_id']  },
      { name: 'active',   display: 'Active',   tag: 'select',   multiple: false, null: false, options: { true: 'yes', false: 'no' } , class: 'span4', default: data['active'] },
    ]
    form = @formGen( model: { configure_attributes: configure_attributes, className: '' } )

    @html App.view('generic/admin/new')(
      form: form,
      head: 'New Channel'
    )
    @modalShow()

  submit: (e) =>
    e.preventDefault()
        
    # get params
    params = @formParam(e.target)

    object = @object || new App.Channel
    object.load(
      area:    'Email::Inbound',
      adapter:  params['adapter'],
      group_id: params['group_id'],
      options: {
        host:     params['host'],
        user:     params['user'],
        password: params['password'],
        ssl:      params['ssl'],
      },
      host:     params['host'],
      user:     params['user'],
      password: params['password'],
      active:   params['active'],
    )

    # validate form
    errors = object.validate()
    
    # show errors in form
    if errors
      @log 'error new', errors
      @validateForm( form: e.target, errors: errors )
      return false

    # save object
    object.save(
      success: =>
        @modalHide()
      error: =>
        @log 'errors'
        @modalHide()
    )


class App.ChannelEmailInbound extends App.Controller
  events:
    'click [data-type=new]':  'new'
    'click [data-type=edit]': 'edit'

  constructor: ->
    super

    App.Channel.bind 'refresh change', @render
    App.Channel.fetch()

  render: =>
    channels = App.Channel.all()
    
    html = $('<div></div>')
    data = []
    for channel in channels
      if channel.area is 'Email::Inbound'
        channel.host = channel.options['host']
        channel.user = channel.options['user']
        data.push channel

    table = @table(
      overview: ['host', 'user', 'adapter', 'active'],
      model:    App.Channel,
      objects:  data,
    )

    html.append( table )
    html.append( '<a data-type="new" class="btn">new account</a>' )
    @html html

  new: (e) =>
    e.preventDefault()
    new App.ChannelEmailInboundEdit()

  edit: (e) =>
    e.preventDefault()
    item = $(e.target).item( App.Channel )
    new App.ChannelEmailInboundEdit( object: item )


class App.ChannelEmailOutbound extends App.Controller
  events:
    'change #_adapter':     'toggle'
    'submit #mail_adapter': 'update'

  constructor: ->
    super

    App.Channel.bind 'refresh change', @render
    App.Channel.fetch()

  render: =>
    channels     = App.Channel.all()
    data         = []
    adapters     = {}
    adapter_used = undefined
    channel_used = undefined
    for channel in channels
      if channel.area is 'Email::Outbound'

        data.push channel
        adapters[channel.adapter] = channel.adapter
        if @adapter_used
          if @adapter_used is channel.adapter
            adapter_used = channel.adapter
            channel_used = channel
        else if channel.active is true
            adapter_used = channel.adapter
            channel_used = channel

    configure_attributes = [
      { name: 'adapter', display: 'Send Mails via', tag: 'select', multiple: false, null: false, options: adapters , class: 'span4', default: adapter_used },
    ]
    form_adapter = @formGen( model: { configure_attributes: configure_attributes, className: '' } )

    if adapter_used is 'SMTP'
      configure_attributes = [
        { name: 'host',     display: 'Host',     tag: 'input',    type: 'text', limit: 120, null: false, class: 'span4', autocapitalize: false, default: (channel_used['options']&&channel_used['options']['host']) },
        { name: 'user',     display: 'User',     tag: 'input',    type: 'text', limit: 120, null: true, class: 'span4', autocapitalize: false, default: (channel_used['options']&&channel_used['options']['user']) },
        { name: 'password', display: 'Password', tag: 'input',    type: 'password', limit: 120, null: true, class: 'span4', autocapitalize: false, default: (channel_used['options']&&channel_used['options']['password']) },
        { name: 'ssl',      display: 'SSL',      tag: 'select',   multiple: false, null: false, options: { true: 'yes', false: 'no' } , class: 'span4', default: (channel_used['options']&&channel_used['options']['ssl']) },
      ]
      form_adapter_settings = @formGen( model: { configure_attributes: configure_attributes, className: '' } )

    html = App.view('channel/email_outbound')(
      form_adapter:          form_adapter,
      form_adapter_settings: form_adapter_settings,
    )
    html = $(html)
    @html html

  toggle: (e) =>

    # get params
    params = @formParam(e.target)

    @adapter_used = params['adapter']

    @render()
    
  update: (e) =>
    e.preventDefault()
    params   = @formParam(e.target)
    channels = App.Channel.all()
    for channel in channels
      if channel.area is 'Email::Outbound' && channel.adapter is params['adapter']
        channel.updateAttributes(
          options: {
            host:     params['host'],
            user:     params['user'],
            password: params['password'],
            ssl:      params['ssl'],
          },
          active: true,
        )

    # set all other to inactive
    channels = App.Channel.all()
    for channel in channels
      if channel.area is 'Email::Outbound' && channel.adapter isnt params['adapter']
        channel.updateAttributes( active: false )

    # rerender
    @render()
