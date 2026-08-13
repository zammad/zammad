App.Config.set('mistral', {
  key:                    'mistral'
  label:                  __('Mistral AI')
  prio:                   6000
  credential_fields:      ['token']
  model_fields:           ['model', 'embedding_model', 'embedding_size', 'embedding_input_limit', 'ocr_model']
  required:               ['token']
  supports_embeddings:    true
  supports_model_listing: true
}, 'AIProviders')
