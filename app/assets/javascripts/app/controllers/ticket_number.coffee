class TicketZoomHookRouter extends App.ControllerPermanent
  requiredPermission: ['ticket.agent', 'ticket.customer']
  constructor: (params) ->
    super

    target_ticket = App.Ticket.findByAttribute('number', params.ticket_number);

    if (target_ticket)
      window.location.replace(target_ticket.uiUrl())
    else
      window.location.replace("#ticket/zoom/0")

App.Config.set('ticket/number/:ticket_number', TicketZoomHookRouter, 'Routes')
