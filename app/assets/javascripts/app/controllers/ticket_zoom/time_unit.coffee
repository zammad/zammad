class App.TicketZoomTimeUnit extends App.ControllerObserver
  @include App.TimeAccountingUnitMixin

  model: 'Ticket'
  observe:
    time_unit: true
  events:
    'click .js-showMoreEntries': 'showMoreEntries'

  constructor: ->
    super

    @controllerBind('config_update', (data) =>
      return if not /^time_accounting_unit/.test(data.name)
      @rerenderCallback()
    )

    @showAllEntries = false

  render: (ticket) =>
    return if ticket.currentView() isnt 'agent'
    return if !ticket.time_unit

    @ticket = ticket

    entries = @fetchEntries()

    list = entries.slice(0, 3)
    if @showAllEntries
      list = entries

    # Don't show anything if there are no entries besides "none"
    if list.length is 1 && list[0][0] is __('none')
      list = []

    @html App.view('ticket_zoom/time_unit')(
      ticket:      ticket
      displayUnit: @timeAccountingDisplayUnit()
      list:        list
      showMore:    entries.length > 3 && !@showAllEntries
    )

  fetchEntries: ->
    filtered = App.TicketTimeAccounting.search(
      filter:
        ticket_id: @ticket.id
    )
    return [] if !filtered || filtered.length is 0

    types   = _.indexBy(App.TicketTimeAccountingType.all(), 'id')
    grouped = _.groupBy(filtered, (time_accounting) -> time_accounting.type_id)
    mapped  = _.map(grouped, (list, type_id) ->
      iteratee = (sum, time_accounting) -> sum + parseFloat(time_accounting.time_unit)

      [types[type_id]?.name || __('none'), _.reduce(list, iteratee, 0)]
    )

    _.sortBy(mapped, (group) -> group[1]).reverse()

  showMoreEntries: (e) ->
    @preventDefaultAndStopPropagation(e)
    @showAllEntries = true
    @render(@ticket)
