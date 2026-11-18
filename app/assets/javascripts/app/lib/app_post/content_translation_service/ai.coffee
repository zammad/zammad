# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Keep in sync with the backends in app/services/service/content_translation/backend/.
App.Config.set('ai', {
  label:                 __('AI')

  # ControllerForm attributes for the credentials of this service. AI keeps its credentials in
  # the AI provider manager, so it has nothing of its own to ask for.
  credential_attributes: []
}, 'ContentTranslationServices')
