class App.TicketZoomTimeUnit extends App.ControllerObserver
  model: 'Ticket'
  observe:
    time_unit: true

  render: (ticket) =>
    return if ticket.currentView() isnt 'agent'
    return if !ticket.time_unit
    @html App.view('ticket_zoom/time_unit')(
      ticket: ticket
    )
