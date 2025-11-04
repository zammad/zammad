class App.TicketSummary extends App.ControllerAIFeatureBase
  header: __('Ticket Summary')
  description: __('Ticket Summary provides the functionality to summarize the current ticket state. It will provide a new sidebar which contains information to reduce reading time in the ticket with a summarized version of the problem, open questions and upcoming events.')
  requiredPermission: 'admin.ai_assistance_ticket_summary'
  events:
    'change .js-aiAssistanceTicketSummarySetting input': 'toggleAIAssistanceTicketSummarySetting'
    'change .checkbox--service input': 'toggleService'
    'submit .js-ticketSummaryGenerationConfig': 'selectGenerationConfig'

  elements:
    '.js-aiAssistanceTicketSummarySetting input': 'aiAssistanceTicketSummarySetting'

  constructor: ->
    super

    @controllerBind('config_update', (data) =>
      if data.name == 'ai_assistance_ticket_summary'
        @renderAlert()
        @aiAssistanceTicketSummarySetting.prop('checked', App.Config.get('ai_assistance_ticket_summary'))
      else if data.name == 'ai_assistance_ticket_summary_config'
        for key, value of data.value
          field = @$("[name='#{key}']")

          if field.is('select')
            field.val(value)
          else
            field.prop('checked', value)
    )

  showAlert: ->
    App.Config.get('ai_assistance_ticket_summary') && !App.Config.get('ai_provider')

  render: =>
    service_config = App.Setting.get('ai_assistance_ticket_summary_config') || {}

    content = $(App.view('ai/ticket_summary')(
      description: App.i18n.translateContent(@description)
      serviceOptions: @serviceOptions(service_config)
    ))

    select = App.UiElement.select.render(
      name: 'generate_on'
      value: service_config['generate_on']
      options: [
        {
          name: __('On ticket detail opening')
          value: 'on_ticket_detail_opening'
        },
        {
          name: __('On ticket summary sidebar activation')
          value: 'on_ticket_summary_sidebar_activation'
        },
      ]
    )

    content.find('.js-ticketSummaryGenerationConfigSelect').html(select)

    @html content

    @renderAlert()

  serviceOptions: (config) ->
    [
      {
        name: __('Customer Intent')
        key: 'customer_request'
        description: __('Provide a summary of the problem the customer needs to get resolved.')
        active: true,
        disabled: true,
      },
      {
        name: __('Conversation Summary')
        key: 'conversation_summary'
        description: __('Provide a summary of the conversation between customer and support agent.')
        active: true,
        disabled: true,
      },
      {
        name: __('Open Questions')
        key: 'open_questions'
        description: __('Provide a summary of the questions raised in the conversation.')
        active: config.open_questions,
      }
      {
        name: __('Upcoming Events')
        key: 'upcoming_events'
        description: __('Provide a summary of the upcoming events based on the conversation.')
        active: config.upcoming_events,
      }
      {
        name: __('Customer Sentiment')
        key: 'customer_sentiment'
        description: __('Provide an assessment of the customer sentiment based on the conversation.')
        active: config.customer_sentiment,
      }
    ]

  toggleAIAssistanceTicketSummarySetting:  =>
    value = @aiAssistanceTicketSummarySetting.prop('checked')
    App.Setting.set('ai_assistance_ticket_summary', value, failLocal: @failLocal, doneLocal: @renderAlert, notify: true)

  toggleService: (e) ->
    value = $(e.currentTarget).prop('checked')
    key = $(e.currentTarget).attr('name')

    config = App.Setting.get('ai_assistance_ticket_summary_config') || {}
    config[key] = value
    App.Setting.set('ai_assistance_ticket_summary_config', config, failLocal: @failLocal, notify: true)

  selectGenerationConfig: (e) ->
    e.preventDefault()
    value = $(e.currentTarget).find('[name="generate_on"]').val()

    config = App.Setting.get('ai_assistance_ticket_summary_config') || {}
    config['generate_on'] = value

    App.Setting.set('ai_assistance_ticket_summary_config', config, failLocal: @failLocal, notify: true)

  failLocal: =>
    @render()

App.Config.set('Summary', { prio: 1200, name: __('Ticket Summary'), parent: '#ai', target: '#ai/ticket_summary', controller: App.TicketSummary, permission: ['admin.ai_assistance_ticket_summary'] }, 'NavBarAdmin')
