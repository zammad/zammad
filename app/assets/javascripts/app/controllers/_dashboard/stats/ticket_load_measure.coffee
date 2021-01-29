class Stats extends App.ControllerDashboardStatsBase
  render: (data = {}) ->
    if !data.StatsTicketLoadMeasure
      data.StatsTicketLoadMeasure =
        state: 'supergood'
        percent: 0
        own: 0
        total: 0
        average_per_agent: 0

    data.StatsTicketLoadMeasure.description = 'Out of all open tickets (company-wide), how many are assigned to you?'

    content = App.view('dashboard/stats/ticket_load_measure')(data)

    if @$('.ticket_load_measure').length > 0
      @$('.ticket_load_measure').html(content)
    else
      @el.append(content)

App.Config.set('ticket_load_measure', { controller: Stats, permission: 'ticket.agent', prio: 400, className: 'ticket_load_measure' }, 'Stats')
