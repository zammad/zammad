App.Config.set('azure', {
  key:    'azure'
  label:  __('Azure AI (legacy deployment-based endpoints)')
  prio:   5000
  fields: ['token', 'url_completions', 'url_ocr'] # TODO: Add url_embeddings when needed.
  required: ['token', 'url_completions']
}, 'AIProviders')
