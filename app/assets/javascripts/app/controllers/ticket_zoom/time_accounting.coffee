class App.TicketZoomTimeAccounting extends App.ControllerModal
  buttonClose: true
  buttonCancel: 'skip'
  buttonSubmit: 'Account Time'
  buttonClass: 'btn--success'
  head: 'Time Accounting'
  small: true

  content: ->
    App.view('ticket_zoom/time_accounting')()

  onCancel: =>
    if @cancelCallback
      @cancelCallback()

  onSubmit: =>
    @close()
    if @submitCallback
      params = @formParams()
      @submitCallback(params)
