class App.DashboardTicket extends App.Controller
  events:
    'click [data-type=edit]':     'zoom'
    'click [data-type=settings]': 'settings'
    'click [data-type=page]':     'page'

  constructor: ->
    super
    @start_page = 1
    @navupdate '#'

    # set new key
    @key = 'ticket_overview_' + @view

    # bind to rebuild view event
    @bind( 'ticket_overview_rebuild', @fetch )

    # render
    @fetch()

  fetch: =>

    # use cache of first page
    cache = App.Store.get( @key )
    if cache
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
          data.ajax = true
          @load(data)
      )

  load: (data) =>

    if data.ajax
      data.ajax = false
      App.Store.write( @key, data )

      # load collections
      App.Event.trigger 'loadAssets', data.assets

    # get meta data
    App.Overview.refresh( data.overview, options: { clear: true } )

    App.Overview.unbind('local:rerender')
    App.Overview.bind 'local:rerender', (record) =>
      @log 'notice', 'rerender...', record
      @render(data)

    App.Overview.unbind('local:refetch')
    App.Overview.bind 'local:refetch', (record) =>
      @log 'notice', 'refetch...', record
      @fetch()

    @render( data )

  render: (data) ->
    return if !data
    return if !data.ticket_ids
    return if !data.overview

    @overview      = data.overview
    @tickets_count = data.tickets_count
    @ticket_ids    = data.ticket_ids
    # FIXME 10
    pages_total =  parseInt( ( @tickets_count / 10 ) + 0.99999 ) || 1
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

    shown_all_attributes = @ticketTableAttributes( App.Overview.find(@overview.id).view.d )
    new App.ControllerTable(
      el:                html.find('.table-overview'),
      overview_extended: shown_all_attributes,
      model:             App.Ticket,
      objects:           @tickets_in_table,
      checkbox:          false,
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
    new Settings(
      overview: App.Overview.find(@overview.id)
    )

  page: (e) =>
    e.preventDefault()
    id = $(e.target).data('id')
    @start_page = id
    @fetch()

class Settings extends App.ControllerModal
  constructor: ->
    super
    @render()

  render: ->

    @html App.view('dashboard/ticket_settings')(
      overview: @overview,
    )
    @configure_attributes_article = [
#      { name: 'from',                     display: 'From',     tag: 'input',    type: 'text', limit: 100, null: false, class: 'span8',  },
#      { name: 'to',                       display: 'To',          tag: 'input',    type: 'text', limit: 100, null: true, class: 'span7', item_class: 'hide' },
#      { name: 'ticket_article_type_id',   display: 'Type',        tag: 'select',   multiple: false, null: true, relation: 'TicketArticleType', default: '9', class: 'medium', item_class: 'pull-left' },
#      { name: 'internal',                 display: 'Visibility',  tag: 'radio',  default: false,  null: true, options: { true: 'internal', false: 'public' }, class: 'medium', item_class: 'pull-left' },
      {
        name:     'per_page',
        display:  'Items per page',
        tag:      'select',
        multiple: false,
        null:     false,
#        default: @overview.view.d.per_page,
        options: {
          5: 5,
          10: 10,
          15: 15,
          20: 20,
        },
        class: 'medium',
#        item_class: 'pull-left',
      },
      { 
        name:    'attributes',
        display: 'Attributes',
        tag:     'checkbox',
        default: @overview.view.d,
        null:    false,
        translate:  true
        options: {
          number:                 'Number'
          title:                  'Title'
          customer:               'Customer'
          ticket_state:           'State'
          ticket_priority:        'Priority'
          group:                  'Group'
          owner:                  'Owner'
          created_at:             'Age'
          last_contact:           'Last Contact'
          last_contact_agent:     'Last Contact Agent'
          last_contact_customer:  'Last Contact Customer'
          first_response:         'First Response'
          close_time:             'Close Time'
          escalation_time:        'Escalation in'
          article_count:          'Article Count'
        },
        class:      'medium',
#        item_class: 'pull-left',
      },
      { 
        name:    'order_by',
        display: 'Order',
        tag:     'select',
        default: @overview.order.by,
        null:    false,
        translate:  true
        options: {
          number:                 'Number'
          title:                  'Title'
          customer:               'Customer'
          ticket_state:           'State'
          ticket_priority:        'Priority'
          group:                  'Group'
          owner:                  'Owner'
          created_at:             'Age'
          last_contact:           'Last Contact'
          last_contact_agent:     'Last Contact Agent'
          last_contact_customer:  'Last Contact Customer'
          first_response:         'First Response'
          close_time:             'Close Time'
          escalation_time:        'Escalation in'
          article_count:          'Article Count'
        },
        class:      'medium',
      },
      { 
        name:    'order_by_direction',
        display: 'Direction',
        tag:     'select',
        default: @overview.order.direction,
        null:    false,
        translate: true
        options: {
          ASC:   'up',
          DESC:  'down',
        },
        class:      'medium',
      },
    ]

    new App.ControllerForm(
      el: @el.find('#form-setting'),
      model: { configure_attributes: @configure_attributes_article },
      autofocus: false,
    )

    @modalShow()

  submit: (e) =>
    e.preventDefault()
    params = @formParam(e.target)

    # check if refetch is needed
    @reload_needed = 0
    if @overview.view['d']['per_page'] isnt params['per_page']
      @overview.view['d']['per_page'] = params['per_page']
      @reload_needed = 1

    if @overview.order['by'] isnt params['order_by']
      @overview.order['by'] = params['order_by']
      @reload_needed = 1

    if @overview.order['direction'] isnt params['order_by_direction']
      @overview.order['direction'] = params['order_by_direction']
      @reload_needed = 1

    @overview.view['d'] = params['attributes']

    @overview.save(
      success: =>
        if @reload_needed
          @overview.trigger('local:refetch')
        else
          @overview.trigger('local:rerender')
    )

    @modalHide()
