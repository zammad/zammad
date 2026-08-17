# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# What an admin is told before the connection serving semantic search is changed: the knowledge base
# has to be embedded again, which takes time, API calls and tokens.
#
# A warning, not the gate. Whether the change needs confirming at all is decided by the backend
# (Service::AI::ProviderConnection::Validator::EmbeddingRebuild), so a change made through the API or
# the console gets the same treatment as one made here - this only makes sure the admin is not
# surprised by the bill.
class App.ControllerAIEmbeddingRebuildConfirm extends App.ControllerModal
  buttonClose:  true
  # Renders as 'Cancel & Go Back', which is what the modal calls its cancel button.
  buttonCancel: true
  buttonSubmit: __('Proceed')
  buttonClass:  'btn--success'
  head:         __('Are you sure you want to change the embedding configuration?')
  large:        true

  # 'rebuild' - the connection keeps serving semantic search with a different provider or model, so
  # everything indexed has to be produced again. 'clear' - nothing serves it afterwards, so the index
  # is simply left where it is.
  mode: 'rebuild'

  content: =>
    App.view('ai/embedding_rebuild_confirm')(mode: @mode)

  onSubmit: =>
    @close()
    @callback?()
