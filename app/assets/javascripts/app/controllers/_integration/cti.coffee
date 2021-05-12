class Cti extends App.ControllerIntegrationBase
  featureIntegration: 'cti_integration'
  featureName: 'CTI (generic)'
  featureConfig: 'cti_config'
  description: [
    ['This service shows you contacts of incoming calls and a caller list in realtime.']
    ['Also caller id of outbound calls can be changed.']
  ]
  events:
    'click .js-select': 'selectAll'
    'change .js-switch input': 'switch'

  render: =>
    super
    new Form(
      el: @$('.js-form')
    )

    new App.HttpLog(
      el: @$('.js-log')
      facility: 'cti'
    )

class Form extends App.Controller
  events:
    'submit form': 'update'
    'click .js-inboundBlockCallerId .js-add': 'addInboundBlockCallerId'
    'click .js-outboundRouting .js-add': 'addOutboundRouting'
    'click .js-notifyMap .js-addMap': 'addNotifyMap'
    'click .js-inboundBlockCallerId .js-remove': 'removeInboundBlockCallerId'
    'click .js-outboundRouting .js-remove': 'removeOutboundRouting'
    'click .js-notifyMap .js-removeMap': 'removeNotifyMap'

  constructor: ->
    super
    @render()

  currentConfig: ->
    config = App.Setting.get('cti_config')
    if !config.outbound
      config.outbound = {}
    if !config.outbound.routing_table
      config.outbound.routing_table = []
    if !config.inbound
      config.inbound = {}
    if !config.inbound.block_caller_ids
      config.inbound.block_caller_ids = []
    if !config.notify_map
      config.notify_map = []
    config

  setConfig: (value) ->
    App.Setting.set('cti_config', value, {notify: true})

  render: =>
    @config = @currentConfig()

    @html App.view('integration/cti')(
      config: @config
      cti_token: App.Setting.get('cti_token')
    )

    # placeholder
    configure_attributes = [
      { name: 'user_ids', display: '', tag: 'column_select', multiple: true, null: true, relation: 'User', sortBy: 'firstname' },
    ]
    new App.ControllerForm(
      el: @$('.js-userSelectorBlank')
      model:
        configure_attributes: configure_attributes,
      params:
        user_ids: []
      autofocus: false
    )

    configure_attributes = [
      {
        name: 'view_limit',
        display: '',
        tag: 'select',
        null: false,
        options: [
          { name: 60, value: 60 }
          { name: 120, value: 120 }
          { name: 180, value: 180 }
          { name: 240, value: 240 }
          { name: 300, value: 300 }
        ]
      },
    ]
    new App.ControllerForm(
      el: @$('.js-viewLimit')
      model:
        configure_attributes: configure_attributes,
      params:
        view_limit: @config['view_limit']
      autofocus: false
    )

    for row in @config.notify_map
      configure_attributes = [
        { name: 'user_ids', display: '', tag: 'column_select', multiple: true, null: true, relation: 'User', sortBy: 'firstname' },
      ]
      new App.ControllerForm(
        el: @$("[name=queue][value='#{row.queue}']").closest('tr').find('.js-userSelector')
        model:
          configure_attributes: configure_attributes,
        params:
          user_ids: row.user_ids
        autofocus: false
      )

  updateCurrentConfig: =>
    config = @config
    cleanupInput = @cleanupInput

    # default caller_id
    default_caller_id = @$('input[name=default_caller_id]').val()
    config.outbound.default_caller_id = cleanupInput(default_caller_id)

    # default view limit
    view_limit = @$('select[name=view_limit]').val()
    config.view_limit = parseInt(view_limit)

    # routing table
    config.outbound.routing_table = []
    @$('.js-outboundRouting .js-row').each(->
      dest = cleanupInput($(@).find('input[name="dest"]').val())
      caller_id = cleanupInput($(@).find('input[name="caller_id"]').val())
      note = $(@).find('input[name="note"]').val()
      config.outbound.routing_table.push {
        dest: dest
        caller_id: caller_id
        note: note
      }
    )

    # blocked caller ids
    config.inbound.block_caller_ids = []
    @$('.js-inboundBlockCallerId .js-row').each(->
      caller_id = $(@).find('input[name="caller_id"]').val()
      note = $(@).find('input[name="note"]').val()
      config.inbound.block_caller_ids.push {
        caller_id: cleanupInput(caller_id)
        note: note
      }
    )

    # notify map
    config.notify_map = []
    @$('.js-notifyMap .js-row').each(->
      queue = $(@).find('input[name="queue"]').val()
      user_ids = $(@).find('select[name="user_ids"]').val()
      config.notify_map.push {
        queue: cleanupInput(queue)
        user_ids: user_ids
      }
    )

    @config = config

  update: (e) =>
    e.preventDefault()
    @updateCurrentConfig()
    @setConfig(@config)

  cleanupInput: (value) ->
    return value if !value
    value.replace(/\s/g, '').trim()

  addInboundBlockCallerId: (e) =>
    e.preventDefault()
    @updateCurrentConfig()
    element = $(e.currentTarget).closest('tr')
    caller_id = element.find('input[name="caller_id"]').val()
    note = element.find('input[name="note"]').val()
    return if _.isEmpty(caller_id) || _.isEmpty(note)
    @config.inbound.block_caller_ids.push {
      caller_id: @cleanupInput(caller_id)
      note: note
    }
    @render()

  addOutboundRouting: (e) =>
    e.preventDefault()
    @updateCurrentConfig()
    element = $(e.currentTarget).closest('tr')
    dest = @cleanupInput(element.find('input[name="dest"]').val())
    caller_id = @cleanupInput(element.find('input[name="caller_id"]').val())
    note = element.find('input[name="note"]').val()
    return if _.isEmpty(caller_id) || _.isEmpty(dest) || _.isEmpty(note)
    @config.outbound.routing_table.push {
      dest: dest
      caller_id: caller_id
      note: note
    }
    @render()

  addNotifyMap: (e) =>
    e.preventDefault()
    @updateCurrentConfig()
    element = $(e.currentTarget).closest('tr')
    queue = @cleanupInput(element.find('input[name="queue"]').val())
    user_ids = element.find('select[name="user_ids"]').val()
    if _.isEmpty(queue)
      @notify(
        type:    'error'
        msg:     App.i18n.translateContent('A queue is required!')
        timeout: 6000
      )
      return
    if _.isEmpty(user_ids)
      @notify(
        type:    'error'
        msg:     App.i18n.translateContent('A user is required!')
        timeout: 6000
      )
      return

    for row in @config.notify_map
      if row.queue is queue
        @notify(
          type:    'error'
          msg:     App.i18n.translateContent('Queue already exists!')
          timeout: 6000
        )
        return
    @config.notify_map.push {
      queue: queue
      user_ids: user_ids
    }
    @render()

  removeInboundBlockCallerId: (e) =>
    e.preventDefault()
    @updateCurrentConfig()
    element = $(e.currentTarget).closest('tr')
    element.remove()
    @updateCurrentConfig()

  removeOutboundRouting: (e) =>
    e.preventDefault()
    @updateCurrentConfig()
    element = $(e.currentTarget).closest('tr')
    element.remove()
    @updateCurrentConfig()

  removeNotifyMap: (e) =>
    e.preventDefault()
    @updateCurrentConfig()
    element = $(e.currentTarget).closest('tr')
    element.remove()
    @updateCurrentConfig()

class State
  @current: ->
    App.Setting.get('cti_integration')

App.Config.set(
  'IntegrationCti'
  {
    name: 'CTI (generic)'
    target: '#system/integration/cti'
    description: 'Generic API to integrate VoIP service provider with realtime push.'
    controller: Cti
    state: State
  }
  'NavBarIntegrations'
)
