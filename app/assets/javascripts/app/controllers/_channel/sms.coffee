class ChannelSms extends App.ControllerTabs
  requiredPermission: 'admin.channel_sms'
  header: 'SMS'
  constructor: ->
    super

    @title 'SMS', true
    @tabs = [
      {
        name:       'Accounts',
        target:     'c-account',
        controller: ChannelSmsAccountOverview,
      },
    ]

    @render()

class ChannelSmsAccountOverview extends App.Controller
  events:
    'click .js-channelEdit': 'change'
    'click .js-channelDelete': 'delete'
    'click .js-channelDisable': 'disable'
    'click .js-channelEnable': 'enable'
    'click .js-editNotification': 'editNotification'

  constructor: ->
    super
    @interval(@load, 30000)
    #@load()

  load: =>

    @startLoading()

    @ajax(
      id:   'sms_index'
      type: 'GET'
      url:  "#{@apiPath}/channels_sms"
      processData: true
      success: (data, status, xhr) =>
        @config = data.config
        @stopLoading()
        App.Collection.loadAssets(data.assets)
        @render(data)
    )

  render: (data = {}) =>

    @channelDriver = data.channel_driver

    # get channels
    @account_channels = []
    for channel_id in data.account_channel_ids
      account_channel = App.Channel.fullLocal(channel_id)
      if account_channel.group_id
        account_channel.group = App.Group.find(account_channel.group_id)
      else
        account_channel.group = '-'
      @account_channels.push account_channel

    # get channels
    @notification_channels = []
    for channel_id in data.notification_channel_ids
      @notification_channels.push App.Channel.find(channel_id)

    @html App.view('channel/sms_account_overview')(
      account_channels:      @account_channels
      notification_channels: @notification_channels
      config:                @config
    )

  change: (e) =>
    e.preventDefault()
    id = $(e.target).closest('.action').data('id')
    if !id
      channel = new App.Channel(active: true)
    else
      channel = App.Channel.find(id)
    new ChannelSmsAccount(
      container:     @el.closest('.content')
      channel:       channel
      callback:      @load
      channelDriver: @channelDriver
      config:        @config
    )

  delete: (e) =>
    e.preventDefault()
    id = $(e.target).closest('.action').data('id')
    channel = App.Channel.find(id)
    new App.ControllerGenericDestroyConfirm(
      item: channel
      options:
        url: "/api/v1/channels_sms/#{channel.id}"
      container: @el.closest('.content')
      callback: =>
        @load()
    )

  disable: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    @ajax(
      id:   'sms_disable'
      type: 'POST'
      url:  "#{@apiPath}/channels_sms_disable"
      data: JSON.stringify(id: id)
      processData: true
      success: =>
        @load()
    )

  enable: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    @ajax(
      id:   'sms_enable'
      type: 'POST'
      url:  "#{@apiPath}/channels_sms_enable"
      data: JSON.stringify(id: id)
      processData: true
      success: =>
        @load()
    )

  editNotification: (e) =>
    e.preventDefault()
    id      = $(e.target).closest('.action').data('id')
    channel = App.Channel.find(id)
    new ChannelSmsNotification(
      container:     @el.closest('.content')
      channel:       channel
      callback:      @load
      channelDriver: @channelDriver
      config:        @config
    )

class ChannelSmsAccount extends App.ControllerModal
  head: 'SMS Account'
  buttonCancel: true
  centerButtons: [
    {
      text: 'Test'
      className: 'js-test'
    }
  ]
  elements:
    'form': 'form'
    'select[name="options::adapter"]': 'adapterSelect'
  events:
    'click .js-test': 'onTest'

  content: ->
    el = $('<div><div class="js-channelAdapterSelector"></div><div class="js-channelWebhook"></div><div class="js-channelAdapterOptions"></div></div>')

    # form
    options = {}
    currentConfig = {}
    for config in @config
      if config.account
        options[config.adapter] = config.name

    form = new App.ControllerForm(
      el: el.find('.js-channelAdapterSelector')
      model:
        configure_attributes: [
          { name: 'options::adapter', display: 'Provider', tag: 'select', null: false, options: options, nulloption: true }
        ]
        className: ''
      params: @channel
    )
    @renderAdapterOptions(@channel.options?.adapter, el)
    el.find('[name="options::adapter"]').bind('change', (e) =>
      @renderAdapterOptions(e.target.value, el)
    )
    el

  renderAdapterOptions: (adapter, el) ->
    el.find('.js-channelWebhook').html('')
    el.find('.js-channelAdapterOptions').html('')

    currentConfig = {}
    for configuration in @config
      if configuration.adapter is adapter
        if configuration.account
          currentConfig = configuration.account
    return if _.isEmpty(currentConfig)

    if _.isEmpty(@channel.options) || _.isEmpty(@channel.options.webhook_token)
      @channel.options ||= {}
      @channel.options.webhook_token = '?'
      for localCurrentConfig in currentConfig
        if localCurrentConfig.name is 'options::webhook_token'
          @channel.options.webhook_token = localCurrentConfig.default

    webhook = "#{@Config.get('http_type')}://#{@Config.get('fqdn')}/api/v1/sms_webhook/#{@channel.options?.webhook_token}"
    new App.ControllerForm(
      el: el.find('.js-channelWebhook')
      model:
        configure_attributes: [
          { name: 'options::webhook', display: 'Webhook', tag: 'input', type: 'text', limit: 200, null: false, default: webhook, disabled: true },
        ]
        className: ''
      params: @channel
    )

    new App.ControllerForm(
      el: el.find('.js-channelAdapterOptions')
      model:
        configure_attributes: currentConfig
        className: ''
      params: @channel
    )

  onDelete: =>
    if @channel.isNew() is true
      @close()
      @callback()
      return

    new App.ControllerGenericDestroyConfirm(
      item: @channel
      options:
        url: "/api/v1/channels_sms/#{@channel.id}"
      container: @el.closest('.content')
      callback: =>
        @close()
        @callback()
    )

  onSubmit: (e) ->
    e.preventDefault()

    if @adapterSelect.val() is ''
      @onDelete()
      return

    @formDisable(e)

    @channel.options ||= {}
    for key, value of @formParam(@el)
      if key is 'options'
        for optionsKey, optionsValue of value
          @channel.options ||= {}
          @channel.options[optionsKey] = optionsValue
      else
        @channel[key] = value
    @channel.area = 'Sms::Account'

    url = '/api/v1/channels_sms'
    if !@channel.isNew()
      url = "/api/v1/channels_sms/#{@channel.id}"

    ui = @
    @channel.save(
      url: url
      done: ->
        ui.formEnable(e)
        ui.channel = App.Channel.find(@id)
        ui.close()
        ui.callback()
      fail: (settings, details) ->
        ui.log 'errors', details
        ui.formEnable(e)
        ui.showAlert(details.error_human || details.error || 'Unable to update object!')
    )

  onTest: (e) ->
    e.preventDefault()
    new TestModal(
      channel:   @formParam(@el)
      container: @el.closest('.content')
    )

class ChannelSmsNotification extends App.ControllerModal
  head: 'SMS Notification'
  buttonCancel: true
  centerButtons: [
    {
      text: 'Test'
      className: 'js-test'
    }
  ]
  elements:
    'form': 'form'
    'select[name="options::adapter"]': 'adapterSelect'
  events:
    'click .js-test': 'onTest'

  content: ->
    el = $('<div><div class="js-channelAdapterSelector"></div><div class="js-channelAdapterOptions"></div></div>')
    if !@channel
      @channel = new App.Channel(active: true)

    # form
    options = {}
    currentConfig = {}
    for config in @config
      if config.notification
        options[config.adapter] = config.name

    form = new App.ControllerForm(
      el: el.find('.js-channelAdapterSelector')
      model:
        configure_attributes: [
          { name: 'options::adapter', display: 'Provider', tag: 'select', null: false, options: options, nulloption: true }
        ]
        className: ''
      params: @channel
    )
    @renderAdapterOptions(@channel.options?.adapter, el)
    el.find('[name="options::adapter"]').bind('change', (e) =>
      @renderAdapterOptions(e.target.value, el)
    )
    el

  renderAdapterOptions: (adapter, el) ->
    el.find('.js-channelAdapterOptions').html('')

    currentConfig = {}
    for configuration in @config
      if configuration.adapter is adapter
        if configuration.notification
          currentConfig = configuration.notification
    return if _.isEmpty(currentConfig)

    new App.ControllerForm(
      el: el.find('.js-channelAdapterOptions')
      model:
        configure_attributes: currentConfig
        className: ''
      params: @channel
    )

  onDelete: =>
    if @channel.isNew() is true
      @close()
      @callback()
      return

    new App.ControllerGenericDestroyConfirm(
      item: @channel
      options:
        url: "/api/v1/channels_sms/#{@channel.id}"
      container: @el.closest('.content')
      callback: =>
        @close()
        @callback()
    )

  onSubmit: (e) ->
    e.preventDefault()

    if @adapterSelect.val() is ''
      @onDelete()
      return

    @formDisable(e)

    @channel.options ||= {}
    for key, value of @formParam(@el)
      @channel[key] = value
    @channel.area = 'Sms::Notification'

    url = '/api/v1/channels_sms'
    if !@channel.isNew()
      url = "/api/v1/channels_sms/#{@channel.id}"
    ui = @
    @channel.save(
      url: url
      done: ->
        ui.formEnable(e)
        ui.channel = App.Channel.find(@id)
        ui.close()
        ui.callback()
      fail: (settings, details) ->
        ui.log 'errors', details
        ui.formEnable(e)
        ui.showAlert(details.error_human || details.error || 'Unable to update object!')
    )

  onTest: (e) ->
    e.preventDefault()
    new TestModal(
      channel:   @formParam(@el)
      container: @el.closest('.content')
    )

class TestModal extends App.ControllerModal
  head: 'Test SMS provider'
  buttonCancel: true

  content: ->
    form = new App.ControllerForm(
      model:
        configure_attributes: [
          { name: 'recipient', display: 'Recipient', tag: 'input', null: false }
          { name: 'message', display: 'Message', tag: 'input', null: false, default: 'Test message from Zammad' }
        ]
        className: ''
    )
    form.form

  T: (name) ->
    App.i18n.translateInline(name)

  submit: (e) ->
    super(e)

    @el.find('.js-danger').addClass('hide')
    @el.find('.js-success').addClass('hide')
    @formDisable(@el)

    testData = _.extend(
      @formParam(e.currentTarget),
      options: @channel.options
    )

    @ajax(
      type: 'POST'
      url:  "#{@apiPath}/channels_sms/test"
      data: JSON.stringify(testData)
      processData: true
      success: (data) =>
        @formEnable(@el)
        if error_text = (data.error || data.error_human)
          @el.find('.js-danger')
            .text(@T(error_text))
            .removeClass('hide')
        else
          @el.find('.js-success')
            .text(@T('SMS successfully sent'))
            .removeClass('hide')
      error: (xhr) =>
        data = JSON.parse(xhr.responseText)
        @formEnable(@el)
        @el.find('.js-danger')
          .text(@T(data.error || 'Unable to perform test'))
          .removeClass('hide')
    )

App.Config.set('SMS', { prio: 3100, name: 'SMS', parent: '#channels', target: '#channels/sms', controller: ChannelSms, permission: ['admin.channel_sms'] }, 'NavBarAdmin')
