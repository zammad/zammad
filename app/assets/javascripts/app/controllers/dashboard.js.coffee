class Index extends App.ControllerContent

  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    if @isRole('Customer')
      @navigate '#'
      return

    # set title
    @title 'Dashboard'
    @navupdate '#dashboard'

    @plugins = {
      main: {
        my_assigned: {
          controller: App.DashboardTicket,
          params: {
            view: 'my_assigned',
          },
        },
        all_unassigned: {
          controller: App.DashboardTicket,
          params: {
            view: 'all_unassigned',
          },
        },
      },
      side: {
        activity_stream: {
          controller: App.DashboardActivityStream,
          params: {
            limit: 20,
          },
        },
#        rss_atom: {
#          controller: App.DashboardRss,
#          params: {
#            head:  'Heise ATOM',
#            url:   'http://www.heise.de/newsticker/heise-atom.xml',
#            limit: 5,
#          },
#        },
#        rss_rdf: {
#          controller: App.DashboardRss,
#          params: {
#            head:  'Heise RDF',
#            url:   'http://www.heise.de/newsticker/heise.rdf',
#            limit: 5,
#          },
#        },
#        recent_viewed: {
#          controller: App.DashboardRecentViewed,
#        }
      }
    }

    # render page
    @render()

  render: ->

    @html App.view('dashboard')(
      head: 'Dashboard'
    )

    for area, plugins of @plugins
      for name, plugin of plugins
        target = area + '_' + name
        @el.find('.' + area + '-overviews').append('<div class="" id="' + target + '"></div>')
        if plugin.controller
          params = plugin.params || {}
          params.el = @el.find( '#' + target )
          new plugin.controller( params )

    dndOptions =
      handle:               'h2.can-move'
      placeholder:          'can-move-plcaeholder'
      tolerance:            'pointer'
      distance:             15
      opacity:              0.6
      forcePlaceholderSize: true

    @renderWidgetClockFace 25

    @el.find( '#sortable' ).sortable( dndOptions )
    @el.find( '#sortable-sidebar' ).sortable( dndOptions )

  renderWidgetClockFace: (time) =>
    canvas = @el.find 'canvas'
    ctx = canvas.get(0).getContext '2d'
    radius = 26

    @el.find('.time.stat-widget .stat-amount').text time

    canvas.attr 'width', 2 * radius
    canvas.attr 'height', 2 * radius

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

App.Config.set( 'dashboard', Index, 'Routes' )
App.Config.set( 'Dashboard', { prio: 100, parent: '', name: 'Dashboard', target: '#dashboard', role: ['Agent'], class: 'dashboard' }, 'NavBar' )

