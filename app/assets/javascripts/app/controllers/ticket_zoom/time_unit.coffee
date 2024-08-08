class App.TicketZoomTimeUnit extends App.Controller
  @include App.TimeAccountingUnitMixin

  events:
    'click .js-showMoreEntries': 'showMoreEntries'

  constructor: ->
    super

    @controllerBind('config_update', (data) =>
      return if not /^time_accounting_unit/.test(data.name)
      @render()
    )

    @showAllEntries = false

  reload: (time_accountings) =>
    @time_accountings = time_accountings
    @render()

  render: =>
    ticket = App.Ticket.find(@object_id)

    return if ticket.currentView() isnt 'agent'
    return if !ticket.time_unit

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
    return [] if !App.Config.get('time_accounting_types')

    filtered = @time_accountings
    return [] if !filtered || filtered.length is 0

    types   = _.indexBy(App.TicketTimeAccountingType.all(), 'id')
    grouped = _.groupBy(filtered, (time_accounting) -> time_accounting.type_id)
    mapped  = _.map(grouped, (list, type_id) ->
      iteratee = (sum, time_accounting) -> sum + parseFloat(time_accounting.time_unit)

      [types[type_id]?.name || __('None'), _.reduce(list, iteratee, 0)]
    )
    return [] if mapped.length is 1 && mapped[0][0] is 'None'

    _.sortBy(mapped, (group) -> group[1]).reverse()

  showMoreEntries: (e) ->
    @preventDefaultAndStopPropagation(e)
    @showAllEntries = true
    @render()
