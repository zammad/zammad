# default model also in lib/ai/provider/mistral.rb
App.Config.set('mistral', {
  key:                  'mistral'
  label:                __('Mistral AI')
  prio:                 6000
  fields:               ['token', 'model', 'embedding_model', 'ocr_model']
  required:             ['token']
  default_model:        'mistral-large-2512'
  default_embedding_model: 'mistral-embed'
  supports_embeddings:  true
}, 'AIProviders')
