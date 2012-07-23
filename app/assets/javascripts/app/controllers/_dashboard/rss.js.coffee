$ = jQuery.sub()

class App.DashboardRss extends App.Controller
  constructor: ->
    super

    # refresh list ever 600 sec.
    Spine.bind 'rss_rebuild', (data) =>
      @load(data)

    # use cache of first page
    if window.LastRefresh[ 'dashboard_rss' ]
      @load( window.LastRefresh[ 'dashboard_rss' ] )

  load: (data) =>
    items = data.items || []
    @head = data.head || '?'
    @render(items)

  render: (items) ->
    html = App.view('dashboard/rss')(
      head:  @head,
      items: items
    )
    html = $(html)
    @html html
