class App.TicketZoomOverviewNavigator extends App.Controller
  @include App.TicketNavigable

  events:
    'click a': 'open'

  constructor: ->
    super

    return if !@overview_id

    # rebuild overview navigator if overview has changed
    lateUpdate = =>
      @delay(@render, 2600, 'overview-navigator')

    @overview = App.Overview.find(@overview_id)
    @bindId = App.OverviewListCollection.bind(@overview.link, lateUpdate, false)

    @render()

  release: =>
    App.OverviewListCollection.unbind(@bindId)

  render: =>
    if !@overview_id
      @html('')
      return

    # get overview data
    overview = App.OverviewListCollection.get(@overview.link)
    return if !overview
    current_position = 0
    found            = false
    item_next        = false
    item_previous    = false
    for ticket in overview.tickets
      current_position += 1
      item_next         = overview.tickets[current_position]
      item_previous     = overview.tickets[current_position-2]
      if ticket.id is @ticket_id
        found = true
        break

    if !found
      @html('')
      return

    # get next/previous ticket
    if item_next
      next = App.Ticket.find(item_next.id)
    if item_previous
      previous = App.Ticket.find(item_previous.id)

    @html App.view('ticket_zoom/overview_navigator')(
      title:            overview.overview.name
      total_count:      overview.count
      current_position: current_position
      next:             next
      previous:         previous
    )

  open: (e) =>
    e.preventDefault()
    ticketLink = $(e.target)

    if (id = ticketLink.data('id'))?
      url = ticketLink.attr('href')
    else if (id = ticketLink.closest('a').data('id'))?
      url = ticketLink.closest('a').attr('href')
    else
      return

    @taskOpenTicket(id, url)
