class App.DashboardRecentViewed extends App.Controller
  constructor: ->
    super

    @items = []

    # get data
    @ajax(
      id:    'dashboard_recent_viewed',
      type:  'GET',
      url:   @apiPath + '/recent_viewed',
      data:  {
        limit: 5,
      }
      processData: true,
      success: (data, status, xhr) =>
        @items = data.recent_viewed

        # load assets
        App.Collection.loadAssets( data.assets )

        @render()
    )

  render: ->

    for item in @items
      item.link = '#ticket_zoom/' + item.o_id
      item.title = App.Ticket.find( item.o_id ).title
      item.type  = item.recent_view_object

    html = App.view('dashboard/recent_viewed')(
      head: 'Recent Viewed',
      items: @items
    )
    html = $(html)

    @html html

    # start user popups
    @userPopups('left')
