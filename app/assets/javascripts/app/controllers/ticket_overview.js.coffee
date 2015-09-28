class App.TicketOverview extends App.Controller
  constructor: ->
    super

    @render()

  render: ->
    @html App.view('ticket_overview')()

    @navBarController = new Navbar(
      el:   @el.find('.sidebar')
      view: @view
    )

    @contentController = new Table(
      el:   @el.find('.main')
      view: @view
    )

  active: (state) =>
    @activeState = state

  isActive: =>
    @activeState

  url: =>
    '#ticket/view/' + @view

  show: (params) =>

    # highlight navbar
    @navupdate '#ticket/view'

    # redirect to last overview if we got called in first level
    @view = params['view']
    if !@view && @viewLast
      @navigate "ticket/view/#{@viewLast}", true
      return

    # build nav bar
    if @navBarController
      @navBarController.update(
        view:        @view
        activeState: true
      )

    # do not rerender overview if current overview is requested again
    return if @viewLast is @view

    # remember last view
    @viewLast = @view

    # build content
    if @contentController
      @contentController.update(
        view: @view
      )

  hide: =>
    if @navBarController
      @navBarController.active(false)

  changed: ->
    false

  release: ->
    # no

  overview: (overview_id) =>
    return if !@contentController
    @contentController.meta(overview_id)

class Table extends App.Controller
  events:
    'click [data-type=settings]': 'settings'
    'click [data-type=viewmode]': 'viewmode'

  constructor: ->
    super

    @cache = {}

    # rebuild ticket overview data
    @bind 'ticket_overview_rebuild', (data) =>
      #console.log('EVENT ticket_overview_rebuild', @view, data.view)

      # remeber bulk attributes
      @bulk = data.bulk

      # fill cache
      @cache[data.view] = data

      # check if current view is updated
      if @view is data.view
        @render()

    # force fetch ticket overview
    @bind 'ticket_overview_fetch_force', =>
      @fetch()

    # force fetch ticket overview
    @bind 'ticket_overview_local', =>
      @render(true)

    # rerender view, e. g. on langauge change
    @bind 'ui:rerender', =>
      return if !@authenticate(true)
      @render()

  update: (params) =>
    for key, value of params
      @[key] = value

    @view_mode = localStorage.getItem( "mode:#{@view}" ) || 's'
    @log 'notice', 'view:', @view, @view_mode

    return if !@view

    # fetch initial data
    if !@cache || !@cache[@view]
      @fetch()
    else
      @render()

  fetch: =>

    # init fetch via ajax, all other updates on time via websockets
    @ajax(
      id:   'ticket_overview_' + @view + '_' + @view_mode
      type: 'GET'
      url:  @apiPath + '/ticket_overviews'
      data:
        view:      @view
        view_mode: @view_mode
      processData: true
      success: (data) =>
        if data.assets
          App.Collection.loadAssets( data.assets )

        # remeber bulk attributes
        @bulk = data.bulk

        @cache[data.view] = data
        @render()
      )

  meta: (overview_id) =>
    return if !@cache

    # find requested overview data
    for url, data of @cache
      if data.overview.id is overview_id
        return data
    false

  render: (overview_changed = false) =>
    #console.log('RENDER', @cache, @view)
    return if !@cache
    return if !@cache[@view]

    # use cache
    overview      = @cache[@view].overview
    tickets_count = @cache[@view].tickets_count
    ticket_ids    = @cache[@view].ticket_ids

    # use cache if no local change
    if !overview_changed
      App.Overview.refresh( overview, { clear: true } )

    # get ticket list
    ticket_list_show = []
    for ticket_id in ticket_ids
      ticket_list_show.push App.Ticket.fullLocal( ticket_id )

    # if customer and no ticket exists, show the following message only
    if !ticket_list_show[0] && @isRole('Customer')
      @html App.view('customer_not_ticket_exists')()
      return

    @selected = @bulkGetSelected()

    # set page title
    @overview = App.Overview.find( overview.id )

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

    @html html

    # create table/overview
    table = ''
    if @view_mode is 'm'
      table = App.view('agent_ticket_view/detail')(
        overview: @overview
        objects:  ticket_list_show
        checkbox: checkbox
      )
      table = $(table)
      table.delegate('[name="bulk_all"]', 'click', (e) ->
        console.log('OOOO',  $(e.target).attr('checked') )
        if $(e.target).attr('checked')
          $(e.target).closest('table').find('[name="bulk"]').attr('checked', true)
        else
          $(e.target).closest('table').find('[name="bulk"]').attr('checked', false)
      )
      @el.find('.table-overview').append(table)
    else
      openTicket = (id,e) =>

        # open ticket via task manager to provide task with overview info
        ticket = App.Ticket.fullLocal(id)
        App.TaskManager.execute(
          key:        'Ticket-' + ticket.id
          controller: 'TicketZoom'
          params:
            ticket_id:   ticket.id
            overview_id: @overview.id
          show:       true
        )
        @navigate ticket.uiUrl()
      callbackTicketTitleAdd = (value, object, attribute, attributes, refObject) ->
        attribute.title = object.title
        value
      callbackLinkToTicket = (value, object, attribute, attributes, refObject) ->
        attribute.link = object.uiUrl()
        value
      callbackUserPopover = (value, object, attribute, attributes, refObject) ->
        attribute.class = 'user-popover'
        attribute.data =
          id: refObject.id
        value
      callbackOrganizationPopover = (value, object, attribute, attributes, refObject) ->
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
        el:           @$('.table-overview')
        model:        App.Ticket
        objects:      ticket_list_show
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
    @el.find('.table-overview').delegate('[name="bulk"]', 'click', (e) ->
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


  viewmode: (e) =>
    e.preventDefault()
    @view_mode = $(e.target).data('mode')
    localStorage.setItem( "mode:#{@view}", @view_mode )
    @fetch()
    #@render()

  articleTypeFilter = (items) ->
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
    @el.find('.table-overview').find('[name="bulk"]').each( (index, element) ->
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

            # fetch overview data again
            App.Event.trigger('ticket_overview_fetch_force')
      )
    )
    @el.find('.table-overview').find('[name="bulk"]:checked').prop('checked', false)
    App.Event.trigger 'notify', {
      type: 'success'
      msg: App.i18n.translateContent('Bulk-Action executed!')
    }

  settings: (e) =>
    e.preventDefault()
    new App.OverviewSettings(
      overview_id: @overview.id
      view_mode:   @view_mode
      container:   @el.closest('.content')
    )

class App.OverviewSettings extends App.ControllerModal
  constructor: ->
    super
    @overview = App.Overview.find(@overview_id)

    @configure_attributes_article = []
    if @view_mode is 'd'
      @configure_attributes_article.push({
        name:     'view::per_page'
        display:  'Items per page'
        tag:      'select'
        multiple: false
        null:     false
        default: @overview.view.per_page
        options: {
          5: ' 5'
          10: '10'
          15: '15'
          20: '20'
          25: '25'
        },
      })
    attributeOptions = {}
    attributeOptionsArray = []
    configure_attributes = App.Ticket.configure_attributes
    for row, attribute of App.Ticket.attributesGet()
      configure_attributes.push attribute
    for row in configure_attributes

      # ignore passwords
      if row.type isnt 'password'
        name = row.name

        # get correct data name
        if row.name.substr(row.name.length-4,4) is '_ids'
          name = row.name.substr(0, row.name.length-4)
        else if row.name.substr(row.name.length-3,3) is '_id'
          name = row.name.substr(0, row.name.length-3)

        if !attributeOptions[ name ]
          attributeOptions[ name ] = row.display
          attributeOptionsArray.push(
            {
              value:  name
              name:   row.display
            }
          )
    @configure_attributes_article.push({
      name:    "view::#{@view_mode}"
      display: 'Attributes'
      tag:     'checkbox'
      default: @overview.view[@view_mode]
      null:    false
      translate: true
      sortBy: null
      options: attributeOptionsArray
    },
    {
      name:    'order::by'
      display: 'Order'
      tag:     'select'
      default: @overview.order.by
      null:    false
      translate: true
      sortBy: null
      options: attributeOptionsArray
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
    @reload_needed = false
    if @overview.order.by isnt params.order.by
      @overview.order.by = params.order.by
      @reload_needed = true

    if @overview.order.direction isnt params.order.direction
      @overview.order.direction = params.order.direction
      @reload_needed = true

    for key, value of params.view
      @overview.view[key] = value

    @overview.group_by = params.group_by

    @overview.save(
      done: =>

        # fetch overview data again
        if @reload_needed
          App.Event.trigger('ticket_overview_fetch_force')
        else
          App.Event.trigger('ticket_overview_local')

        # hide modal
        @hide()
    )

class Navbar extends App.Controller
  constructor: ->
    super

    # rebuild ticket overview data
    @bind 'ticket_overview_index', (data) =>
      #console.log('EVENT ticket_overview_index')
      @cache = data
      @update()


    # force fetch ticket overview
    @bind 'ticket_overview_fetch_force', =>
      @fetch()

    # rerender view, e. g. on langauge change
    @bind 'ui:rerender', =>
      @render()

    # init fetch via ajax
    ajaxInit = =>

      # ignore if already pushed via websockets
      return if @cache
      @fetch()

    @delay( ajaxInit, 5000 )

  fetch: =>
    #console.log('AJAX CALLL')
    # init fetch via ajax, all other updates on time via websockets
    @ajax(
      id:    'ticket_overviews',
      type:  'GET',
      url:   @apiPath + '/ticket_overviews',
      processData: true,
      success: (data) =>
        @cache = data
        @update()
      )

  active: (state) =>
    @activeState = state

  update: (params = {}) ->
    for key, value of params
      @[key] = value
    @render()

    if @activeState
      meta =
        title: ''
      if @cache
        for item in @cache
          if item.link is @view
            meta.title = item.name
      @title meta.title, true

  render: =>
    #console.log('RENDER NAV')
    return if !@cache
    data = _.clone(@cache)

    # redirect to first view
    if @activeState && !@view && !_.isEmpty(data)
      view = data[0].link
      #console.log('REDIRECT', "ticket/view/#{view}")
      @navigate "ticket/view/#{view}", true
      return

    # add new views
    for item in data
      item.target = '#ticket/view/' + item.link
      if item.link is @view
        item.active = true
        activeOverview = item
      else
        item.active = false

    @html App.view('agent_ticket_view/navbar')(
      items: data
    )

class TicketOverviewRouter extends App.ControllerPermanent
  constructor: (params) ->
    super

    # check authentication
    return if !@authenticate()

    # cleanup params
    clean_params =
      view: params.view

    App.TaskManager.execute(
      key:        'TicketOverview'
      controller: 'TicketOverview'
      params:     clean_params
      show:       true
      persistent: true
    )

App.Config.set( 'ticket/view', TicketOverviewRouter, 'Routes' )
App.Config.set( 'ticket/view/:view', TicketOverviewRouter, 'Routes' )
App.Config.set( 'TicketOverview', { controller: 'TicketOverview', authentication: true }, 'permanentTask' )
App.Config.set( 'TicketOverview', { prio: 1000, parent: '', name: 'Overviews', target: '#ticket/view', role: ['Agent', 'Customer'], class: 'overviews' }, 'NavBar' )
