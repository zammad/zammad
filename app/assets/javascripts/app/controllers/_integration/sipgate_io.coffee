class SipgateIo extends App.ControllerIntegrationBase
  featureIntegration: 'sipgate_integration'
  featureName: 'sipgate.io'
  featureConfig: 'sipgate_config'
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
      facility: 'sipgate.io'
    )

class Form extends App.Controller
  events:
    'submit form': 'update'
    'click .js-inboundBlockCallerId .js-add': 'addInboundBlockCallerId'
    'click .js-outboundRouting .js-add': 'addOutboundRouting'
    'click .js-inboundBlockCallerId .js-remove': 'removeInboundBlockCallerId'
    'click .js-outboundRouting .js-remove': 'removeOutboundRouting'
    'click .js-userRemoteMap .js-add': 'addUserRemoteMap'
    'click .js-userRemoteMap .js-remove': 'removeUserRemoteMap'

  constructor: ->
    super
    @render()

  currentConfig: ->
    config = App.Setting.get('sipgate_config')
    if !config.outbound
      config.outbound = {}
    if !config.outbound.routing_table
      config.outbound.routing_table = []
    if !config.inbound
      config.inbound = {}
    if !config.inbound.block_caller_ids
      config.inbound.block_caller_ids = []
    if !config.user_remote_map
      config.user_remote_map = []
    config

  setConfig: (value) ->
    App.Setting.set('sipgate_config', value, {notify: true})

  render: =>
    @config = @currentConfig()

    @html App.view('integration/sipgate')(
      config: @config
    )

  updateCurrentConfig: =>
    config = @config
    cleanupInput = @cleanupInput

    config.api_user = cleanupInput(@$('input[name=api_user]').val())
    config.api_password = cleanupInput(@$('input[name=api_password]').val())

    # default caller_id
    default_caller_id = @$('input[name=default_caller_id]').val()
    config.outbound.default_caller_id = cleanupInput(default_caller_id)

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

    # user device map
    config.user_remote_map = []
    @$('.js-userRemoteMap .js-row').each(->
      remote_user_id = $(@).find('input[name="remote_user_id"]').val()
      user_id = $(@).find('input[name="user_id"]').val()
      config.user_remote_map.push {
        remote_user_id: remote_user_id
        user_id: user_id
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

  addUserRemoteMap: (e) =>
    e.preventDefault()
    @updateCurrentConfig()
    element = $(e.currentTarget).closest('tr')
    user_id = @cleanupInput(element.find('input[name="user_id"]').val())
    remote_user_id = @cleanupInput(element.find('input[name="remote_user_id"]').val())
    return if _.isEmpty(user_id) || _.isEmpty(remote_user_id)
    @config.user_remote_map.push {
      user_id: user_id
      remote_user_id: remote_user_id
    }
    @render()

  removeUserRemoteMap: (e) =>
    e.preventDefault()
    @updateCurrentConfig()
    element = $(e.currentTarget).closest('tr')
    element.remove()
    @updateCurrentConfig()

class State
  @current: ->
    App.Setting.get('sipgate_integration')

App.Config.set(
  'IntegrationSipgate'
  {
    name: 'sipgate.io'
    target: '#system/integration/sipgate'
    description: 'VoIP service provider with realtime push.'
    controller: SipgateIo
    state: State
  }
  'NavBarIntegrations'
)
