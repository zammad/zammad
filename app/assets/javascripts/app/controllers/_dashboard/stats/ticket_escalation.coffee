class Stats extends App.ControllerDashboardStatsBase
  render: (data = {}) ->
    if !data.StatsTicketEscalation
      data.StatsTicketEscalation =
        state: 'supergood'
        own: 0
        total: 0

    data.StatsTicketEscalation.description = 'How many escalated tickets do you have open? (Mr. Bubbles gets grumpy if you have too many…)'

    content = App.view('dashboard/stats/ticket_escalation')(data)

    if @$('.ticket_escalation').length > 0
      @$('.ticket_escalation').html(content)
    else
      @el.append(content)

App.Config.set('ticket_escalation', { controller: Stats, permission: 'ticket.agent', prio: 200, className: 'ticket_escalation' }, 'Stats')
