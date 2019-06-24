class Stats extends App.Controller
  constructor: ->
    super
    @load()

  load: =>
    stats_store = App.StatsStore.first()
    if stats_store
      @render(stats_store.data)
    else
      @render()

  render: (data = {}) ->
    if !data.StatsTicketInProcess
      data.StatsTicketInProcess =
        state: 'supergood'
        percent: 0
        average_per_agent: 0

    data.StatsTicketInProcess.description = 'What percentage of your tickets have you responded to, updated, or modified in some way today?'

    content = App.view('dashboard/stats/ticket_in_process')(data)

    if @$('.ticket_in_process').length > 0
      @$('.ticket_in_process').html(content)
    else
      @el.append(content)


App.Config.set('ticket_in_process', {controller: Stats, permission: 'ticket.agent', prio: 500 }, 'Stats')
