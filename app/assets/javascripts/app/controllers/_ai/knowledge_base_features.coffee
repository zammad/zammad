# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBaseFeatures extends App.ControllerAIFeatureBase
  @requiredPermission: 'admin.ai_knowledge_base'
  header: __('Knowledge Base Assistant')

  description: __('This enables Semantic search to empower all the AI tools integrated with your knowledge base.')

  relevanceScoreSelector: '[name="ai_assistance_kb_answer_suggestions_relevance_score"]'

  events:
    'change .js-vectordbEnabledSetting input':      'toggleVectordbEnabledSetting'
    'change .checkbox--service input':              'toggleService'
    'submit .js-kbAnswerSuggestionsRelevanceScore': 'saveKbAnswerSuggestionsRelevanceScore'

  elements:
    '.js-vectordbEnabledSetting input': 'vectordbEnabledSetting'

  constructor: ->
    super

    # The service settings are frontend settings, so a change made in another session arrives here
    # as a config update. Only the affected control is refreshed, to not discard a pending input.
    @controllerBind('config_update', (data) =>
      if data.name in @serviceSettings()
        @$("[name='#{data.name}']").prop('checked', data.value)
        @renderAlert()
      else if data.name is 'ai_assistance_kb_answer_suggestions_relevance_score'
        @$(@relevanceScoreSelector).val(data.value)
    )

  showAlert: ->
    anyServiceEnabled = _.any(@serviceSettings(), (name) -> App.Config.get(name))

    (App.Setting.get('vectordb_enabled') || anyServiceEnabled) && !App.Config.get('ai_provider')

  renderMissingKnowledgeBaseAlert: =>
    @el.find('.js-missingKnowledgeBaseAlert').remove()
    return if App.Config.get('kb_active')

    @el.find('.page-content').prepend(App.view('ai/missing_knowledge_base_alert')())
    @refreshElements()

  render: =>
    content = $(App.view('ai/knowledge_base_features')(
      header:          @header
      description:     @description
      vectordbEnabled: App.Setting.get('vectordb_enabled')
      serviceOptions:  @serviceOptions()
      buttons:         [
        { name: __('Legal Information'), 'data-type': 'legal-information', class: 'btn--info' }
      ]
    ))

    relevanceScoreInput = App.UiElement.integer.render(
      name:       'ai_assistance_kb_answer_suggestions_relevance_score'
      id:         'ai_assistance_kb_answer_suggestions_relevance_score'
      value:      App.Config.get('ai_assistance_kb_answer_suggestions_relevance_score')
      min:        0
      max:        100
      appendText: '%'
    )

    # The section heading is the only visible label of the input.
    relevanceScoreInput.find('input').attr('aria-labelledby', 'relevance-score-threshold-label')

    content.find('.js-kbAnswerSuggestionsRelevanceScoreInput').html(relevanceScoreInput)

    @html content

    @renderAlert()
    @renderMissingEmbeddingProviderAlert() if @permissionCheck('admin.ai_provider')
    @renderMissingKnowledgeBaseAlert()
    @renderProviderModal('knowledge_base_answer_from_ticket')

  serviceSettings: ->
    _.pluck(@serviceOptions(), 'key')

  # Every service is backed by its own boolean setting, addressed by the checkbox name.
  serviceOptions: ->
    [
      {
        name:        __('Knowledge Base Answer Suggestions')
        key:         'ai_assistance_kb_answer_suggestions'
        description: __('Suggest matching knowledge base answers in the ticket sidebar.')
        active:      App.Config.get('ai_assistance_kb_answer_suggestions')
      }
      {
        name:        __('Knowledge Base Answer Generation')
        key:         'ai_assistance_kb_answer_from_ticket_generation'
        description: __('Allow agents to generate a knowledge base answer in draft state from a solved ticket.')
        active:      App.Config.get('ai_assistance_kb_answer_from_ticket_generation')
      }
    ]

  featureOptions: ->
    [
      {
        name:        __('Knowledge Base Answer Generation')
        key:         'ai_assistance_kb_answer_from_ticket_generation'
        description: __('Provide a summary of the questions raised in the conversation.')
        active:      App.Config.get('ai_assistance_kb_answer_from_ticket_generation')
      }
    ]

  toggleVectordbEnabledSetting: =>
    value = @vectordbEnabledSetting.prop('checked')

    App.Setting.set('vectordb_enabled', value,
      notify:    true
      doneLocal: =>
        @render()
        @syncVectorIndex() if value
      # The prerequisite messages are long, so they get a longer timeout, and the toggle is
      # reset in place instead of re-rendering, which would discard a pending input.
      fail: (settings, details) =>
        @vectordbEnabledSetting.prop('checked', !value)
        @notify(
          type:    'error'
          msg:     details?.error_human || details?.error || __('The setting could not be updated.')
          timeout: 6000
        )
    )

  syncVectorIndex: =>
    App.Ajax.request(
      type: 'POST'
      url:  App.Config.get('api_path') + '/ai/vector_index/sync'
      error: (data) =>
        details = data.responseJSON || {}
        @notify(
          type:    'error'
          msg:     details.error_human || details.error || __('The vector index could not be updated.')
          timeout: 6000
        )
    )

  toggleService: (e) =>
    name  = $(e.currentTarget).attr('name')
    value = $(e.currentTarget).prop('checked')

    App.Setting.set(name, value, failLocal: @failLocal, doneLocal: @renderAlert, notify: true)

  saveKbAnswerSuggestionsRelevanceScore: (e) =>
    e.preventDefault()

    raw   = @$(@relevanceScoreSelector).val()
    value = parseInt(raw, 10)

    # An empty or non-numeric input parses to NaN; hand over the raw value so the setting validation
    # reports it instead of silently storing null.
    value = raw if isNaN(value)

    App.Setting.set('ai_assistance_kb_answer_suggestions_relevance_score', value, failLocal: @failLocal, notify: true)

  toggleFeature: (e) =>
    checkbox = $(e.currentTarget)
    App.Setting.set(checkbox.attr('name'), checkbox.prop('checked'), failLocal: @failLocal, doneLocal: @renderAlert, notify: true)

  failLocal: =>
    @render()

App.Config.set('KnowledgeBaseFeatures', { prio: 1080, name: __('Knowledge Base Assistant'), parent: '#ai', target: '#ai/knowledge_base_features', controller: KnowledgeBaseFeatures, permission: ['admin.ai_knowledge_base'] }, 'NavBarAdmin')
