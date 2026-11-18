# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class DeepL extends App.ControllerContentTranslationIntegration
  header:        'DeepL'
  provider:      'deepl'
  configSetting: 'content_translation_deepl_config'
  logFacility:   'DeepL'

class State
  @current: ->
    App.ContentTranslationProviderSwitch.isActive('deepl')

App.Config.set(
  'IntegrationDeepL'
  {
    name: 'DeepL'
    target: '#system/integration/deepl'
    description: __('Machine translation service to translate ticket articles.')
    controller: DeepL
    state: State
    permission: ['admin.integration']
  }
  'NavBarIntegrations'
)
