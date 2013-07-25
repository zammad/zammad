class App.DashboardRss extends App.Controller
  constructor: ->
    super

    # bind to rebuild view event
    @bind( 'rss_rebuild', @fetch )

    # refresh list ever 600 sec.
    @fetch()

  fetch: =>

    # get data from cache
    cache = App.Store.get( 'dashboard_rss' )
    if cache
      cache.head = 'Heise ATOM'
      @render( cache )

    # init fetch via ajax, all other updates on time via websockets
    else
      App.Com.ajax(
        id:    'dashboard_rss'
        type:  'GET'
        url:   'api/rss_fetch'
        data:  {
          limit: 8
          url:   'http://www.heise.de/newsticker/heise-atom.xml'
        }
        processData: true
        success: (data) =>
          if data.message
            @render(
              head:    'Heise ATOM'
              message: data.message
            )
          else
            App.Store.write( 'dashboard_rss', data )
            data.head = 'Heise ATOM'
            @render(data)
        error: =>
          @render(
            head:    'Heise ATOM'
            message: 'Unable to fetch rss!'
          )
      )

  render: (data) ->
    @html App.view('dashboard/rss')(
      head:  data.head,
      items: data.items || []
      message: data.message
    )
