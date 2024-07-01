class App.TicketOverviewTable extends App.Controller
  @extend App.PopoverProvidable
  @registerPopovers 'Organization', 'User'

  events:
    'click [data-type=settings]': 'settings'
    'click [data-type=viewmode]': 'viewmode'

  constructor: ->
    super

    if @view
      @bindId = App.OverviewListCollection.bind(@view, @updateTable)

    # rerender view, e. g. on langauge change
    @controllerBind('ui:rerender', =>
      return if !@authenticateCheck()
      return if !@view
      @render(App.OverviewListCollection.get(@view))
    )

  show: =>
    if @table
      @table.show()

  hide: =>
    if @table
      @table.hide()

  release: =>
    if @bindId
      App.OverviewListCollection.unbind(@bindId)

  update: (params) =>
    for key, value of params
      @[key] = value

    return if !@view

    if @view
      if @bindId
        App.OverviewListCollection.unbind(@bindId)
      @bindId = App.OverviewListCollection.bind(@view, @updateTable)

  updateTable: (data) =>
    if !@table
      @render(data)
      return

    # use cache
    overview = data.overview
    tickets  = data.tickets

    return if !overview && !tickets

    # get ticket list
    ticketListShow = []
    for ticket in tickets
      ticketListShow.push App.Ticket.fullLocal(ticket.id)
    @overview = App.Overview.find(overview.id)

    @removePopovers()

    @table.update(
      overviewAttributes: @convertOverviewAttributesToArray(@overview.view.s)
      objects:            ticketListShow
      groupBy:            @overview.group_by
      groupDirection:     @overview.group_direction
      orderBy:            @overview.order.by
      orderDirection:     @overview.order.direction
    )

    @renderPopovers(doNotBind: true)

  render: (data) =>
    return if !data

    # use cache
    overview = data.overview
    tickets  = data.tickets

    return if !overview && !tickets

    @view_mode = App.LocalStorage.get("mode:#{@view}", @Session.get('id')) || 's'

    App.WebSocket.send(event:'ticket_overview_select', data: { view: @view })

    # get ticket list
    ticketListShow = []
    for ticket in tickets
      ticketListShow.push App.Ticket.fullLocal(ticket.id)

    # if customer and no ticket exists, show the following message only
    return if @renderCustomerNotTicketExistIfNeeded(ticketListShow)

    # set page title
    @overview = App.Overview.find(overview.id)

    # render init page
    checkbox = false
    edit     = false
    if @permissionCheck('admin.overview')
      edit = true
    if @permissionCheck('ticket.agent')
      checkbox = true
    view_modes = []
    if @permissionCheck('ticket.agent')
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
    html = App.view('agent_ticket_view/content')(
      overview:   @overview
      view_modes: view_modes
      edit:       edit
    )
    html = $(html)

    @html html

    # create table/overview
    table = ''
    if @view_mode is 'm'
      table = App.view('agent_ticket_view/detail')(
        overview: @overview
        objects:  ticketListShow
        checkbox: checkbox
      )
      table = $(table)
      table.on('change', '[name="bulk_all"]', (e) ->
        if $(e.currentTarget).prop('checked')
          $(e.currentTarget).closest('table').find('[name="bulk"]').prop('checked', true)
        else
          $(e.currentTarget).closest('table').find('[name="bulk"]').prop('checked', false)
      )
      @$('.table-overview').append(table)
    else
      openTicket = (id,e) =>

        # open ticket via task manager to provide task with overview info
        ticket = App.Ticket.findNative(id)
        return if !ticket

        App.TaskManager.execute(
          key:        "Ticket-#{ticket.id}"
          controller: 'TicketZoom'
          params:
            ticket_id:   ticket.id
            overview_id: @overview.id
          show:       true
        )
        @navigate ticket.uiUrl()

      callbackTicketTitleAdd = (value, object, attribute, attributes) ->
        attribute.title = object.title
        value

      callbackLinkToTicket = (value, object, attribute, attributes) ->
        attribute.link = object.uiUrl()
        value

      callbackUserPopover = (value, object, attribute, attributes) ->
        return value if !object
        refObjectId = undefined
        if attribute.name is 'customer_id'
          refObjectId = object.customer_id
        if attribute.name is 'owner_id'
          refObjectId = object.owner_id
        return value if !refObjectId
        attribute.class = 'user-popover'
        attribute.data =
          id: refObjectId
        value

      callbackOrganizationPopover = (value, object, attribute, attributes) ->
        return value if !object
        return value if !object.organization_id
        attribute.class = 'organization-popover'
        attribute.data =
          id: object.organization_id
        value

      callbackCheckbox = (id, checked, e) =>
        if @shouldShowBulkForm()
          @bulkForm.render()
          @bulkForm.show()
        else
          @bulkForm.hide()

        if @lastChecked && e.shiftKey
          # check items in a row
          currentItem = $(e.currentTarget).parents('.item')
          lastCheckedItem = $(@lastChecked).parents('.item')
          items = currentItem.parent().children()

          if currentItem.index() > lastCheckedItem.index()
            # current item is below last checked item
            startId = lastCheckedItem.index()
            endId = currentItem.index()
          else
            # current item is above last checked item
            startId = currentItem.index()
            endId = lastCheckedItem.index()

          items.slice(startId+1, endId).find('[name="bulk"]').prop('checked', (-> !@checked))

        @lastChecked = e.currentTarget
        @bulkForm.updateTicketIdsBulkForm(e)

      callbackIconHeader = (headers) ->
        attribute =
          name:         'icon'
          display:      ''
          parentClass:  'noTruncate'
          translation:  false
          width:        '28px'
          displayWidth: 28
          unresizable:  true
        headers.unshift(0)
        headers[0] = attribute
        headers

      callbackIcon = (value, object, attribute, header) ->
        value = ' '
        attribute.class = object.iconClass()
        attribute.link  = ''
        attribute.title = object.iconTitle()
        value

      callbackPriority = (value, object, attribute, header) ->
        value = ' '

        if object.priority
          attribute.title = object.priority()
        else
          attribute.title = App.i18n.translateInline(App.TicketPriority.findNative(@priority_id)?.displayName())
        value = object.priorityIcon()

      callbackIconPriorityHeader = (headers) ->
        attribute =
          name:         'icon_priority'
          display:      ''
          translation:  false
          width:        '24px'
          displayWidth: 24
          unresizable:  true
        headers.unshift(0)
        headers[0] = attribute
        headers

      callbackIconPriority = (value, object, attribute, header) ->
        value = ' '
        priority = App.TicketPriority.findNative(object.priority_id)
        attribute.title = App.i18n.translateInline(priority?.name)
        value = object.priorityIcon()

      callbackHeader = [ callbackIconHeader ]
      callbackAttributes =
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

      if App.Config.get('ui_ticket_overview_priority_icon') == true
        callbackHeader = [ callbackIconHeader, callbackIconPriorityHeader ]
        callbackAttributes.icon_priority = [ callbackIconPriority ]

      tableArguments =
        tableId:        "ticket_overview_#{@overview.id}"
        overview:       @convertOverviewAttributesToArray(@overview.view.s)
        el:             @$('.table-overview')
        model:          App.Ticket
        objects:        ticketListShow
        checkbox:       checkbox
        groupBy:        @overview.group_by
        groupDirection: @overview.group_direction
        orderBy:        @overview.order.by
        orderDirection: @overview.order.direction
        class:          'table--light'
        bindRow:
          events:
            'click': openTicket
        #bindCol:
        #  customer_id:
        #    events:
        #      'mouseover': popOver
        callbackHeader: callbackHeader
        callbackAttributes: callbackAttributes
        autoAlignLastColumn: true
        bindCheckbox:
          events:
            'click': callbackCheckbox
          select_all: callbackCheckbox

      # remember elWidth even if table is not shown but rerendered
      if @el.width() != 0
        @elWidth = @el.width()
      if @elWidth
        tableArguments.availableWidth = @elWidth

      @table = new App.ControllerTable(tableArguments)

    @renderPopovers(doNotBind: true)

    @bulkForm.releaseController() if @bulkForm
    @bulkForm = new App.TicketBulkForm(
      el:           @el.find('.bulkAction')
      holder:       @el
      view:         @view
      batchSuccess: =>
        @render()
    )

    # start bulk action observ
    localElement = @$('.table-overview')
    if localElement.find('input[name="bulk"]:checked').length isnt 0
      @bulkForm.show()

    # show/hide bulk action
    localElement.on('change', 'input[name="bulk"], input[name="bulk_all"]', (e) =>
      if @shouldShowBulkForm()
        @bulkForm.show()
      else
        @bulkForm.hide()
        @bulkForm.reset()
    )

    # deselect bulk_all if one item is uncheck observ
    localElement.on('change', '[name="bulk"]', (e) ->
      bulkAll = localElement.find('[name="bulk_all"]')
      checkedCount = localElement.find('input[name="bulk"]:checked').length
      checkboxCount = localElement.find('input[name="bulk"]').length
      if checkedCount is 0
        bulkAll.prop('indeterminate', false)
        bulkAll.prop('checked', false)
      else
        if checkedCount is checkboxCount
          bulkAll.prop('indeterminate', false)
          bulkAll.prop('checked', true)
        else
          bulkAll.prop('checked', false)
          bulkAll.prop('indeterminate', true)
    )

  convertOverviewAttributesToArray: (overviewAttributes) ->
    # Ensure that the given attributes for the overview is an array,
    #   otherwise some data might not be displayed.
    # For more details, see https://github.com/zammad/zammad/issues/3943.
    if !Array.isArray(overviewAttributes)
      overviewAttributes = [overviewAttributes]

    overviewAttributes

  renderCustomerNotTicketExistIfNeeded: (ticketListShow) =>
    user = App.User.current()
    @stopListening user, 'refresh'

    return if ticketListShow[0] || @permissionCheck('ticket.agent')

    tickets_count = user.lifetimeCustomerTicketsCount()
    @html App.view('customer_not_ticket_exists')(has_any_tickets: tickets_count > 0, is_allowed_to_create_ticket: @Config.get('customer_ticket_create'))

    if tickets_count == 0
      @listenTo user, 'refresh', =>
        return if tickets_count == user.lifetimeCustomerTicketsCount()

        @renderCustomerNotTicketExistIfNeeded([])

    return true

  shouldShowBulkForm: =>
    items = @$('table').find('input[name="bulk"]:checked')
    return false if items.length == 0

    ticket_ids        = _.map(items, (el) -> $(el).val() )
    ticket_group_ids  = _.map(App.Ticket.findAll(ticket_ids), (ticket) -> ticket.group_id)
    ticket_group_ids  = _.uniq(ticket_group_ids)
    allowed_group_ids = App.User.find(@Session.get('id')).allGroupIds('change')
    allowed_group_ids = _.map(allowed_group_ids, (id_string) -> parseInt(id_string, 10) )
    _.every(ticket_group_ids, (id) -> id in allowed_group_ids)

  viewmode: (e) =>
    e.preventDefault()
    @view_mode = $(e.target).data('mode')
    App.LocalStorage.set("mode:#{@view}", @view_mode, @Session.get('id'))
    @fetch()
    #@render()

  settings: (e) =>
    e.preventDefault()
    @keyboardOff()

    new App.TicketOverviewSettings(
      overview_id:     @overview.id
      view_mode:       @view_mode
      container:       @el.closest('.content')
      onCloseCallback: @keyboardOn
    )
