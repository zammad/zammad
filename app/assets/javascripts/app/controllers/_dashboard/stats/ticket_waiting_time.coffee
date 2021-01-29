class Stats extends App.ControllerDashboardStatsBase
  render: (data = {}) ->
    if !data.StatsTicketWaitingTime
      data.StatsTicketWaitingTime =
        handling_time: 0
        average: 0
        state: 'supergood'
        average_per_agent: 0

    data.StatsTicketWaitingTime.description = 'How long has each customer had to wait, on average, to get a response from you today?'

    content = App.view('dashboard/stats/ticket_waiting_time')(data)
    if @$('.ticket_waiting_time').length > 0
      @$('.ticket_waiting_time').html(content)
    else
      @el.append(content)

    if data.StatsTicketWaitingTime
      @renderWidgetClockFace(data.StatsTicketWaitingTime.handling_time, data.StatsTicketWaitingTime.state, data.StatsTicketWaitingTime.percent)

  renderWidgetClockFace: (time, state, percent) =>
    dpr = window.devicePixelRatio || 1
    canvas = @el.find 'canvas'
    ctx    = canvas.get(0).getContext '2d'
    radius = 26

    @el.find('.time.stat-widget .stat-amount').text time

    canvas.attr 'width', 2 * radius * dpr
    canvas.attr 'height', 2 * radius * dpr

    # scale canvas to dpr (2x on retina)
    ctx.scale dpr, dpr

    handlingTimeColors = {}
    handlingTimeColors['supergood'] = '#38AE6A' # supergood
    handlingTimeColors['good']      = '#A9AC41' # good
    handlingTimeColors['ok']        = '#FAAB00' # ok
    handlingTimeColors['bad']       = '#F6820B' # bad
    handlingTimeColors['superbad']  = '#F35910' # superbad

    for handlingState, timeColor of handlingTimeColors
      if state == handlingState
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
    arcsector = Math.PI * 2 * percent
    ctx.arc radius, radius, radius, -Math.PI/2, arcsector - Math.PI/2, false
    ctx.lineTo radius, radius
    ctx.closePath()
    ctx.fill()

App.Config.set('ticket_waiting_time', { controller: Stats, permission: 'ticket.agent', prio: 100, className: 'ticket_waiting_time' }, 'Stats')
