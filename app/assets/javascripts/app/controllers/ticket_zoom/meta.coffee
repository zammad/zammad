class App.TicketZoomMeta extends App.ControllerObserver
  model: 'Ticket'
  observe:
    number: true
    created_at: true
    escalation_at: true

  render: (ticket) =>
    @html App.view('ticket_zoom/meta')(
      ticket:     ticket
      isCustomer: ticket.currentView() is 'customer'
    )
