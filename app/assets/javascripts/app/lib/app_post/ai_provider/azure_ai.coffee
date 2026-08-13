App.Config.set('azure', {
  key:                    'azure'
  label:                  __('Azure AI (legacy deployment-based endpoints)')
  prio:                   5000
  # Deployment-based endpoints name the model in the URL, so there is no model to pick and no
  # second wizard step: the dialog stays the single credential step it always was.
  credential_fields:      ['token', 'url_completions', 'url_ocr'] # TODO: Add url_embeddings when needed.
  model_fields:           []
  required:               ['token', 'url_completions']
  supports_model_listing: false
}, 'AIProviders')
