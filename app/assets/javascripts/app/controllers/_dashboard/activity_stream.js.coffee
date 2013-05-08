class App.DashboardActivityStream extends App.Controller
  events:
    'click [data-type=edit]': 'zoom'

  constructor: ->
    super
    @items = []

    @fetch()

    # bind to rebuild view event
    App.Event.bind( 'activity_stream_rebuild', @load, 'page' )

  fetch: =>

    # use cache of first page
    cache = App.Store.get( 'activity_stream' )
    if cache
      @load( cache )

    # init fetch via ajax, all other updates on time via websockets
    else
      App.Com.ajax(
        id:    'dashoard_activity_stream'
        type:  'GET'
        url:   'api/activity_stream'
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

    # load user collection
    App.Collection.load( type: 'User', data: data.users )

    # load ticket collection
    App.Collection.load( type: 'Ticket', data: data.tickets )

    # load article collection
    App.Collection.load( type: 'TicketArticle', data: data.articles )

    @render(items)

  render: (items) ->

    # load user data
    for item in items
      item.created_by = App.Collection.find( 'User', item.created_by_id )

    # load ticket data
    for item in items
      item.data = {}
      if item.history_object is 'Ticket'
        item.data.title = App.Collection.find( 'Ticket', item.o_id ).title
      if item.history_object is 'Ticket::Article'
        article = App.Collection.find( 'TicketArticle', item.o_id )
        item.history_object = 'Article'
        item.sub_o_id = article.id
        item.o_id = article.ticket_id
        item.data.title = article.subject

    html = App.view('dashboard/activity_stream')(
      head: 'Activity Stream',
      items: items
    )
    html = $(html)

    @html html

    # start user popups
    @userPopups('left')

  zoom: (e) =>
    e.preventDefault()
    id = $(e.target).parents('[data-id]').data('id')
    subid = $(e.target).parents('[data-subid]').data('subid')
    @log 'goto zoom!', id, subid
    if subid
      @navigate 'ticket/zoom/' + id + '/' + subid
    else
      @navigate 'ticket/zoom/' + id
