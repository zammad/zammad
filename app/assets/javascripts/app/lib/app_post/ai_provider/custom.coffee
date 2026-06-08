# default model also in lib/ai/provider/custom.rb
App.Config.set('custom_open_ai', {
  key:    'custom_open_ai'
  label:  __('Custom (OpenAI Compatible)')
  prio:   7000
  url_placeholder: 'http://localhost:1234/v1'
  fields: ['url', 'token', 'model', 'ocr_active', 'ocr_model']
  required: ['model', 'url']
}, 'AIProviders')
