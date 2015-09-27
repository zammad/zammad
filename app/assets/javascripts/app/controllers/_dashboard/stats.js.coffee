class App.DashboardStats extends App.Controller
  constructor: ->
    super
    @load()
    @bind('dashboard_stats_rebuild', @load)

  load: =>
    stats_store = App.StatsStore.first()
    if stats_store
      @render(stats_store.data)
    else
      @render()

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

  renderWidgetClockFace: (time, max_time = 60) =>
    canvas = @el.find 'canvas'
    ctx    = canvas.get(0).getContext '2d'
    radius = 26

    @el.find('.time.stat-widget .stat-amount').text time

    canvas.attr 'width', 2 * radius
    canvas.attr 'height', 2 * radius

    time = max_time if time > max_time

    handlingTimeColors = {}
    handlingTimeColors[max_time/12] = '#38AE6A' # supergood
    handlingTimeColors[max_time/6] = '#A9AC41' # good
    handlingTimeColors[max_time/4] = '#FAAB00' # ok
    handlingTimeColors[max_time/3] = '#F6820B' # bad
    handlingTimeColors[max_time/2] = '#F35910' # superbad

    for handlingTime, timeColor of handlingTimeColors
      if time <= handlingTime
        backgroundColor = timeColor
        break

    # 30% background
    if time isnt 0
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
    arcsector = Math.PI * 2 * time/max_time
    ctx.arc radius, radius, radius, -Math.PI/2, arcsector - Math.PI/2, false
    ctx.lineTo radius, radius
    ctx.closePath()
    ctx.fill()
