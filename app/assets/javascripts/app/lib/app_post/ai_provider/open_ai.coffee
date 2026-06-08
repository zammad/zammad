# default model also in lib/ai/provider/open_ai.rb
App.Config.set('open_ai', {
  key:    'open_ai'
  label:  __('OpenAI')
  prio:   2000
  fields: ['token', 'model', 'ocr_active', 'ocr_model']
  required: ['token']
  default_model: 'gpt-4.1'
}, 'AIProviders')
