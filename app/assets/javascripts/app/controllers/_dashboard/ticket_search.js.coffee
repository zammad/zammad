class App.DashboardTicketSearch extends App.Controller
  events:
    'click [data-type=page]':     'page'

  constructor: ->
    super
    @start_page = 1
    @navupdate '#'

    # render
    @fetch()

  fetch: (force) =>

    @ajax(
      id:    'dashboard_ticket_search' + @name,
      type:  'GET',
      url:   @apiPath + '/tickets/search',
      data:
        condition:  @condition
        order:      @order
        detail:     true
        limit:      200
      processData: true,
      success: (data) =>

        @load( data, true )
    )

  load: (data = false, ajax = false) =>

    if ajax
      App.Store.write( 'dashboard_ticket_search' + @name, data )

      # load assets
      App.Collection.loadAssets( data.assets )

      @render( data )

    else
      data = App.Store.get( 'dashboard_ticket_search' + @name )
      if data
        @render( data )


  render: (data) ->
    return if !data
    return if !data.tickets

    @overview =
      name: @name
    @tickets_count = data.tickets_count
    @ticket_ids    = data.tickets
    per_page    = @per_page || 5
    pages_total =  parseInt( ( @tickets_count / per_page ) + 0.99999 ) || 1
    html = App.view('dashboard/ticket')(
      overview:    @overview,
      pages_total: pages_total,
      start_page:  @start_page,
    )
    html = $(html)
    html.find('li').removeClass('active')
    html.find(".page [data-id=\"#{@start_page}\"]").parents('li').addClass('active')

    @tickets_in_table = []
    start = ( @start_page-1 ) * 5
    end = ( @start_page ) * 5
    i = start
    while i < end
      i = i + 1
      if @ticket_ids[ i - 1 ]
        @tickets_in_table.push App.Ticket.fullLocal( @ticket_ids[ i - 1 ] )

    openTicket = (id,e) =>
      ticket = App.Ticket.fullLocal(id)
      @navigate ticket.uiUrl()
    callbackTicketTitleAdd = (value, object, attribute, attributes, refObject) =>
      attribute.title = object.title
      value
    callbackLinkToTicket = (value, object, attribute, attributes, refObject) =>
      attribute.link = object.uiUrl()
      value
    callbackResetLink = (value, object, attribute, attributes, refObject) =>
      attribute.link = undefined
      value
    callbackUserPopover = (value, object, attribute, attributes, refObject) =>
      attribute.class = 'user-popover'
      attribute.data =
        id: refObject.id
      value

    new App.ControllerTable(
      overview:          @view.d
      el:                html.find('.table-overview'),
      model:             App.Ticket
      objects:           @tickets_in_table,
      checkbox:          false
      groupBy:           @group_by
      bindRow:
        events:
          'click': openTicket
      callbackAttributes:
        customer_id:
          [ callbackResetLink, callbackUserPopover ]
        owner_id:
          [ callbackResetLink, callbackUserPopover ]
        title:
          [ callbackLinkToTicket, callbackTicketTitleAdd ]
        number:
          [ callbackLinkToTicket, callbackTicketTitleAdd ]
    )

    @html html

    # show frontend times
    @frontendTimeUpdate()

    # start user popups
    @userPopups()

  zoom: (e) =>
    e.preventDefault()
    id = $(e.target).parents('[data-id]').data('id')

    @navigate 'ticket/zoom/' + id

  page: (e) =>
    e.preventDefault()
    id = $(e.target).data('id')
    @start_page = id
    @load()

