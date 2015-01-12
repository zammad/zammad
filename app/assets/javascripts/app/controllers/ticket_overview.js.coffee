class Index extends App.Controller
  constructor: ->
    super
    @render()

  render: ->

    @html App.view('agent_ticket_view')()

    # redirect to first view
    if !@view
      cache = App.Store.get( 'navupdate_ticket_overview' )
      if cache && !_.isEmpty( cache )
        view = cache[0].link
        @navigate "ticket/view/#{view}"
        return

    new Navbar(
      el:   @el.find('.sidebar')
      view: @view
    )

    if @view
      new Table(
        el:   @el.find('.main')
        view: @view
      )

class Table extends App.ControllerContent
  events:
    'click [data-type=edit]':      'zoom'
    'click [data-type=settings]':  'settings'
    'click [data-type=viewmode]':  'viewmode'
    'click [data-type=page]':      'page'

  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    @view_mode = localStorage.getItem( "mode:#{@view}" ) || 's'
    @log 'notice', 'view:', @view, @view_mode

    # set title
    @title ''
    @navupdate '#ticket/view'

    @meta = {}
    @bulk = {}

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
      @load(cache)

    # init fetch via ajax, all other updates on time via websockets
    else
      @ajax(
        id:   'ticket_overview_' + @key
        type: 'GET'
        url:  @apiPath + '/ticket_overviews'
        data:
          view:      @view
          view_mode: @view_mode
        processData: true
        success: (data) =>
          data.ajax = true
          @load(data)
        )

  load: (data) =>
    return if !data
    return if !data.ticket_ids
    return if !data.overview

    @overview      = data.overview
    @tickets_count = data.tickets_count
    @ticket_ids    = data.ticket_ids

    if data.ajax
      data.ajax = false
      App.Store.write( @key, data )

      # load assets
      App.Collection.loadAssets( data.assets )

    # get meta data
    @overview = data.overview
    App.Overview.refresh( @overview, { clear: true } )

    App.Overview.unbind('local:rerender')
    App.Overview.bind 'local:rerender', (record) =>
      @log 'notice', 'rerender...', record
      @render()

    App.Overview.unbind('local:refetch')
    App.Overview.bind 'local:refetch', (record) =>
      @log 'notice', 'refetch...', record
      @fetch(true)

    @ticket_list_show = []
    for ticket_id in @ticket_ids
      @ticket_list_show.push App.Ticket.fullLocal( ticket_id )

    # remeber bulk attributes
    @bulk = data.bulk

    # set cache
#    App.Store.write( @key, data )

    # render page
    @render()

  render: ->

    # if customer and no ticket exists, show the following message only
    if !@ticket_list_show[0] && @isRole('Customer')
      @html App.view('customer_not_ticket_exists')()
      return

    @selected = @bulkGetSelected()

    # set page title
    @overview = App.Overview.find( @overview.id )
    @title @overview.name

    # render init page
    checkbox = true
    edit     = true
    if @isRole('Customer')
      checkbox = false
      edit     = false
    view_modes = [
      {
        name:  'S'
        type:  's'
        class: 'active' if @view_mode is 's'
      },
      {
        name:  'M'
        type:  'm'
        class: 'active' if @view_mode is 'm'
      }
    ]
    if @isRole('Customer')
      view_modes = []
    html = App.view('agent_ticket_view/content')(
      overview:   @overview
      view_modes: view_modes
      checkbox:   checkbox
      edit:       edit
    )
    html = $(html)
#    html.find('li').removeClass('active')
#    html.find("[data-id=\"#{@start_page}\"]").parents('li').addClass('active')

    @html html

    # create table/overview
    table = ''
    if @view_mode is 'm'
      table = App.view('agent_ticket_view/detail')(
        overview: @overview
        objects:  @ticket_list_show
        checkbox: checkbox
      )
      table = $(table)
      table.delegate('[name="bulk_all"]', 'click', (e) ->
        if $(e.target).attr('checked')
          $(e.target).parents().find('[name="bulk"]').attr('checked', true)
        else
          $(e.target).parents().find('[name="bulk"]').attr('checked', false)
      )
      @el.find('.table-overview').append(table)
    else
      openTicket = (id,e) =>
        ticket = App.Ticket.fullLocal(id)
        @navigate ticket.uiUrl()
      callbackTicketTitleAdd = (value, object, attribute, attributes, refObject) =>
        attribute.title = object.title
        value
      callbackLinkToTicket = (value, object, attribute, attributes, refObject) =>
        attribute.link = object.uiUrl()
        value
      callbackUserPopover = (value, object, attribute, attributes, refObject) =>
        attribute.class = 'user-popover'
        attribute.data =
          id: refObject.id
        value
      callbackOrganizationPopover = (value, object, attribute, attributes, refObject) =>
        attribute.class = 'organization-popover'
        attribute.data =
          id: refObject.id
        value
      callbackCheckbox = (id, checked, e) =>
        if @el.find('table').find('input[name="bulk"]:checked').length == 0
          @el.find('.bulkAction').addClass('hide')
        else
          @el.find('.bulkAction').removeClass('hide')
      callbackIconHeader = (header) ->
        attribute =
          name:       'icon'
          display:    ''
          translation: false
          style:      'width: 28px'
        header.unshift(0)
        header[0] = attribute
        header
      callbackIcon = (value, object, attribute, header, refObject) ->
        value = ' '
        attribute.class  = object.icon()
        attribute.link   = ''
        attribute.title  = App.i18n.translateInline( object.iconTitle() )
        value

      new App.ControllerTable(
        overview:     @overview.view.s
        el:           @el.find('.table-overview')
        model:        App.Ticket
        objects:      @ticket_list_show
        checkbox:     checkbox
        groupBy:      @overview.group_by
        bindRow:
          events:
            'click':  openTicket
        #bindCol:
        #  customer_id:
        #    events:
        #      'mouseover': popOver
        callbackHeader:    callbackIconHeader
        callbackAttributes:
          icon:
            [ callbackIcon ]
          customer_id:
            [ callbackUserPopover ]
          organization_id:
            [ callbackOrganizationPopover ]
          owner_id:
            [ callbackUserPopover ]
          title:
            [ callbackLinkToTicket, callbackTicketTitleAdd ]
          number:
            [ callbackLinkToTicket, callbackTicketTitleAdd ]
        bindCheckbox:
          events:
            'click':  callbackCheckbox
      )

    @bulkSetSelected( @selected )

    # start user popups
    @userPopups()

    # start organization popups
    @organizationPopups()

    # show frontend times
    @frontendTimeUpdate()

    # start bulk action observ
    @el.find('.bulkAction').append( @bulk_form() )
    if @el.find('.table-overview').find('input[name="bulk"]:checked').length isnt 0
        @el.find('.bulkAction').removeClass('hide')

    # show/hide bulk action
    @el.find('.table-overview').delegate('input[name="bulk"], input[name="bulk_all"]', 'click', (e) =>
      console.log('YES')
      if @el.find('.table-overview').find('input[name="bulk"]:checked').length == 0

        # hide
        @el.find('.bulkAction').addClass('hide')

        @resetBulkForm()
      else

        # show
        @el.find('.bulkAction').removeClass('hide')
    )

    # deselect bulk_all if one item is uncheck observ
    @el.find('.table-overview').delegate('[name="bulk"]', 'click', (e) =>
      if !$(e.target).attr('checked')
        $(e.target).parents().find('[name="bulk_all"]').attr('checked', false)
    )

    # bind bulk form buttons
    @$('.js-confirm').click(@bulkFormConfirm)
    @$('.js-cancel').click(@resetBulkForm)

  bulkFormConfirm: =>
    @$('.js-action-step').addClass('hide')
    @$('.js-confirm-step').removeClass('hide')

    # need a delay because of the click event
    setTimeout ( => @$('.textarea.form-group textarea').focus() ), 0

  resetBulkForm: =>
    @$('.js-action-step').removeClass('hide')
    @$('.js-confirm-step').addClass('hide')

  page: (e) =>
    e.preventDefault()
    id = $(e.target).data('id')
    @start_page = id
    @fetch()

  viewmode: (e) =>
    e.preventDefault()
    @start_page    = 1
    mode = $(e.target).data('mode')
    @view_mode = mode
    localStorage.setItem( "mode:#{@view}", mode )
    @fetch()
    @render()

  articleTypeFilter = (items) =>
    for item in items
      if item.name is 'note'
        return [item]
    items

  bulk_form: =>
    @configure_attributes_ticket = [
      { name: 'state_id',     display: 'State',    tag: 'select',   multiple: false, null: true, relation: 'TicketState', filter: @bulk, translate: true, nulloption: true, default: '', class: '', item_class: '' },
      { name: 'priority_id',  display: 'Priority', tag: 'select',   multiple: false, null: true, relation: 'TicketPriority', filter: @bulk, translate: true, nulloption: true, default: '', class: '', item_class: '' },
      { name: 'group_id',     display: 'Group',    tag: 'select',   multiple: false, null: true, relation: 'Group', filter: @bulk, nulloption: true, class: '', item_class: ''  },
      { name: 'owner_id',     display: 'Owner',    tag: 'select',   multiple: false, null: true, relation: 'User', filter: @bulk, nulloption: true, class: '', item_class: '' }
    ]

    # render init page
    html = $( App.view('agent_ticket_view/bulk')() )
    new App.ControllerForm(
      el: html.find('#form-ticket-bulk')
      model:
        configure_attributes: @configure_attributes_ticket
        className:            'create'
        labelClass:           'input-group-addon'
      form_data:   @bulk
      noFieldset: true
    )

    new App.ControllerForm(
      el: html.find('#form-ticket-bulk-comment')
      model:
        configure_attributes: [{ name: 'body',         display: 'Comment', tag: 'textarea', rows: 4, null: true, upload: false, item_class: 'flex' }]
        className:            'create'
        labelClass:           'input-group-addon'
      form_data:   @bulk
      noFieldset: true
    )

    @confirm_attributes = [
      { name: 'type_id',      display: 'Type',     tag: 'select',   multiple: false, null: true, relation: 'TicketArticleType', filter: articleTypeFilter, default: '9', translate: true, class: 'medium' }
      { name: 'internal',     display: 'Visibility', tag: 'select', null: true, options: { true: 'internal', false: 'public' }, class: 'medium', item_class: '', default: false }
    ]

    new App.ControllerForm(
      el: html.find('#form-ticket-bulk-typeVisibility')
      model:
        configure_attributes: @confirm_attributes
        className:            'create'
        labelClass:           'input-group-addon'
      form_data:   @bulk
      noFieldset: true
    )

    html.bind('submit', (e) =>
      e.preventDefault()
      @bulk_submit(e)
    )
    return html

  bulkGetSelected: ->
    @ticketIDs = []
    @el.find('.table-overview').find('[name="bulk"]:checked').each( (index, element) =>
      ticket_id = $(element).val()
      @ticketIDs.push ticket_id
    )
    @ticketIDs

  bulkSetSelected: (ticketIDs) ->
    @el.find('.table-overview').find('[name="bulk"]').each( (index, element) =>
      ticket_id = $(element).val()
      for ticket_id_selected in ticketIDs
        if ticket_id_selected is ticket_id
          $(element).attr( 'checked', true )
    )

  bulk_submit: (e) =>
    @bulk_count = @el.find('.table-overview').find('[name="bulk"]:checked').length
    @bulk_count_index = 0
    @el.find('.table-overview').find('[name="bulk"]:checked').each( (index, element) =>
      @log 'notice', '@bulk_count_index', @bulk_count, @bulk_count_index
      ticket_id = $(element).val()
      ticket = App.Ticket.find(ticket_id)
      params = @formParam(e.target)

      # update ticket
      ticket_update = {}
      for item of params
        if params[item] != ''
          ticket_update[item] = params[item]

#      @log 'notice', 'update', params, ticket_update, ticket

      # validate article
      if params['body']
        article = new App.TicketArticle
        params.from      = @Session.get().displayName()
        params.ticket_id = ticket.id
        params.form_id   = @form_id

        sender            = App.TicketArticleSender.findByAttribute( 'name', 'Agent' )
        type              = App.TicketArticleType.find( params['type_id'] )
        params.sender_id  = sender.id

        if !params['internal']
          params['internal'] = false

        @log 'notice', 'update article', params, sender
        article.load(params)
        errors = article.validate()
        if errors
          @log 'error', 'update article', errors
          @formEnable(e)
          return

      ticket.load(ticket_update)
      ticket.save(
        done: (r) =>
          @bulk_count_index++

          # reset form after save
          if article
            article.save(
              fail: (r) =>
                @log 'error', 'update article', r
            )

          # refresh view after all tickets are proceeded
          if @bulk_count_index == @bulk_count

            # rebuild navbar with updated ticket count of overviews
            App.WebSocket.send( event: 'navupdate_ticket_overview' )

            # fetch overview data again
            @fetch()
      )
    )
    @el.find('.table-overview').find('[name="bulk"]:checked').prop('checked', false)
    App.Event.trigger 'notify', {
      type: 'success'
      msg: App.i18n.translateContent('Bulk-Action executed!')
    }

  zoom: (e) =>
    e.preventDefault()
    id = $(e.target).parents('[data-id]').data('id')
    position = $(e.target).parents('[data-position]').data('position')

    # set last overview
    @Config.set('LastOverview', @view )
    @Config.set('LastOverviewPosition', position )
    @Config.set('LastOverviewTotal', @tickets_count )

    @navigate 'ticket/zoom/' + id + '/nav/true'

  settings: (e) =>
    e.preventDefault()
    new App.OverviewSettings(
      overview_id: @overview.id
      view_mode:   @view_mode
    )

class App.OverviewSettings extends App.ControllerModal
  constructor: ->
    super
    @overview = App.Overview.find(@overview_id)

    @configure_attributes_article = []
    if @view_mode is 'd'
      @configure_attributes_article.push({
        name:     'view::per_page',
        display:  'Items per page',
        tag:      'select',
        multiple: false,
        null:     false,
        default: @overview.view.per_page
        options: {
          5: ' 5'
          10: '10'
          15: '15'
          20: '20'
          25: '25'
        },
        class: 'medium',
      })
    @configure_attributes_article.push({
      name:    "view::#{@view_mode}"
      display: 'Attributes'
      tag:     'checkbox'
      default: @overview.view[@view_mode]
      null:    false
      translate: true
      options: [
        {
          value:  'number'
          name:   'Number'
        },
        {
          value:  'title'
          name:   'Title'
        },
        {
          value:  'customer'
          name:   'Customer'
        },
        {
          value:  'organization'
          name:   'Organization'
        },
        {
          value:  'state'
          name:   'State'
        },
        {
          value:  'priority'
          name:   'Priority'
        },
        {
          value:  'group'
          name:   'Group'
        },
        {
          value:  'owner'
          name:   'Owner'
        },
        {
          value:  'created_at'
          name:   'Age'
        },
        {
          value:  'last_contact'
          name:   'Last Contact Time'
        },
        {
          value:  'last_contact_agent'
          name:   'Last Contact Agent Time'
        },
        {
          value:  'last_contact_customer'
          name:   'Last Contact Customer Time'
        },
        {
          value:  'first_response'
          name:   'First Response Time'
        },
        {
          value:  'close_time'
          name:   'Close Time'
        },
        {
          value:  'escalation_time'
          name:   'Escalation Time'
        },
        {
          value:  'pending_time'
          name:   'Pending Reminder Time'
        },
        {
          value:  'article_count'
          name:   'Article Count'
        },
      ]
      class:      'medium'
    },
    {
      name:    'order::by'
      display: 'Order'
      tag:     'select'
      default: @overview.order.by
      null:    false
      translate: true
      options:
        number:                 'Number'
        title:                  'Title'
        customer:               'Customer'
        organization:           'Organization'
        state:                  'State'
        priority:               'Priority'
        group:                  'Group'
        owner:                  'Owner'
        created_at:             'Age'
        last_contact:           'Last Contact'
        last_contact_agent:     'Last Contact Agent'
        last_contact_customer:  'Last Contact Customer'
        first_response:         'First Response'
        close_time:             'Close Time'
        escalation_time:        'Escalation'
        article_count:          'Article Count'
      class:   'medium'
    },
    {
      name:    'order::direction'
      display: 'Direction'
      tag:     'select'
      default: @overview.order.direction
      null:    false
      translate: true
      options:
        ASC:   'up'
        DESC:  'down'
      class:   'medium'
    },
    {
      name:    'group_by'
      display: 'Group by'
      tag:     'select'
      default: @overview.group_by
      null:    true
      nulloption: true
      translate:  true
      options:
        customer:       'Customer'
        organization:   'Organization'
        state:          'State'
        priority:       'Priority'
        group:          'Group'
        owner:          'Owner'
      class:   'medium'
    })

    @head   = App.i18n.translateContent( 'Edit' ) + ': ' + App.i18n.translateContent( @overview.name )
    @close  = true
    @cancel = true
    @button = true
    controller = new App.ControllerForm(
      model:     { configure_attributes: @configure_attributes_article }
      autofocus: false
    )
    @content = controller.form
    @show()

  onSubmit: (e) =>
    e.preventDefault()
    params = @formParam(e.target)

    # check if refetch is needed
    @reload_needed = 0
    if @overview.order.by isnt params.order.by
      @overview.order.by = params.order.by
      @reload_needed = 1

    if @overview.order.direction isnt params.order.direction
      @overview.order.direction = params.order.direction
      @reload_needed = 1

    for key, value of params.view
      @overview.view[key] = value

    @overview.group_by = params.group_by

    @overview.save(
      done: =>
        if @reload_needed
          @overview.trigger('local:refetch')
        else
          @overview.trigger('local:rerender')
    )
    @hide()

class Navbar extends App.Controller
  constructor: ->
    super

    # rebuild ticket overview data
    @bind 'navupdate_ticket_overview', (data) =>
      if !_.isEmpty(data)
        App.Store.write( 'navupdate_ticket_overview', data )
        @render(data)

    cache = App.Store.get( 'navupdate_ticket_overview' )
    if cache
      @render( cache )
    else
      @render( [] )

      # init fetch via ajax, all other updates on time via websockets
      @ajax(
        id:    'ticket_overviews',
        type:  'GET',
        url:   @apiPath + '/ticket_overviews',
        processData: true,
        success: (data) =>
          App.Store.write( 'navupdate_ticket_overview', data )
          @render(data)
        )

  render: (dataOrig) ->

    data = _.clone(dataOrig)

    # redirect to first view
    if !@view && !_.isEmpty(data)
      view = data[0].link
      @navigate "ticket/view/#{view}"
      return

    # add new views
    for item in data
      item.target = '#ticket/view/' + item.link
      if item.link is @view
        item.active = true
      else
        item.active = false

    @html App.view('agent_ticket_view/navbar')(
      items: data
    )


class Router extends App.Controller
  constructor: ->
    super

    # set new key
    @key = 'ticket_overview_' + @view

    # get data
    cache = App.Store.get( @key )
    if cache
      @tickets_count = cache.tickets_count
      @ticket_ids    = cache.ticket_ids
      @redirect()
    else
      @ajax(
        type:       'GET'
        url:        @apiPath + '/ticket_overviews'
        data:
          view:      @view
          array:     true
        processData: true
        success:     @load
      )

  load: (data) =>
    @ticket_ids    = data.ticket_ids
    @tickets_count = data.tickets_count
#    App.Store.write( data )
    @redirect()

  redirect: =>
    @Config.set('LastOverview', @view )
    @position = parseInt( @position )
    @Config.set('LastOverviewPosition', @position )
    @Config.set('LastOverviewTotal', @tickets_count )

    # redirect
    if @direction == 'next'
      if @ticket_ids[ @position ] && @ticket_ids[ @position ]
        position = @position + 1
        @Config.set( 'LastOverviewPosition', position )
        @navigate 'ticket/zoom/' + @ticket_ids[ @position ] + '/nav/true'
      else
        @navigate 'ticket/zoom/' + @ticket_ids[ @position - 1 ] + '/nav/true'
    else
      if @ticket_ids[ @position - 2 ] && @ticket_ids[ @position - 2 ] + '/nav/true'
        position = @position - 1
        @Config.set( 'LastOverviewPosition', position )
        @navigate 'ticket/zoom/' + @ticket_ids[ @position - 2 ] + '/nav/true'
      else
        @navigate 'ticket/zoom/' + @ticket_ids[ @position - 1 ] + '/nav/true'

App.Config.set( 'ticket/view', Index, 'Routes' )
App.Config.set( 'ticket/view/:view', Index, 'Routes' )
#App.Config.set( 'ticket/view/:view/:position/:direction', Router, 'Routes' )

App.Config.set( 'TicketOverview', { prio: 1000, parent: '', name: 'Overviews', target: '#ticket/view', role: ['Agent', 'Customer'], class: 'overviews' }, 'NavBar' )
