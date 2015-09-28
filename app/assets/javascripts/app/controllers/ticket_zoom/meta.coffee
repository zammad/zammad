class App.TicketZoomMeta extends App.Controller
  constructor: ->
    super

    @ticket      = App.Ticket.fullLocal( @ticket.id )
    @subscribeId = @ticket.subscribe(@render)
    @render(@ticket)

  render: (ticket) =>
    @html App.view('ticket_zoom/meta')(
      ticket:     ticket
      isCustomer: @isRole('Customer')
    )

  release: =>
    App.Ticket.unsubscribe( @subscribeId )