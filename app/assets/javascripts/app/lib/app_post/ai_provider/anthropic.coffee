App.Config.set('anthropic', {
  key:                    'anthropic'
  label:                  __('Anthropic')
  prio:                   4000
  credential_fields:      ['token']
  model_fields:           ['model', 'ocr_model']
  required:               ['token']
  supports_model_listing: true
}, 'AIProviders')
