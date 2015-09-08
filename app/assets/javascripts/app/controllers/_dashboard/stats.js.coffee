class App.DashboardStats extends App.Controller
  constructor: ->
    super

    stats_store = App.StatsStore.first()
    if stats_store
      @render(stats_store.data)
    else
      @render()

    # bind to rebuild view event
    @bind('dashboard_stats_rebuild', @render)

  render: (data = {}) ->
    if !data.TicketResponseTime
      data.TicketResponseTime =
        handling_time: 0
        average: 0
        average_per_agent: 0
    if !data.StatsTicketEscalation
      data.StatsTicketEscalation =
        state: 'supergood'
        own: 0
        total: 0
    if !data.StatsTicketChannelDistribution
      data.StatsTicketChannelDistribution =
        channels:
          1:
            inbound: 0
            outbound: 0
            inbound_in_percent: 0
            outbound_in_percent: 0
          2:
            inbound: 0
            outbound: 0
            inbound_in_percent: 0
            outbound_in_percent: 0
          3:
            inbound: 0
            outbound: 0
            inbound_in_percent: 0
            outbound_in_percent: 0
    if !data.StatsTicketLoadMeasure
      data.StatsTicketLoadMeasure =
        state: 'supergood'
        percent: 0
        own: 0
        total: 0
        average_per_agent: 0
    if !data.StatsTicketInProcess
      data.StatsTicketInProcess =
        state: 'supergood'
        percent: 0
        average_per_agent: 0
    if !data.StatsTicketReopen
      data.StatsTicketReopen =
        state: 'supergood'
        percent: 0
        average_per_agent: 0

    @html App.view('dashboard/stats')(data)

    if data.TicketResponseTime
      @renderWidgetClockFace data.TicketResponseTime.handling_time

  renderWidgetClockFace: (time) =>
    canvas = @el.find 'canvas'
    ctx    = canvas.get(0).getContext '2d'
    radius = 26

    @el.find('.time.stat-widget .stat-amount').text time

    canvas.attr 'width', 2 * radius
    canvas.attr 'height', 2 * radius

    time = 60 if time > 60

    handlingTimeColors =
      5: '#38AE6A' # supergood
      10: '#A9AC41' # good
      15: '#FAAB00' # ok
      20: '#F6820B' # bad
      25: '#F35910' # superbad

    for handlingTime, timeColor of handlingTimeColors
      if time <= handlingTime
        backgroundColor = timeColor
        break

    # 30% background
    ctx.globalAlpha = 0.3
    ctx.fillStyle = backgroundColor
    ctx.beginPath()
    ctx.arc radius, radius, radius, 0, Math.PI * 2, true
    ctx.closePath()
    ctx.fill()

    # 100% pie piece
    ctx.globalAlpha = 1

    ctx.beginPath()
    ctx.moveTo radius, radius
    arcsector = Math.PI * 2 * time/60
    ctx.arc radius, radius, radius, -Math.PI/2, arcsector - Math.PI/2, false
    ctx.lineTo radius, radius
    ctx.closePath()
    ctx.fill()
