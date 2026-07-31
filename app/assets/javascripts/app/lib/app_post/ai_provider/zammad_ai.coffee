App.Config.set('zammad_ai', {
  key:                 'zammad_ai'
  label:               __('Zammad AI')
  prio:                1000
  fields: ->
    return [] if App.Config.get('system_online_service')
    ['token']
  required:            ['token']
  supports_embeddings: true
}, 'AIProviders')
