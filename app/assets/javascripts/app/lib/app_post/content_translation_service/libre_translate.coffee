# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Keep in sync with the backends in app/services/service/content_translation/backend/.
App.Config.set('libre_translate', {
  key:                   'libre_translate'
  label:                 __('LibreTranslate')
  prio:                  2000

  # ControllerForm attributes for the credentials of this service. The names are the keys the
  # backend reads from the service config, and 'api_key' is also the spelling the settings
  # controller masks on.
  credential_attributes: [
    { name: 'url', display: __('URL'), tag: 'input', type: 'url', null: false, placeholder: 'https://libretranslate.com' }
    { name: 'api_key', display: __('API key'), tag: 'input', type: 'text', input_type: 'password', null: true }
  ]

  # Unlike AI, LibreTranslate has no part of the installation it could be missing with.
  available:             -> true
}, 'ContentTranslationServices')
