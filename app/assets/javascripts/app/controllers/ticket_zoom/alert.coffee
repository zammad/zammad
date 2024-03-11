class App.TicketZoomAlert extends App.ControllerObserver
  model: 'Ticket'
  observe:
    state_id: true
    preferences: true
  globalRerender: false

  render: (ticket) =>
    alert = new App.TicketZoomChannel(ticket).channelAlert()

    if not alert
      @html ''
      @el.addClass('hide')
      return

    element = App.view('ticket_zoom/alert')(alert: alert)

    @html element
    @el.removeClass('hide')
