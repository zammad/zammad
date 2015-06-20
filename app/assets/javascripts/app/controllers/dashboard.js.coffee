class App.Dashboard extends App.Controller
  events:
    'click .tabs .tab': 'toggle'
    'click .intro': 'clues'
  constructor: ->
    super

    if @isRole('Customer')
      @navigate '#'
      return

    # render page
    @render()

    # rerender view, e. g. on language change
    @bind 'ui:rerender', =>
      return if !@authenticate(true)
      @render()

  render: ->

    @html App.view('dashboard')(
      head: 'Dashboard'
    )

    new App.DashboardActivityStream(
      el:    @$('.sidebar')
      limit: 25
    )

    @renderWidgetClockFace 25

  clues: =>
    new App.FirstStepsClues(
      el: @el
    )

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

  active: (state) =>
    @activeState = state

  isActive: =>
    @activeState

  url: =>
    '#dashboard'

  show: (params) =>

    # set title
    @title 'Dashboard'

    # highlight navbar
    @navupdate '#dashboard'

  hide: =>
    # no

  changed: =>
    false

  release: =>
    # no

  toggle: (e) =>
    @$('.tabs .tab').removeClass('active')
    $(e.target).addClass('active')
    target = $(e.target).data('area')
    @$('.tab-content').addClass('hidden')
    @$(".tab-content.#{target}").removeClass('hidden')

class DashboardRouter extends App.ControllerPermanent
  constructor: (params) ->
    super

    # check authentication
    return if !@authenticate()

    App.TaskManager.execute(
      key:        'Dashboard'
      controller: 'Dashboard'
      params:     {}
      show:       true
      persistent: true
    )

App.Config.set( 'dashboard', DashboardRouter, 'Routes' )
App.Config.set( 'Dashboard', { prio: 100, parent: '', name: 'Dashboard', target: '#dashboard', role: ['Agent'], class: 'dashboard' }, 'NavBar' )
App.Config.set( 'Dashboard', { controller: 'Dashboard', authentication: true }, 'permanentTask' )
