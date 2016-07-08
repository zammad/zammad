class App.TicketCustomerAvatar extends App.ObserverController
  model: 'Ticket'
  observe:
    customer_id: true
  globalRerender: false

  render: (ticket) =>
    new App.WidgetAvatar(
      el:        @el.find('.js-avatar')
      object_id: ticket.customer_id
      size:      50
    )
