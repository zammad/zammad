class App.DashboardRecentViewed extends App.Controller
  events:
    'click [data-type=edit]': 'zoom'

  constructor: ->
    super
#    @log 'aaaa', @el

    @items = []

    # get data
    App.Com.ajax(
      id:    'dashboard_recent_viewed',
      type:  'GET',
      url:   'api/recent_viewed',
      data:  {
        limit: 5,
      }
      processData: true,
#      data: JSON.stringify( view: @view ),
      success: (data, status, xhr) =>
        @items = data.recent_viewed

        # load user collection
        App.Collection.load( type: 'User', data: data.users )

        # load ticket collection
        App.Collection.load( type: 'Ticket', data: data.tickets )

        @render()
    )

  render: ->

    # load user data
    for item in @items
      item.created_by = App.Collection.find( 'User', item.created_by_id )

    # load ticket data
    for item in @items
      item.ticket = App.Collection.find( 'User', item.o_id )

    html = App.view('dashboard/recent_viewed')(
      head: 'Recent Viewed',
      items: @items
    )
    html = $(html)

    @html html

    # start user popups
    @userPopups('left')

  zoom: (e) =>
    e.preventDefault()
    id = $(e.target).parents('[data-id]').data('id')
    @log 'goto zoom!'
    @navigate 'ticket/zoom/' + id
