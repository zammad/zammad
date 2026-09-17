# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Keep in sync with the backends in app/services/service/content_translation/backend/.
App.Config.set('deepl', {
  key:                   'deepl'
  label:                 __('DeepL')
  prio:                  3000

  credential_attributes: [
    {
      name:       'tier'
      display:    __('API plan')
      tag:        'select'
      null:       false
      nulloption: true
      translate:  true
      options:    [
        { name: __('Developer API (api-free.deepl.com)'), value: 'free' }
        { name: __('Growth/Enterprise API (api.deepl.com)'), value: 'pro' }
      ]
    }
    { name: 'api_key', display: __('API key'), tag: 'input', type: 'text', input_type: 'password', null: false }
  ]

  available:             -> true
}, 'ContentTranslationServices')
