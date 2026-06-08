App.Config.set('zammad_ai', {
  key:    'zammad_ai'
  label:  __('Zammad AI')
  prio:   1000
  fields: ->
    return ['ocr_active'] if App.Config.get('system_online_service')
    ['token', 'ocr_active']
  required: ['token']
}, 'AIProviders')
