class App.TicketZoomMeta extends App.Controller
  constructor: ->
    super
    @render()

    # rerender, e. g. on language change
    @bind('ui:rerender', =>
      @render()
    )

  render: (ticket) =>
    if !ticket
      ticket = App.Ticket.fullLocal(@ticket.id)

    if !@subscribeId
      @subscribeId = @ticket.subscribe(@render)

    @html App.view('ticket_zoom/meta')(
      ticket:     ticket
      isCustomer: @isRole('Customer')
    )

  release: =>
    App.Ticket.unsubscribe(@subscribeId)
