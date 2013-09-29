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
