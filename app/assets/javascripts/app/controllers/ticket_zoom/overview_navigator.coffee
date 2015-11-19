class App.TicketZoomOverviewNavigator extends App.Controller
  events:
    'click a': 'open'

  constructor: ->
    super

    return if !@overview_id

    # rebuild overview navigator if overview has changed
    lateUpdate = =>
      @delay(@render, 2600, 'overview-navigator')

    @overview = App.Overview.find(@overview_id)
    @bindId = App.OverviewCollection.bind(@overview.link, lateUpdate, false)

    @render()

  release: =>
    App.OverviewCollection.unbind(@bindId)

  render: =>
    if !@overview_id
      @html('')
      return

    # get overview data
    overview = App.OverviewCollection.get(@overview.link)
    return if !overview
    current_position = 0
    found            = false
    next             = false
    previous         = false
    for ticket_id in overview.ticket_ids
      current_position += 1
      next              = overview.ticket_ids[current_position]
      previous          = overview.ticket_ids[current_position-2]
      if ticket_id is @ticket_id
        found = true
        break

    if !found
      @html('')
      return

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