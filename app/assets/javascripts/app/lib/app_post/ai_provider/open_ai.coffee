# default model also in lib/ai/provider/open_ai.rb
App.Config.set('open_ai', {
  key:                  'open_ai'
  label:                __('OpenAI')
  prio:                 2000
  fields:               ['token', 'model', 'embedding_model', 'ocr_model']
  required:             ['token']
  default_model:        'gpt-4.1'
  default_embedding_model: 'text-embedding-3-small'
  supports_embeddings:  true
}, 'AIProviders')
