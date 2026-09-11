# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Keep in sync with the backends in app/services/service/content_translation/backend/.
App.Config.set('ai', {
  key:                   'ai'
  label:                 __('AI provider')
  prio:                  1000

  # ControllerForm attributes for the credentials of this service. AI keeps its credentials in
  # the AI provider manager, so it has nothing of its own to ask for.
  credential_attributes: []

  ai_feature_identifier: 'translate'

  # An installation without AI at all deactivates its permission - then the service is not offered
  # either. A switched-off AI provider is a different case: the switch can come back, so the
  # service stays selectable and the integration warns about the switch instead.
  available:             -> App.Permission.findByAttribute('name', 'admin.ai_provider')?.active isnt false
}, 'ContentTranslationServices')
