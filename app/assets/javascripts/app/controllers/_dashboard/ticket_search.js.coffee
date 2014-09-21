class App.DashboardTicketSearch extends App.Controller
  events:
    'click [data-type=page]':     'page'

  constructor: ->
    super
    @item_from = 1
    @navupdate '#'

    @key = @name + Math.floor( Math.random() * 999999 ).toString()

    # render
    @fetch()

  fetch: (force) =>

    @ajax(
      id:    'dashboard_ticket_search' + @key,
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
      App.Store.write( 'dashboard_ticket_search' + @key, data )

      # load assets
      App.Collection.loadAssets( data.assets )

      @render( data )

    else
      data = App.Store.get( 'dashboard_ticket_search' + @key )
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

    items_total    = @tickets_count
    items_per_page = Math.min(per_page || 10, @tickets_count)
    items_from     = @item_from
    items_till     = items_from-1 + items_per_page
    if items_till > items_total
      items_till = items_total
    html = App.view('dashboard/ticket')(
      overview:       @overview
      items_per_page: items_per_page
      items_from:     items_from
      items_till:     items_till
      items_total:    items_total
    )
    html = $(html)
    html.find('li').removeClass('active')
    html.find(".page [data-id=\"#{@start_page}\"]").parents('li').addClass('active')

    @tickets_in_table = []
    i = items_from - 1
    while i < items_till
      if @ticket_ids[ i ]
        @tickets_in_table.push App.Ticket.retrieve( @ticket_ids[ i ] )
      i = i + 1

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
    @item_from = id
    @load()

  page: (e) =>
    e.preventDefault()
    @item_from = $(e.target).data('from')
    if !@item_from
      @item_from = $(e.target).parent().data('from')
    return if !@item_from
    @load()
