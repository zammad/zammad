class App.TicketSharedDraftOverwriteModal extends App.ControllerModal
  head:         __('Save Draft')
  message:      __('There is an existing draft. Do you want to overwrite it?')
  buttonCancel: true
  buttonSubmit: __('Overwrite Draft')
  buttonClass:  'btn--danger'

  onShowDraft: null
  onSaveDraft: null

  showDraft: (e) =>
    e.preventDefault()
    @cancel()
    @onShowDraft(e)

  onSubmit: ->
    @onSaveDraft()
    @close()

  post: =>
    return if !@onShowDraft

    button = $("<div class='btn'>#{App.Utils.icon('note')} #{__('Show Draft')}</div>")

    button.click(@showDraft)

    @el.find('.modal-rightFooter').prepend(button)
