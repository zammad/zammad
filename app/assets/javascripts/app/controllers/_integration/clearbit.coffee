class Clearbit extends App.ControllerIntegrationBase
  featureIntegration: 'clearbit_integration'
  featureName: 'Clearbit'
  featureConfig: 'clearbit_config'
  description: [
    ['Automatically enrich your customers and organizations with fresh, up-to-date intel. Map data directly to object fields.
']
  ]

  render: =>
    super
    new Form(
      el: @$('.js-form')
    )

    new App.HttpLog(
      el: @$('.js-log')
      facility: 'clearbit'
    )

class Form extends App.Controller
  events:
    'submit form': 'update'
    'click .js-userSync .js-add': 'addUserSync'
    'click .js-organizationSync .js-add': 'addOrganizationSync'
    'click .js-userSync .js-remove': 'removeRow'
    'click .js-organizationSync .js-remove': 'removeRow'

  constructor: ->
    super
    @render()

  currentConfig: ->
    config = clone(App.Setting.get('clearbit_config'))
    if !config
      config = {}
    if config.organization_autocreate is undefined
      config.organization_autocreate = true
    if config.organization_shared is undefined
      config.organization_shared = false
    if !config.user_sync
      config.user_sync =
        'person.name.givenName': 'user.firstname'
        'person.name.familyName': 'user.lastname'
        'person.email': 'user.email'
        'person.bio': 'user.note'
        'company.url': 'user.web'
        'person.site': 'user.web'
        'company.location': 'user.address'
        'person.location': 'user.address'
    if !config.organization_sync
      config.organization_sync =
        'company.legalName': 'organization.name'
        'company.name': 'organization.name'
        'company.description': 'organization.note'
    config

  setConfig: (value) ->
    App.Setting.set('clearbit_config', value, {notify: true})

  render: =>
    if !@config
      @config = @currentConfig()
    settings = [
      { name: 'api_key', display: 'API Key', tag: 'input', type: 'text', limit: 100, null: false, placeholder: '...', note: 'Your api key.' },
      { name: 'organization_autocreate', display: 'Auto create', tag: 'boolean', type: 'boolean', null: false, note: 'Create organizations automatically if record has one.' },
      { name: 'organization_shared', display: 'Shared', tag: 'boolean', type: 'boolean', null: false, note: 'New organizations are shared.' },
    ]

    @html App.view('integration/clearbit')(
      config: @config
      settings: settings
    )

    for setting in settings
      setting.display = ''
      new App.ControllerForm(
        el: @$("[data-name=#{setting.name}]")
        model: { configure_attributes: [setting] }
        params: @config
      )

  updateCurrentConfig: =>
    config = @config
    cleanupInput = @cleanupInput

    params = @formParam(@$('form'))
    config.api_key = params['api_key']
    config.organization_autocreate = params['organization_autocreate']
    config.organization_shared = params['organization_shared']

    # user sync
    config.user_sync = {}
    @$('.js-userSync .js-row').each(->
      element = $(@)
      source = cleanupInput(element.find('input[name="source"]').val())
      destination = cleanupInput(element.find('input[name="destination"]').val())
      config.user_sync[source] = destination
    )

    # organization sync
    config.organization_sync = {}
    @$('.js-organizationSync .js-row').each(->
      element = $(@)
      source = cleanupInput(element.find('input[name="source"]').val())
      destination = cleanupInput(element.find('input[name="destination"]').val())
      config.organization_sync[source] = destination
    )

    @config = config

  update: (e) =>
    e.preventDefault()
    @updateCurrentConfig()
    @setConfig(@config)

  cleanupInput: (value) ->
    return value if !value
    value.replace(/\s/g, '').trim()

  addUserSync: (e) =>
    e.preventDefault()
    @updateCurrentConfig()
    element = $(e.currentTarget).closest('tr')
    source = @cleanupInput(element.find('input[name="source"]').val())
    destination = @cleanupInput(element.find('input[name="destination"]').val())
    return if _.isEmpty(source) || _.isEmpty(destination)
    @config.user_sync[source] = destination
    @render()

  addOrganizationSync: (e) =>
    e.preventDefault()
    @updateCurrentConfig()
    element = $(e.currentTarget).closest('tr')
    source = @cleanupInput(element.find('input[name="source"]').val())
    destination = @cleanupInput(element.find('input[name="destination"]').val())
    return if _.isEmpty(source) || _.isEmpty(destination)
    @config.organization_sync[source] = destination
    @render()

  removeRow: (e) =>
    e.preventDefault()
    @updateCurrentConfig()
    element = $(e.currentTarget).closest('tr')
    element.remove()
    @updateCurrentConfig()

class State
  @current: ->
    App.Setting.get('clearbit_integration')

App.Config.set(
  'IntegrationClearbit'
  {
    name: 'Clearbit'
    target: '#system/integration/clearbit'
    description: 'A powerful service to get more information about your customers.'
    controller: Clearbit
    state: State
    permission: ['admin.integration.clearbit']
  }
  'NavBarIntegrations'
)
