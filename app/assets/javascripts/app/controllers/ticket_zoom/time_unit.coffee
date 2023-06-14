class App.TicketZoomTimeUnit extends App.ControllerObserver
  @include App.TimeAccountingUnitMixin

  model: 'Ticket'
  observe:
    time_unit: true

  constructor: ->
    super

    @controllerBind('config_update', (data) =>
      return if not /^time_accounting_unit/.test(data.name)
      @rerenderCallback()
    )

  render: (ticket) =>
    return if ticket.currentView() isnt 'agent'
    return if !ticket.time_unit

    @html App.view('ticket_zoom/time_unit')(
      ticket:                    ticket
      timeAccountingDisplayUnit: @timeAccountingDisplayUnit()
    )
