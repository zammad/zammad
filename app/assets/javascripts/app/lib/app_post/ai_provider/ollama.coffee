# default model also in lib/ai/provider/ollama.rb
App.Config.set('ollama', {
  key:    'ollama'
  label:  __('Ollama')
  prio:   3000
  fields: ['url', 'model']
  default_model: 'llama3.2'
}, 'AIProviders')
