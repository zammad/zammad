# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The page of one translation provider. A subclass names the provider, the setting holding its
# configuration and its HTTP log facility; the tabs and the switch are the same for every provider.
class App.ControllerContentTranslationIntegration extends App.ControllerTabs
  @requiredPermission: 'admin.integration'
  description: __('This service allows agents to translate articles to their configured UI language or other languages of their choice.')

  # provider:      'deepl'
  # configSetting: 'content_translation_deepl_config'
  # logFacility:   'DeepL'

  events:
    'click .nav-tabs [data-toggle="tab"]': 'tabRemember'
    'change .js-header-switch input':      'didChangeHeaderSwitch'

  elements:
    '.js-header-switch input': 'headerSwitch'

  constructor: ->
    super

    @headerSwitchName = "content-translation-#{@provider}"

    @title @header, true

    @tabs = [
      { name: __('Provider Settings'), target: 'provider-settings', controller: App.ContentTranslationProviderSettings, params: { provider: @provider, configSetting: @configSetting } }
      { name: __('Recent Logs'), target: 'logs', controller: App.HttpLog, params: { facility: @logFacility, header: false } }
      { name: __('Feedback'), target: 'feedback', controller: App.ContentTranslationFeedback, params: { provider: @provider } }
    ]

    # The tabs read settings while rendering, and App.ControllerTabs#render never releases the
    # tab controllers, so the page is rendered once after the settings are loaded.
    App.Setting.fetchFull((=> @render()), force: false)

    # Another provider's page, or another admin, may switch this one off.
    @subscribeId = App.Setting.subscribe(@renderHeaderSwitch, initFetch: false, clear: false)

  render: =>
    @headerSwitchChecked = App.ContentTranslationProviderSwitch.isActive(@provider)

    super

  renderHeaderSwitch: =>
    App.ContentTranslationProviderSwitch.render(@headerSwitch, @provider)

  didChangeHeaderSwitch: =>
    App.ContentTranslationProviderSwitch.toggle(@headerSwitch, @provider, @el.closest('.content'))

  release: =>
    App.Setting.unsubscribe(@subscribeId)

# At most one provider is active: its name is the only one content_translation_provider holds. The
# two flags the agent side reads follow it, so turning a provider on is all an admin has to do.
class App.ContentTranslationProviderSwitch
  # The server switches the name and both flags together. A single setting written through the API
  # can still leave the name stored with a flag off: such a provider translates nothing and shows
  # as off, to be switched on again.
  @active: ->
    return '' if !App.Setting.get('content_translation_service')
    return '' if !App.Setting.get('content_translation_ticket_article')

    App.Setting.get('content_translation_provider') || ''

  @isActive: (provider) ->
    @active() is provider

  # Until the settings are fetched again they hold the state from before the switch, so a render
  # in between would flip the switch back.
  @render: (input, provider) ->
    return if input.data('switching')

    input.prop('checked', @isActive(provider))

  @toggle: (input, provider, container) ->
    input.data('switching', true).prop('disabled', true)

    finish = =>
      input.data('switching', false).prop('disabled', false)
      @render(input, provider)

    if input.prop('checked')
      @activate(provider, container, finish)
    else
      @deactivate(provider, finish)

  @label: (provider) ->
    label = App.Config.get('ContentTranslationServices')?[provider]?.label
    return provider if !label

    App.i18n.translatePlain(label)

  # Asks first while another provider is active, because turning this one on switches that one off.
  # Its configuration and logs stay, so switching back later needs nothing to be entered again.
  @activate: (provider, container, always) ->
    active = @active()

    if !active or active is provider
      @request(provider, 'activate', always)
      return

    new ReplaceProviderConfirm(
      container:           container
      activeProviderLabel: @label(active)
      providerLabel:       @label(provider)
      callback:            => @request(provider, 'activate', always)
      onDecline:           always
    )

  @deactivate: (provider, always) ->
    return always() if !@isActive(provider)

    @request(provider, 'deactivate', always)

  @request: (provider, action, always) ->
    App.Ajax.request(
      type: 'POST'
      url:  "#{App.Config.get('api_path')}/content_translation/providers/#{provider}/#{action}"
      success: ->
        App.Event.trigger('notify', type: 'success', msg: __('Update successful.'), timeout: 2000)

        App.Setting.fetchFull(always, force: true)
      error: (xhr) ->
        details = xhr.responseJSON || {}
        App.Event.trigger('notify', type: 'error', msg: details.error_human || details.error || __('The setting could not be updated.'), timeout: 3000)

        always()
    )

class ReplaceProviderConfirm extends App.ControllerConfirm
  head:         __('Switch translation provider')
  buttonSubmit: __('Switch provider')

  content: ->
    App.i18n.translateContent('%s is the active translation provider. Turning on %s switches it off. Its configuration and logs are kept.', @activeProviderLabel, @providerLabel)

  onSubmit: =>
    @confirmed = true

    super

  # Closing by any other way than confirming leaves the active provider alone.
  onClosed: =>
    @onDecline?() if !@confirmed

# The configuration of one provider, and the article settings all providers share.
class App.ContentTranslationProviderSettings extends App.Controller
  events:
    'submit .js-providerConfig': 'submit'

  constructor: ->
    super

    @render()

  credentialAttributes: ->
    App.Config.get('ContentTranslationServices')[@provider]?.credential_attributes || []

  render: =>
    attributes = @credentialAttributes()
    params     = App.Setting.get(@configSetting) || {}

    @html App.view('integration/content_translation_provider_settings')(attributes: attributes)

    @forms = for attribute in attributes
      new App.ControllerForm(
        el:        @$("[data-name='#{attribute.name}']")
        model:     { configure_attributes: [_.extend({}, attribute, class: 'form-control--small', label_class: 'sr-only')] }
        params:    params
        autofocus: false
      )

    @articleSettings?.releaseController()
    @articleSettings = new App.ContentTranslationArticleSettings(el: @$('.js-articleSettings'))

  # The connection test runs while the setting is saved, so a refused configuration comes back as
  # the error of that save and nothing is stored.
  submit: (e) =>
    e.preventDefault()

    params = @formParam(e.target)

    errors = {}
    for form in @forms
      _.extend(errors, form.validate(params))

    if !_.isEmpty(errors)
      @formValidate(form: e.target, errors: errors)
      return

    form = $(e.target)
    App.ControllerForm.disable(form)

    App.Setting.set(@configSetting, params,
      notify:    true
      doneLocal: -> App.ControllerForm.enable(form)
      failLocal: -> App.ControllerForm.enable(form)
    )

  release: =>
    @articleSettings?.releaseController()

# Shared by every provider: whichever one is active, these settings apply, and switching between
# providers leaves them as they are.
class App.ContentTranslationArticleSettings extends App.Controller
  events:
    'change .js-ticketArticleAutoSetting input': 'toggleTicketArticleAuto'
    'submit form':                               'submit'

  elements:
    '.js-ticketArticleAutoSetting input': 'ticketArticleAutoSetting'

  constructor: ->
    super

    @render()

    # Follow the switch in place instead of rendering again, so a pushed setting change (also the
    # one the switch on this page caused) does not discard an unsaved role selection.
    @controllerBind('config_update', (data) =>
      switch data.name
        when 'content_translation_ticket_article_auto'
          @ticketArticleAutoSetting.prop('checked', App.Config.get(data.name))
        when 'language_detection_article'
          @renderAlert()
    )

    # The roles are no frontend setting, so they are followed via the collection. Only a role change
    # from elsewhere is drawn; the own submit already shows what it saved.
    @subscribeId = App.Setting.subscribe(@settingsChanged, initFetch: true, clear: false)

  settingsChanged: =>
    return if _.isEqual(App.Setting.get('content_translation_ticket_article_auto_role_ids'), @renderedRoleIds)

    @render()

  render: =>
    @html App.view('integration/content_translation_article_settings')(
      ticketArticleAuto: App.Config.get('content_translation_ticket_article_auto')
      alert:             @languageDetectionAlert()
    )

    @renderAlert()

    @renderedRoleIds = App.Setting.get('content_translation_ticket_article_auto_role_ids')

    new App.ControllerForm(
      el:        @$('.js-form')
      model:
        configure_attributes: [
          { name: 'content_translation_ticket_article_auto_role_ids', display: __('Available for the following roles'), tag: 'column_select', null: true, relation: 'Role', translate: true }
        ]
      params:
        content_translation_ticket_article_auto_role_ids: @renderedRoleIds
      autofocus: false
    )

  toggleTicketArticleAuto: =>
    App.Setting.set('content_translation_ticket_article_auto', @ticketArticleAutoSetting.prop('checked'), failLocal: @render, notify: true)

  submit: (e) =>
    e.preventDefault()

    roleIds = @formParam(e.target).content_translation_ticket_article_auto_role_ids || []

    # Known as shown before the request, so neither the local change nor the push redraws the form.
    @renderedRoleIds = roleIds
    App.Setting.set('content_translation_ticket_article_auto_role_ids', roleIds, failLocal: @render, notify: true)

  # Linked only for whoever may change the detection there: the link would otherwise just bounce off
  # permissionCheckRedirect.
  languageDetectionAlert: ->
    if @permissionCheck('admin.ticket')
      return App.i18n.translateContent('The article language detection is disabled. Enable it to avoid translating articles that are already in the target language. %l', '#settings/ticket')

    App.i18n.translateContent('The article language detection is disabled. To avoid translating articles that are already in the target language, ask an administrator with access to the ticket settings to enable it.')

  renderAlert: =>
    @$('.js-languageDetectionAlert').toggleClass('hide', !!App.Config.get('language_detection_article'))

  release: =>
    App.Setting.unsubscribe(@subscribeId)

class App.ContentTranslationFeedback extends App.Controller
  # The page asks for admin.integration only, but the download answers to admin.ai_feedback_logs, so
  # App.ControllerTabs leaves out the tab for whoever lacks it instead of offering a failing button.
  @requiredPermission: 'admin.ai_feedback_logs'

  events:
    'click .js-downloadFeedback': 'downloadFeedback'

  constructor: ->
    super

    @html App.view('integration/content_translation_feedback')()

  # Hardcoded, as Service::ContentTranslation::StoredTranslation::IDENTIFIER does not reach the
  # frontend. Every provider records its runs under it, with its own name as the service.
  downloadFeedback: =>
    App.AIAnalyticsDownload.request(
      type:    'with_usages'
      filters: { identifier: 'translate', ai_service_name: @provider }
      button:  @$('.js-downloadFeedback')
    )
