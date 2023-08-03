class App.TicketOrganizationAvatar extends App.ControllerObserver
  model: 'Ticket'
  observe:
    organization_id: true
  globalRerender: false

  render: (ticket) =>
    return if _.isNull(ticket.organization_id) or _.isUndefined(ticket.organization_id)

    new App.WidgetOrganizationAvatar(
      el:        @el.find('.js-avatar-organization')
      object_id: ticket.organization_id
      size:      50
    )
