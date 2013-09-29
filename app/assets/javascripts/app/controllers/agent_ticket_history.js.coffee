class App.TicketHistory extends App.ControllerModal
  events:
    'click [data-type=sortorder]': 'sortorder',
    'click .cancel': 'modalHide',
    'click .close':  'modalHide',

  constructor: ->
    super
    @fetch(@ticket_id)

  fetch: (@ticket_id) ->

    # get data
    @ajax(
      id:    'ticket_history',
      type:  'GET',
      url:   @apiPath + '/ticket_history/' + ticket_id,
      success: (data, status, xhr) =>

        # load collections
        App.Event.trigger 'loadAssets', data.assets


        # render page
        @render(data.history)
    )

  render: ( items, orderClass = '' ) ->

    for item in items

      item.link  = ''
      item.title = '???'

      if item.object is 'Ticket::Article'
        item.object = 'Article'
        article = App.TicketArticle.find( item.o_id )
        ticket  = App.Ticket.find( article.ticket_id )
        item.title = article.subject || ticket.title
        item.link  = article.uiUrl()

      if App[item.object]
        object     = App[item.object].find( item.o_id )
        item.link  = object.uiUrl()
        item.title = object.displayName()

      item.created_by = App.User.find( item.created_by_id )

    # set cache
    @historyListCache = items

    @html App.view('agent_ticket_history')(
      items: items
      orderClass: orderClass

      @historyListCache
    )

    @modalShow()

    # enable user popups
    @userPopups()

    # show frontend times
    @delay( @frontendTimeUpdate, 300, 'ui-time-update' )

  sortorder: (e) ->
    e.preventDefault()
    idDown = @el.find('[data-type="sortorder"]').hasClass('down')

    if idDown
      @render( @historyListCache, 'up' )
    else
      @render( @historyListCache.reverse(), 'down' )
