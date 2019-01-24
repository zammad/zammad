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
    if !data.StatsTicketChannelDistribution
      data.StatsTicketChannelDistribution =
        channels:
          1:
            inbound: 1
            outbound: 0
            inbound_in_percent: 0
            outbound_in_percent: 0
          2:
            inbound: 0
            outbound: 0
            inbound_in_percent: 0
            outbound_in_percent: 0
          3:
            inbound: 2
            outbound: 0
            inbound_in_percent: 0
            outbound_in_percent: 0

    content = App.view('dashboard/stats/ticket_channel_distribution')(data)

    if @$('.ticket_channel_distribution').length > 0
      @$('.ticket_channel_distribution').html(content)
    else
      @el.append(content)

App.Config.set('ticket_channel_distribution', {controller: Stats, permission: 'ticket.agent', prio: 300 }, 'Stats')
