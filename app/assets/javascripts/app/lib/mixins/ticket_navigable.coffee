# Defines common controller behavior for:
#
#   * individual ticket pages ('ticket_zoom')
#   * ticket listings ('overviews')
#
# Relies on @overview_id and @ticket_id instance variables
App.TicketNavigable =
  taskOpenTicket: (ticket_id, url) ->
    # coerce Ticket objects to id
    ticket_id = ticket_id.id if (ticket_id instanceof App.Ticket)
    @taskLoadTicket(ticket_id)
    @navigate(url ? "ticket/zoom/#{ticket_id}")

  # preserves overview information
  taskLoadTicket: (ticket_id) ->
    App.TaskManager.execute(
      key:        "Ticket-#{ticket_id}"
      controller: 'TicketZoom'
      params:
        ticket_id: ticket_id
        overview_id: @overview_id
      show:       true
    )

  taskOpenNextTicketInOverview: ->
    if !(@overview_id? && @ticket?)
      @taskCloseTicket(true)
      return
    next_ticket = App.Overview.find(@overview_id).nextTicket(@ticket)
    if next_ticket
      @taskCloseTicket()
      @taskLoadTicket(next_ticket.id)
      return
    @taskCloseTicket(true)

  taskCloseTicket: (openNext = false) ->
    App.TaskManager.remove(@taskKey)
    return if !openNext
    nextTaskUrl = App.TaskManager.nextTaskUrl()
    if nextTaskUrl
      @navigate nextTaskUrl
      return
    @navigate '#'
