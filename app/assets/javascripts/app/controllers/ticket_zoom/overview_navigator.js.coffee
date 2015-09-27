class App.TicketZoomOverviewNavigator extends App.Controller
  events:
    'click a': 'open'

  constructor: ->
    super

    # rebuild overview navigator if overview has changed
    @bind 'ticket_overview_rebuild', (data) =>
      execute = =>
        @render()
      @delay(execute, 1600, 'overview-navigator')

    @render()

  render: (overview) =>
    if !@overview_id
      @html('')
      return

    # get overview data
    worker = App.TaskManager.worker( 'TicketOverview' )
    return if !worker
    overview = worker.overview(@overview_id)
    return if !overview
    current_position = 0
    next             = false
    previous         = false
    for ticket_id in overview.ticket_ids
      current_position += 1
      next              = overview.ticket_ids[current_position]
      previous          = overview.ticket_ids[current_position-2]
      break if ticket_id is @ticket_id

    # get next/previous ticket
    if next
      next = App.Ticket.find(next)
    if previous
      previous = App.Ticket.find(previous)

    @html App.view('ticket_zoom/overview_navigator')(
      title:            overview.overview.name
      total_count:      overview.tickets_count
      current_position: current_position
      next:             next
      previous:         previous
    )

  open: (e) =>
    e.preventDefault()

    # get requested object and location
    id  = $(e.target).data('id')
    url = $(e.target).attr('href')
    if !id
      id  = $(e.target).closest('a').data('id')
      url = $(e.target).closest('a').attr('href')

    # return if we are unable to get id
    return if !id

    # open task via task manager to get overview information
    App.TaskManager.execute(
      key:        'Ticket-' + id
      controller: 'TicketZoom'
      params:
        ticket_id:   id
        overview_id: @overview_id
      show:       true
    )
    @navigate url