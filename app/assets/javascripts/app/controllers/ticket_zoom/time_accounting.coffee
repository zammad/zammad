class App.TicketZoomTimeAccounting extends App.ControllerModal
  buttonClose: true
  buttonCancel: false
  buttonSubmit: 'Account Time'
  buttonClass: 'btn--success'
  leftButtons: [{
    className: 'btn--text btn--subtle js-skip',
    text: 'skip'
  }]
  head: 'Time Accounting'
  small: true

  events:
    'submit form':                        'submit'
    'click .js-submit:not(.is-disabled)': 'submit'
    'click .js-cancel':                   'cancel'
    'click .js-close':                    'cancel'
    'click .js-skip':                     'skip'

  content: ->
    App.view('ticket_zoom/time_accounting')()

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

  onSubmit: =>
    @$('[name="time_unit"]').removeClass('has-error')
    params = @formParams()
    if params.time_unit
      params.time_unit = params.time_unit.replace(',', '.')

      if isNaN(parseFloat(params.time_unit)) || params.time_unit.match(/[A-z]|\s/)
        @$('[name="time_unit"]').addClass('has-error')
        return

    @close()
    if @submitCallback
      @submitCallback(params)
