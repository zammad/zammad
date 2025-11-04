App.Config.set('azure', {
  key:    'azure'
  label:  __('Azure AI')
  prio:   5000
  fields: ['url_completions', 'token'] # TODO: Add url_embeddings when needed.
}, 'AIProviders')
