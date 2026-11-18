# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class LibreTranslate extends App.ControllerContentTranslationIntegration
  header:        'LibreTranslate'
  provider:      'libre_translate'
  configSetting: 'content_translation_libre_translate_config'
  logFacility:   'LibreTranslate'

class State
  @current: ->
    App.ContentTranslationProviderSwitch.isActive('libre_translate')

App.Config.set(
  'IntegrationLibreTranslate'
  {
    name: 'LibreTranslate'
    target: '#system/integration/libre_translate'
    description: __('Machine translation service to translate ticket articles.')
    controller: LibreTranslate
    state: State
    permission: ['admin.integration']
  }
  'NavBarIntegrations'
)
