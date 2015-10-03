class App.TicketZoomMeta extends App.Controller
  constructor: ->
    super

    @ticket = App.Ticket.fullLocal(@ticket.id)
    @render(@ticket)
    @subscribeId = @ticket.subscribe(@render)

  render: (ticket) =>
    @html App.view('ticket_zoom/meta')(
      ticket:     ticket
      isCustomer: @isRole('Customer')
    )

  release: =>
    App.Ticket.unsubscribe(@subscribeId)
