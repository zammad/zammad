class App.TicketZoomMeta extends App.ControllerObserver
  @extend App.PopoverProvidable
  @registerPopovers 'Escalation'
  events:
    'click .ticket-number-copy > .ticketNumberCopy-icon': 'copyTicketNumber'

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
    @renderPopovers()

  copyTicketNumber: =>
    text = @el.find('.js-objectNumber').first().data('number') || ''
    if text
      @copyToClipboardWithTooltip(text, '.ticket-number-copy', '.main')
