# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class App.ControllerAIEmbeddingStopConfirm extends App.ControllerModal
  buttonClose:  true
  buttonCancel: true
  buttonSubmit: __('Proceed')
  buttonClass:  'btn--success'
  head:         __('Are you sure you want to stop semantic search?')
  large:        true

  content: ->
    App.view('ai/embedding_stop_confirm')()

  onSubmit: =>
    @close()
    @callback?()
