App.Config.set('custom_open_ai', {
  key:                    'custom_open_ai'
  label:                  __('Custom (OpenAI Compatible)')
  prio:                   7000
  url_placeholder:        'http://localhost:1234/v1'
  credential_fields:      ['url', 'token']
  model_fields:           ['model', 'embedding_model', 'embedding_size', 'embedding_input_limit', 'ocr_model']
  required:               ['model', 'url']
  supports_embeddings:    true
  supports_model_listing: true
}, 'AIProviders')
