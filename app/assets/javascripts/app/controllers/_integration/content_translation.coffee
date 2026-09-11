# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ContentTranslation extends App.ControllerTabs
  @requiredPermission: 'admin.integration'
  header:      __('Translation services')
  description: __('This service allows agents to translate articles to their configured UI language or other languages of their choice.')

  constructor: ->
    super

    @title __('Translation services'), true

    @tabs = [
      { name: __('Provider Settings'), target: 'provider-settings', controller: ProviderSettings }
      { name: __('Ticket Articles'), target: 'ticket-articles', controller: TicketArticles }
      { name: __('Logs'), target: 'logs', controller: Logs }
    ]

    # The tabs read settings while rendering, and App.ControllerTabs#render never releases the
    # tab controllers, so the page is rendered once after the settings are loaded.
    App.Setting.fetchFull((=> @render()), force: false)

class ProviderSettings extends App.Controller
  events:
    'submit form':            'submit'
    'change [name=provider]': 'changeProvider'

  constructor: ->
    super

    @config = App.Setting.get('content_translation_service_config') || {}

    # The connection may be chosen while the AI provider is switched off: routing is configuration,
    # the switch only decides whether it is used.
    if @permissionCheck('admin.ai_provider')
      @fetchAIFeatureProviders()
    else
      @render()

  # The connections to choose from.
  fetchAIFeatureProviders: =>
    App.AIProviderConnection.fetchFull(
      =>
        @ajax(
          id:      'content_translation_ai_feature_providers'
          type:    'GET'
          url:     "#{App.Config.get('api_path')}/ai/feature_providers"
          success: (rows) =>
            @aiFeatureProviders = rows
            @render()
          error: =>
            @notify(
              type: 'error'
              msg:  __('The providers could not be loaded.')
            )
            @render()
        )
      force: false
    )

  render: =>
    provider   = @availableProvider()
    attributes = @configurationAttributes(provider)

    @html App.view('integration/content_translation_provider_settings')(attributes: attributes)

    # The AI service stays selectable while the AI provider is switched off, so that its
    # configuration survives the switch. The alert says why nothing translates in the meantime.
    if @service('ai').available() and !App.Config.get('ai_provider')
      @el.prepend(App.view('ai/missing_provider_alert')(visible: true))

    defaults = { ai_provider_connection_id: App.AIFeatureProvider.valueFor(@aiFeatureProvider(provider)) }
    params   = _.extend(defaults, @config, provider: provider)

    @forms = [
      new App.ControllerForm(
        el:        @$('.js-serviceForm')
        model:     { configure_attributes: [@serviceAttribute()] }
        params:    params
        autofocus: false
      )
    ]

    for attribute in attributes
      @forms.push(new App.ControllerForm(
        el:        @$("[data-name='#{attribute.name}']")
        # The table names the field; the label stays for assistive technology only.
        model:     { configure_attributes: [_.extend({}, attribute, label_class: 'hidden')] }
        params:    params
        autofocus: false
      ))

  changeProvider: =>
    @config = _.extend({}, @config, @formParam(@$('form')))

    @render()

  service: (key) ->
    App.Config.get('ContentTranslationServices')[key]

  # Only a service that is still offered is kept as the selection: a service that is gone would
  # otherwise end up in the select as its raw value.
  availableProvider: ->
    provider = @config.provider
    return if !provider
    return if !@service(provider)?.available()

    provider

  serviceOptions: ->
    services = _.filter(_.values(App.Config.get('ContentTranslationServices')), (service) -> service.available())

    _.map(_.sortBy(services, (service) -> service.prio), (service) -> { name: service.label, value: service.key })

  # customsort keeps the services in the prio order the options were built in.
  serviceAttribute: ->
    { name: 'provider', display: __('Translation service provider'), tag: 'select', options: @serviceOptions(), null: true, nulloption: true, translate: true, customsort: 'on' }

  configurationAttributes: (provider) ->
    (@service(provider)?.credential_attributes or []).concat(@aiProviderAttributes(provider))

  # The AI feature the given service runs as, declared on the service entry.
  aiFeatureIdentifier: (provider) ->
    @service(provider)?.ai_feature_identifier

  # The routing row serving that feature, while the admin has pointed it at a connection.
  aiFeatureProvider: (provider) ->
    identifier = @aiFeatureIdentifier(provider)
    return if !identifier

    _.find(@aiFeatureProviders, (row) -> row.identifier is identifier)

  aiProviderAttributes: (provider) ->
    return [] if !@aiFeatureProviders
    return [] if !@aiFeatureIdentifier(provider)

    [
      { name: 'ai_provider_connection_id', display: __('Provider'), tag: 'select', options: @aiProviderOptions(), null: false }
    ]

  aiProviderOptions: ->
    App.AIFeatureProvider.options(App.AIProviderConnection.all())

  submit: (e) =>
    e.preventDefault()

    params = @formParam(e.target)

    errors = {}
    for form in @forms
      _.extend(errors, form.validate(params))

    if !_.isEmpty(errors)
      @formValidate(form: e.target, errors: errors)
      return

    # The routing row is written first: the settings announce the success of the whole form, so
    # they must not run while the row this form also changed is still the old one.
    @submitAIFeatureProvider(params.provider, params.ai_provider_connection_id, => @submitConfig(params))

  # The flag follows the config only once the config is saved, so a refused config leaves the flag
  # alone and the admin sees one error instead of an error next to a success.
  submitConfig: (params) ->
    # Without a service there is nothing to keep, not even the credentials of the previous one.
    config      = if params.provider then _.omit(params, 'ai_provider_connection_id') else {}
    hasProvider = !!params.provider
    form        = @$('form')

    App.ControllerForm.disable(form)

    App.Setting.set('content_translation_service_config', config,
      notify:    false
      failLocal: -> App.ControllerForm.enable(form)
      doneLocal: =>
        App.ControllerForm.enable(form)

        if App.Config.get('content_translation_service') is hasProvider
          @notify(type: 'success', msg: __('Update successful.'), timeout: 2000)
          return

        App.Setting.set('content_translation_service', hasProvider, notify: true)
    )

  # Calls back only once the row is written, so a failure stops the submit instead of ending in a
  # success and an error notification next to each other.
  submitAIFeatureProvider: (provider, value, done) =>
    return done() if !value

    identifier = @aiFeatureIdentifier(provider)

    App.AIFeatureProvider.save(
      identifier: identifier
      row:        @aiFeatureProvider(provider)
      value:      value
      success:    (updated) =>
        @replaceAIFeatureProvider(identifier, updated)
        done()
      error:      (msg) =>
        @notify(type: 'error', msg: msg)
    )

  # Keeps the rows in step with what was just written, so a second submit updates the row it
  # created instead of trying to create it again.
  replaceAIFeatureProvider: (identifier, row) =>
    @aiFeatureProviders = _.reject(@aiFeatureProviders, (existing) -> existing.identifier is identifier)
    @aiFeatureProviders.push(row) if row

class TicketArticles extends App.Controller
  events:
    'change .js-ticketArticleSetting input':     'toggleTicketArticle'
    'change .js-ticketArticleAutoSetting input': 'toggleTicketArticleAuto'
    'submit form':                               'submit'

  elements:
    '.js-ticketArticleSetting input':     'ticketArticleSetting'
    '.js-ticketArticleAutoSetting input': 'ticketArticleAutoSetting'

  constructor: ->
    super

    @render()

    # Follow the switches in place instead of rendering again, so a pushed setting change (also the
    # one a switch on this page caused) does not discard an unsaved role selection.
    @controllerBind('config_update', (data) =>
      switch data.name
        when 'content_translation_ticket_article'
          @ticketArticleSetting.prop('checked', App.Config.get(data.name))
        when 'content_translation_ticket_article_auto'
          @ticketArticleAutoSetting.prop('checked', App.Config.get(data.name))
    )

    # The roles and the language detection are no frontend settings, so they are followed via the
    # collection. Only a role change from elsewhere is drawn; the own submit already shows what it saved.
    @subscribeId = App.Setting.subscribe(@settingsChanged, initFetch: true, clear: false)

  settingsChanged: =>
    @renderAlert()

    return if _.isEqual(App.Setting.get('content_translation_ticket_article_auto_role_ids'), @renderedRoleIds)

    @render()

  render: =>
    @html App.view('integration/content_translation_ticket_articles')(
      ticketArticle:     App.Config.get('content_translation_ticket_article')
      ticketArticleAuto: App.Config.get('content_translation_ticket_article_auto')
      alert:             App.i18n.translateContent('The article language detection is disabled. Enable it to avoid translating articles that are already in the target language. %l', '#settings/ticket')
    )

    @renderAlert()

    @renderedRoleIds = App.Setting.get('content_translation_ticket_article_auto_role_ids')

    new App.ControllerForm(
      el:        @$('.js-form')
      model:
        configure_attributes: [
          { name: 'content_translation_ticket_article_auto_role_ids', display: __('Roles'), tag: 'column_select', null: true, relation: 'Role', translate: true }
        ]
      params:
        content_translation_ticket_article_auto_role_ids: @renderedRoleIds
      autofocus: false
    )

  toggleTicketArticle: =>
    App.Setting.set('content_translation_ticket_article', @ticketArticleSetting.prop('checked'), failLocal: @render, notify: true)

  toggleTicketArticleAuto: =>
    App.Setting.set('content_translation_ticket_article_auto', @ticketArticleAutoSetting.prop('checked'), failLocal: @render, notify: true)

  submit: (e) =>
    e.preventDefault()

    roleIds = @formParam(e.target).content_translation_ticket_article_auto_role_ids || []

    # Known as shown before the request, so neither the local change nor the push redraws the form.
    @renderedRoleIds = roleIds
    App.Setting.set('content_translation_ticket_article_auto_role_ids', roleIds, failLocal: @render, notify: true)

  renderAlert: =>
    @$('.js-languageDetectionAlert').toggleClass('hide', !!App.Setting.get('language_detection_article'))

  release: =>
    App.Setting.unsubscribe(@subscribeId)

class Logs extends App.Controller
  constructor: ->
    super

    @render()

    @subscribeId = App.Setting.subscribe(@renderAiState, initFetch: true, clear: false)

  render: =>
    @html App.view('integration/content_translation_logs')(hint: @aiHint())

    # The heading belongs to the tab, so it stays while the log itself makes way for the AI hint.
    @httpLog = new App.HttpLog(
      el:       @$('.js-log')
      facility: 'content_translation'
      header:   false
    )

  # Linked only for whoever may open that screen: the link would otherwise just bounce off
  # permissionCheckRedirect.
  aiHint: ->
    if @permissionCheck('admin.ai_feedback_logs')
      return App.i18n.translateContent('You can find relevant AI provider logs under AI > Feedback & Logs. %l', '#ai/feedback_logs')

    App.i18n.translateContent('You can find relevant AI provider logs under AI > Feedback & Logs.')

  renderAiState: =>
    isAI = App.Setting.get('content_translation_service_config')?.provider is 'ai'

    @$('.js-aiHint').toggleClass('hide', !isAI)
    @$('.js-log').toggleClass('hide', isAI)

  release: =>
    App.Setting.unsubscribe(@subscribeId)

    @httpLog?.releaseController()
    @httpLog = null

class State
  @current: ->
    App.Setting.get('content_translation_ticket_article')

App.Config.set(
  'IntegrationContentTranslation'
  {
    name: __('Translation services')
    target: '#system/integration/content_translation'
    description: __('Translate ticket articles into another language.')
    controller: ContentTranslation
    state: State
    permission: ['admin.integration']
  }
  'NavBarIntegrations'
)
