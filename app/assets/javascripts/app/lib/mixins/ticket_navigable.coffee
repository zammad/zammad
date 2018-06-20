# Defines common controller behavior for:
#
#   * individual ticket pages ('ticket_zoom')
#   * ticket listings ('overviews')
#
# Relies on @overview_id and @ticket_id instance variables
App.TicketNavigable =
  openTicket: (ticket_id, url) ->
    # coerce Ticket objects to id
    ticket_id = ticket_id.id if (ticket_id instanceof App.Ticket)

    @loadTicketTask(ticket_id)
    @navigate url ? "ticket/zoom/#{ticket_id}"

  # preserves overview information
  loadTicketTask: (ticket_id) ->
    App.TaskManager.execute(
      key:        "Ticket-#{ticket_id}"
      controller: 'TicketZoom'
      params:     { ticket_id: ticket_id, overview_id: @overview_id }
      show:       true
    )

  openNextTicketInOverview: ->
    return if !(@overview_id? && @ticket?)
    next_ticket = App.Overview.find(@overview_id).nextTicket(@ticket)
    @openTicket(next_ticket.id)
