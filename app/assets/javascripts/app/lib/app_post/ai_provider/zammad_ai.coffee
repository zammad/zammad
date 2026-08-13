App.Config.set('zammad_ai', {
  key:                 'zammad_ai'
  label:               __('Zammad AI')
  prio:                1000
  credential_fields: ->
    return [] if App.Config.get('system_online_service')
    ['token']
  # The service picks the models itself, so there is nothing to configure in a second wizard step.
  model_fields:        []
  required:            ['token']
  # No embedding model field: the service serves a fixed one (EMBEDDING_MODEL_FALLBACK in
  # lib/ai/provider/zammad_ai.rb), so there is nothing for an admin to pick or submit.
  supports_embeddings: true
  supports_model_listing: false
}, 'AIProviders')
