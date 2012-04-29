$ = jQuery.sub()

class App.DashboardRss extends App.Controller
  constructor: ->
    super
#    @log 'aaaa', @el
    
    @items = []
    
    # get data
    @ajax = new App.Ajax
    @ajax.ajax(
      type:  'GET',
      url:   '/rss_fetch',
      data:  {
        limit: @limit,
        url:   @url,
      }
      processData: true,
      success: (data, status, xhr) =>
        @items = data.items || []
        @render()
    )

  render: ->
    html = App.view('dashboard/rss')(
      head:  @head,
      items: @items
    )
    html = $(html)
    @html html
