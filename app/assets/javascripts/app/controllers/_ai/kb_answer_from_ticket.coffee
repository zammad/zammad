# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class App.KbAnswerFromTicket extends App.ControllerAIFeatureBase
  header: __('Knowledge Base Answer Generation')
  description: __('Knowledge Base Answer Generation allows agents to generate a knowledge base answer in draft state from a solved ticket.')
  @requiredPermission: 'admin.ai_assistance_kb_answer_from_ticket_generation'
  events:
    'change .js-aiAssistanceKbAnswerFromTicketSetting input': 'toggleSetting'

  elements:
    '.js-aiAssistanceKbAnswerFromTicketSetting input': 'aiAssistanceKbAnswerFromTicketSetting'

  constructor: ->
    super

    @controllerBind('config_update', (data) =>
      return if data.name isnt 'ai_assistance_kb_answer_from_ticket_generation'

      @renderAlert()
      @aiAssistanceKbAnswerFromTicketSetting.prop('checked', App.Config.get('ai_assistance_kb_answer_from_ticket_generation'))
    )

  showAlert: ->
    App.Config.get('ai_assistance_kb_answer_from_ticket_generation') && !App.Config.get('ai_provider')

  render: =>
    @html App.view('ai/kb_answer_from_ticket')(
      description: App.i18n.translateContent(@description)
      buttons: [
        { name: __('Legal Information'), 'data-type': 'legal-information', class: 'btn--info' }
      ]
    )

    @renderAlert()

  toggleSetting: =>
    value = @aiAssistanceKbAnswerFromTicketSetting.prop('checked')
    App.Setting.set('ai_assistance_kb_answer_from_ticket_generation', value, failLocal: @failLocal, doneLocal: @renderAlert, notify: true)

  failLocal: =>
    @render()

App.Config.set('KbAnswerFromTicket', { prio: 1150, name: __('KB Answer Generation'), parent: '#ai', target: '#ai/kb_answer_from_ticket', controller: App.KbAnswerFromTicket, permission: ['admin.ai_assistance_kb_answer_from_ticket_generation'] }, 'NavBarAdmin')
