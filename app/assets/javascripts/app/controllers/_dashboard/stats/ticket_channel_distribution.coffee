class Stats extends App.ControllerDashboardStatsBase
  render: (data = {}) ->
    if !data.StatsTicketChannelDistribution
      data.StatsTicketChannelDistribution =
        channels:
          1:
            icon:                'email'
            sender:              'email'
            inbound:             0
            outbound:            0
            inbound_in_percent:  0
            outbound_in_percent: 0
          2:
            icon:                'phone'
            sender:              'phone'
            inbound:             0
            outbound:            0
            inbound_in_percent:  0
            outbound_in_percent: 0

    totalTickets = _.reduce data.StatsTicketChannelDistribution.channels, ((memo, channel) -> memo + channel.inbound + channel.outbound), 0
    totalChannels = _.size data.StatsTicketChannelDistribution.channels

    for id, channel of data.StatsTicketChannelDistribution.channels
      channel.overal_percentage = Math.round((channel.inbound + channel.outbound) / totalTickets * 100) || 0

    data.StatsTicketChannelDistribution.description =  'How many of your tickets are coming from email, phone, Twitter, or Facebook? (Shows percentages for both inbound and outbound tickets.)'

    content = App.view('dashboard/stats/ticket_channel_distribution')(data)

    if @$('.ticket_channel_distribution').length > 0
      @$('.ticket_channel_distribution').html(content)
    else
      @el.append(content)

App.Config.set('ticket_channel_distribution', { controller: Stats, permission: 'ticket.agent', prio: 300, className: 'ticket_channel_distribution' }, 'Stats')
