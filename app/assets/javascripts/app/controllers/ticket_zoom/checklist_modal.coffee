class App.TicketZoomChecklistModal extends App.ControllerModal
  buttonClose: true
  buttonCancel: false
  buttonClass: 'btn--primary'
  buttonSubmit: __('Yes, open the checklist')
  leftButtons: [{
    className: 'js-skip',
    text: __('No, just close the ticket')
  }]
  head: __('Incomplete Ticket Checklist')
  small: true

  events:
    'submit form':                        'submit'
    'click .js-submit:not(.is-disabled)': 'submit'
    'click .js-close':                    'cancel'
    'click .js-skip':                     'skip'

  constructor: ->
    super

  content: ->
    App.view('ticket_zoom/checklist_modal')()

  skip: (e) =>
    return if !@submitCallback
    @submitCallback({})
    @close(e)

  onCancel: =>
    return if !@cancelCallback
    @cancelCallback()

  onClose: ->
    return if !@cancelCallback
    @cancelCallback()

  onSubmit: (e) =>
    return if !@cancelCallback
    @cancelCallback()
    @container.find(".tabsSidebar-tab[data-tab='checklist']:not(.active)").click()
    @close(e)
