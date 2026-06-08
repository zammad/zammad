# default model also in lib/ai/provider/anthropic.rb
App.Config.set('anthropic', {
  key:    'anthropic'
  label:  __('Anthropic')
  prio:   4000
  fields: ['token', 'model', 'ocr_active', 'ocr_model']
  required: ['token']
  default_model: 'claude-sonnet-4-6'
}, 'AIProviders')
