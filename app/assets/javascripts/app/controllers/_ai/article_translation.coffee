# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# AI as the translation provider. It shares the switch and the article settings with the provider
# integrations; its feedback and logs are those of every AI feature, under AI > Feedback & Logs.
class App.AIArticleTranslation extends App.ControllerAIFeatureBase
  @requiredPermission: 'admin.ai_assistance_translation'
  header: __('Article Translation')
  provider: 'ai'
  description: __('This service allows agents to translate articles to their configured UI language or other languages of their choice.')

  events:
    'click [data-type=legal-information]': 'legalInformation'
    'change .js-providerSwitch input':     'toggleProvider'

  elements:
    '.js-missingProviderAlert': 'missingProviderAlert'
    '.js-providerSwitch input': 'providerSwitch'

  constructor: ->
    super

    # Another provider's page, or another admin, may switch this one off.
    @subscribeId = App.Setting.subscribe(@settingsChanged, initFetch: false, clear: false)

  showAlert: ->
    App.ContentTranslationProviderSwitch.isActive(@provider) and !App.Config.get('ai_provider')

  render: =>
    @html App.view('ai/article_translation')(
      header:      @header
      checked:     App.ContentTranslationProviderSwitch.isActive(@provider)
      description: @description
      buttons:     [
        { name: __('Legal Information'), 'data-type': 'legal-information', class: 'btn--info' }
      ]
    )

    @articleSettings?.releaseController()
    @articleSettings = new App.ContentTranslationArticleSettings(el: @$('.js-articleSettings'))

    @renderAlert()
    @renderProviderModal('translate')

  settingsChanged: =>
    return if !@providerSwitch?.length

    App.ContentTranslationProviderSwitch.render(@providerSwitch, @provider)
    @renderAlert()

  toggleProvider: =>
    App.ContentTranslationProviderSwitch.toggle(@providerSwitch, @provider, @el.closest('.content'))

  release: =>
    App.Setting.unsubscribe(@subscribeId)
    @articleSettings?.releaseController()

    super

App.Config.set('AIArticleTranslation', { prio: 1250, name: __('Article Translation'), parent: '#ai', target: '#ai/article_translation', controller: App.AIArticleTranslation, permission: ['admin.ai_assistance_translation'] }, 'NavBarAdmin')
