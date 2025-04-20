class Stats extends App.ControllerDashboardStatsBase
  render: (data = {}) ->
    if !data.StatsTicketCreatedToday
      data.StatsTicketCreatedToday =
        tickets_today: 0
        daily_average: 0

    data.StatsTicketCreatedToday.description = __('How many tickets were created today?')

    content = App.view('dashboard/stats/ticket_created_today')(data)

    if @$('.ticket_created_today').length > 0
      @$('.ticket_created_today').html(content)
    else
      @el.append(content)

App.Config.set('ticket_created_today', { controller: Stats, permission: 'ticket.agent', prio: 700, className: 'ticket_created_today' }, 'Stats')
