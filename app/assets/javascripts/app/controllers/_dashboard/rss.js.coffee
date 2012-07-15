$ = jQuery.sub()

class App.DashboardRss extends App.Controller
  constructor: ->
    super
    
    
    # refresh list ever 600 sec.
    @interval( @fetch, 6000000, 'dashboard_rss' )

  fetch: =>

    # use cache of first page
    if window.LastRefresh[ 'dashboard_rss' ]
      @render( window.LastRefresh[ 'dashboard_rss' ] )

    # get data
    App.Com.ajax(
      id:    'dashboard_rss',
      type:  'GET',
      url:   '/rss_fetch',
      data:  {
        limit: @limit,
        url:   @url,
      }
      processData: true,
      success: @load
    )

  load: (data) =>
    items = data.items || []
    
    # set cache
    window.LastRefresh[ 'dashboard_rss' ] = items
    
    @render(items)

  render: (items) ->
    html = App.view('dashboard/rss')(
      head:  @head,
      items: items
    )
    html = $(html)
    @html html
