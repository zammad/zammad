# default model also in lib/ai/provider/ollama.rb
App.Config.set('ollama', {
  key:                  'ollama'
  label:                __('Ollama')
  prio:                 3000
  url_placeholder:      'http://localhost:11434'
  fields:               ['url', 'model', 'embedding_model', 'ocr_model']
  required:             ['url']
  default_model:        'mistral-small3.2'
  default_embedding_model: 'bge-m3'
  supports_embeddings:  true
}, 'AIProviders')
