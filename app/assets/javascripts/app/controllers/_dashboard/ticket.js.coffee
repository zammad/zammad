class App.DashboardTicket extends App.Controller
  events:
    'click [data-type=settings]': 'settings'
    'click [data-type=page]':     'page'

  constructor: ->
    super
    @start_page = 1

    # set new key
    @key = 'ticket_overview_' + @view

    # bind to rebuild view event
    @bind( 'ticket_overview_rebuild', @fetch )

    # render
    @fetch()

  fetch: (force) =>

    # use cache of first page
    cache = App.Store.get( @key )
    if !force && cache
      @load( cache )

    # init fetch via ajax, all other updates on time via websockets
    else
      @ajax(
        id:    'dashboard_ticket_' + @key,
        type:  'GET',
        url:   @apiPath + '/ticket_overviews',
        data:  {
          view:       @view,
          view_mode:  'd',
          start_page: @start_page,
        }
        processData: true,
        success: (data) =>
          @load( data, true )
      )

  load: (data, ajax = false) =>

    if ajax
      App.Store.write( @key, data )

      # load assets
      App.Collection.loadAssets( data.assets )

    # get meta data
    App.Overview.refresh( data.overview, options: { clear: true } )

    App.Overview.unbind('local:rerender')
    App.Overview.bind 'local:rerender', (record) =>
      @log 'notice', 'rerender...', record
      data.overview = record
      @render(data)

    App.Overview.unbind('local:refetch')
    App.Overview.bind 'local:refetch', (record) =>
      @log 'notice', 'refetch...', record
      @fetch(true)

    @render( data )

  render: (data) ->
    return if !data
    return if !data.ticket_ids
    return if !data.overview

    @overview      = data.overview
    @tickets_count = data.tickets_count
    @ticket_ids    = data.ticket_ids
    per_page    = @overview.view.per_page || 10
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
        @tickets_in_table.push App.Ticket.retrieve( @ticket_ids[ i - 1 ] )

    openTicket = (id,e) =>
      ticket = App.Ticket.retrieve(id)
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
      overview:          @overview.view.d
      el:                html.find('.table-overview'),
      model:             App.Ticket
      objects:           @tickets_in_table,
      checkbox:          false
      groupBy:           @overview.group_by
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
    position = $(e.target).parents('[data-position]').data('position')

    @Config.set('LastOverview', @view )
    @Config.set('LastOverviewPosition', position )
    @Config.set('LastOverviewTotal', @tickets_count )

    @navigate 'ticket/zoom/' + id + '/nav/true'

  settings: (e) =>
    e.preventDefault()
    new App.OverviewSettings(
      overview_id: @overview.id
      view_mode:   'd'
    )

  page: (e) =>
    e.preventDefault()
    id = $(e.target).data('id')
    @start_page = id
    @fetch()

