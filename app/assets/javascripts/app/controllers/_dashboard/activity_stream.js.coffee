class App.DashboardActivityStream extends App.Controller
  constructor: ->
    super

    @fetch()

    # bind to rebuild view event
    @bind( 'activity_stream_rebuild', @load )

  fetch: =>

    # use cache of first page
    cache = App.Store.get( 'activity_stream' )
    if cache
      @load( cache )

    # init fetch via ajax, all other updates on time via websockets
    else
      @ajax(
        id:    'dashoard_activity_stream'
        type:  'GET'
        url:   @apiPath + '/activity_stream'
        data:  {
          limit: 8
        }
        processData: true
        success: (data) =>
          App.Store.write( 'activity_stream', data )
          @load(data)
      )

  load: (data) =>
    items = data.activity_stream

    # load collections
    App.Event.trigger 'loadAssets', data.assets

    @render(items)

  render: (items) ->

    for item in items
      if item.history_object is 'Ticket'
        ticket = App.Ticket.find( item.o_id )
        item.link = '#ticket_zoom/' + ticket.id
        item.title = ticket.title
        item.type  = item.history_object
        item.updated_by_id = ticket.updated_by_id
        item.updated_by = App.User.find( ticket.updated_by_id )
      else if item.history_object is 'Ticket::Article'
        article = App.TicketArticle.find( item.o_id )
        ticket  = App.Ticket.find( article.ticket_id )
        item.link = '#ticket_zoom/' + ticket.id + '/' + article.od
        item.title = article.subject || ticket.title
        item.type  = item.history_object
        item.updated_by_id = article.updated_by_id
        item.updated_by = App.User.find( article.updated_by_id )

    html = App.view('dashboard/activity_stream')(
      head: 'Activity Stream',
      items: items
    )
    html = $(html)

    @html html

    # start user popups
    @userPopups('left')

