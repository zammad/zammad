App.Config.set('ollama', {
  key:                    'ollama'
  label:                  __('Ollama')
  prio:                   3000
  url_placeholder:        'http://localhost:11434'
  credential_fields:      ['url']
  model_fields:           ['model', 'embedding_model', 'embedding_size', 'embedding_input_limit', 'ocr_model']
  required:               ['url']
  supports_embeddings:    true
  supports_model_listing: true
}, 'AIProviders')
