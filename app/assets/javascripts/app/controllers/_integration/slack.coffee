class Slack extends App.ControllerIntegrationBase
  featureIntegration: 'slack_integration'
  featureName: __('Slack')
  featureConfig: 'slack_config'
  description: [
    [__('This service sends notifications to your %s channel.'), 'Slack']
    [__('To set up this service you need to create a new |"Incoming webhook"| in your %s integration panel and enter the webhook URL below.'), 'Slack']
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
      create: __('1. Ticket Create')
      update: __('2. Ticket Update')
      reminder_reached: __('3. Ticket Reminder Reached')
      escalation: __('4. Ticket Escalation')
      escalation_warning: __('5. Ticket Escalation Warning')

    configureAttributes = [
      { name: 'types',     display: __('Trigger'),  tag: 'checkbox', options: options, translate: true, 'null': false, class: 'vertical', note: __('When notification is being sent.') },
      { name: 'group_ids', display: __('Group'),    tag: 'select', relation: 'Group', multiple: true, 'null': false, class: 'form-control--small', note: __('Only for these groups.') },
      { name: 'webhook',   display: __('Webhook'),  tag: 'input', type: 'url',  limit: 200, 'null': false, class: 'form-control--small', placeholder: 'https://hooks.slack.com/services/...' },
      { name: 'username',  display: __('Username'), tag: 'input', type: 'text', limit: 100, 'null': false, class: 'form-control--small', placeholder: 'username' },
      { name: 'channel',   display: __('Channel'),  tag: 'input', type: 'text', limit: 100, 'null': true, class: 'form-control--small', placeholder: '#channel' },
      { name: 'icon_url',  display: __('Icon URL'), tag: 'input', type: 'url',  limit: 200, 'null': true, class: 'form-control--small', placeholder: 'https://example.com/logo.png' },
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
      facility: 'slack_webhook'
    )

  update: (e) =>
    e.preventDefault()
    params = @formParam(e.target)
    value =
      items: [params]
    App.Setting.set(@featureConfig, value, {notify: true})

class State
  @current: ->
    App.Setting.get('slack_integration')

App.Config.set(
  'IntegrationSlack'
  {
    name: __('Slack')
    target: '#system/integration/slack'
    description: __('A team communication tool for the 21st century. Compatible with tools like %s.')
    descriptionSubstitute: __('Mattermost, RocketChat')
    controller: Slack
    state: State
  }
  'NavBarIntegrations'
)
