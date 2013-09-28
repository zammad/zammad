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
          limit: @limit || 8
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
      if item.object is 'Ticket'
        ticket = App.Ticket.find( item.o_id )
        item.link = '#ticket/zoom/' + ticket.id
        item.title = ticket.title
        item.object = 'Ticket'

      else if item.object is 'Ticket::Article'
        article = App.TicketArticle.find( item.o_id )
        ticket  = App.Ticket.find( article.ticket_id )
        item.link = '#ticket/zoom/' + ticket.id + '/' + article.id
        item.title = article.subject || ticket.title
        item.object = 'Article'

      else if item.object is 'User'
        user = App.User.find( item.o_id )
        item.link = '#user/zoom/' + item.o_id
        item.title = user.displayName()
        item.object = 'User'

      item.created_by = App.User.find( item.created_by_id )

    html = App.view('dashboard/activity_stream')(
      head: 'Activity Stream',
      items: items
    )
    html = $(html)

    @html html

    # start user popups
    @userPopups('right')

    # update time
    @frontendTimeUpdate()
