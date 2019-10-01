class Index extends App.ControllerIntegrationBase
  featureIntegration: 'rocketchat_integration'
  featureName: 'Rocketchat'
  featureConfig: 'rocketchat_config'
  description: [
    ['This service sends direct messages to user mentioned in articles with @username.', 'Rocketchat']
    ['To set up this service you need to create a user acting as bot to send direct messages', 'Rocketchat']
  ]
  events:
    'click .js-submit': 'update'
    'submit .js-form': 'update'
    'change .js-switch input': 'switch'

  render: =>
    super

    params = App.Setting.get(@featureConfig)
    if params && params.items
      params = params.items[0] || {}

    options =
      create: '1. Ticket Create'
      update: '2. Ticket Update'
      reminder_reached: '3. Ticket Reminder Reached'
      escalation: '4. Ticket Escalation'
      escalation_warning: '5. Ticket Escalation Warning'

    configureAttributes = [
      { name: 'webhook',   display: 'Webhook',  tag: 'input', type: 'url',  limit: 200, 'null': false, placeholder: 'https://support.mycompany.org' },
      { name: 'types',     display: 'Trigger',  tag: 'checkbox', options: options, 'null': false, class: 'vertical', note: 'When notification is being sent.' },
      { name: 'username',  display: 'Username', tag: 'input', type: 'text', limit: 100, 'null': false, placeholder: 'username' },
      { name: 'password',  display: 'Password', tag: 'input', type: 'password', limit: 100, 'null': false, placeholder: 'password' },
      { name: 'channel',  display: 'Channel', tag: 'input', type: 'text', limit: 100, 'null': false, placeholder: '#general' },
      { name: 'icon_url',  display: 'Icon Url', tag: 'input', type: 'url',  limit: 200, 'null': true, placeholder: 'https://example.com/logo.png' },
   ]

    settings = []
    for item in configureAttributes
      setting =
        options:
          form: [item]
        name: item.name
        description: item.note || ''
        title: item.display
      settings.push setting

    formEl = $( App.view('settings/form')(
      settings: settings
    ))

    for setting in settings
      configure_attribute = setting.options['form']
      configure_attribute[0].display = ''
      value = params[setting.name]
      localParams = {}
      localParams[setting.name] = value
      new App.ControllerForm(
        el: formEl.find("[data-name=#{setting.name}]")
        model: { configure_attributes: configure_attribute, className: '' }
        params: localParams
      )

    @$('.js-form').html(formEl)

    new App.HttpLog(
      el: @$('.js-log')
      facility: 'rocketchat_webhook'
    )

  update: (e) =>
    e.preventDefault()
    params = @formParam(e.target)
    value =
      items: [params]
    App.Setting.set(@featureConfig, value, {notify: true})

class State
  @current: ->
    App.Setting.get('rocketchat_integration')

App.Config.set(
  'IntegrationRocketchat'
  {
    name: 'Rocketchat'
    target: '#system/integration/rocketchat'
    description: 'An opensource chat.'
    controller: Index
    state: State
  }
  'NavBarIntegrations'
)
