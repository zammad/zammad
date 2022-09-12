class App.TicketOverview extends App.Controller
  @extend App.TicketMassUpdatable
  @include App.ValidUsersForTicketSelectionMethods

  className: 'overviews'
  activeFocus: 'nav'

  elements:
    '.main': 'mainContent'

  constructor: ->
    super
    @render()

    load = (data) =>
      App.Collection.loadAssets(data.assets)
      @formMeta = data.form_meta
    @bindId = App.TicketOverviewCollection.bind(load)

  render: ->
    elLocal = $(App.view('ticket_overview/index')())

    @navBarControllerVertical.releaseController() if @navBarControllerVertical
    @navBarControllerVertical = new Navbar(
      el:       elLocal.find('.overview-header')
      view:     @view
      vertical: true
    )

    @navBarController.releaseController() if @navBarController
    @navBarController = new Navbar(
      el:   elLocal.filter('.sidebar')
      view: @view
    )

    @controllerTicketBatch.releaseController() if @controllerTicketBatch
    @controllerTicketBatch = new App.TicketBatch(
      el:           elLocal.filter('.js-batch-overlay')
      parent:       @
      parentEl:     elLocal
      appEl:        @appEl
      batchSuccess: =>
        @render()
    )

    @contentController.releaseController() if @contentController
    @contentController = new Table(
      el:          elLocal.find('.overview-table')
      view:        @view
      keyboardOn:  @keyboardOn
      keyboardOff: @keyboardOff
    )

    @html elLocal

    @$('.main').on('click', =>
      @activeFocus = 'overview'
    )
    @$('.sidebar').on('click', =>
      @activeFocus = 'nav'
    )

    @controllerBind('overview:fetch', =>
      return if !@view
      update = =>
        App.OverviewListCollection.fetch(@view)
      @delay(update, 2800, 'overview:fetch')
    )

  active: (state) =>
    return @shown if state is undefined
    @shown = state

  url: =>
    "#ticket/view/#{@view}"

  show: (params) =>
    @keyboardOn()

    # highlight navbar
    @navupdate '#ticket/view'

    # redirect to last overview if we got called in first level
    @view = params['view']
    if !@view && @viewLast
      @navigate "ticket/view/#{@viewLast}", { hideCurrentLocationFromHistory: true }
      return

    # build nav bar
    if @navBarController
      @navBarController.update(
        view:        @view
        activeState: true
      )

    if @navBarControllerVertical
      @navBarControllerVertical.update(
        view:        @view
        activeState: true
      )

    # do not rerender overview if current overview is requested again
    if @viewLast is @view
      if @contentController
        @contentController.show()
      return

    App.TicketOverviewCollection.fetch()

    # remember last view
    @viewLast = @view

    # build content
    @contentController.releaseController() if @contentController
    @contentController = new Table(
      el:          @$('.overview-table')
      view:        @view
      keyboardOn:  @keyboardOn
      keyboardOff: @keyboardOff
    )

  hide: =>
    @keyboardOff()

    if @navBarController
      @navBarController.active(false)
    if @navBarControllerVertical
      @navBarControllerVertical.active(false)
    if @contentController
      @contentController.hide()

  setPosition: (position) =>
    @$('.main').scrollTop(position)

  currentPosition: =>
    @$('.main').scrollTop()

  changed: ->
    false

  release: =>
    @keyboardOff()
    super
    App.TicketOverviewCollection.unbindById(@bindId)

  keyboardOn: =>
    $(window).off 'keydown.overview_navigation'
    $(window).on 'keydown.overview_navigation', @listNavigate

  keyboardOff: ->
    $(window).off 'keydown.overview_navigation'

  listNavigate: (e) =>

    # ignore if focus is in bulk action
    return if $(e.target).is('textarea, input, select')

    if e.keyCode is 38 # up
      e.preventDefault()
      @nudge(e, -1)
      return
    else if e.keyCode is 40 # down
      e.preventDefault()
      @nudge(e, 1)
      return
    else if e.keyCode is 32 # space
      e.preventDefault()
      if @activeFocus is 'overview'
        @$('.table-overview table tbody tr.is-hover td.js-checkbox-field label input').first().trigger('click')
    else if e.keyCode is 9 # tab
      e.preventDefault()
      if @activeFocus is 'nav'
        @activeFocus = 'overview'
        @nudge(e, 1)
      else
        @activeFocus = 'nav'
    else if e.keyCode is 13 # enter
      if @activeFocus is 'overview'
        location = @$('.table-overview table tbody tr.is-hover a').first().attr('href')
        if location
          @navigate location

  nudge: (e, position) ->

    if @activeFocus is 'overview'
      items = @$('.table-overview table tbody')
      current = items.find('tr.is-hover')

      if !current.length
        items.find('tr').first().addClass('is-hover')
        return

      if position is 1
        next = current.next('tr')
        if next.length
          current.removeClass('is-hover')
          next.addClass('is-hover')
      else
        prev = current.prev('tr')
        if prev.length
          current.removeClass('is-hover')
          prev.addClass('is-hover')

      if next
        @scrollToIfNeeded(next, true)
      if prev
        @scrollToIfNeeded(prev, true)

    else
      # get current
      items = @$('.sidebar')
      current = items.find('li.active')

      if !current.length
        location = items.find('li a').first().attr('href')
        if location
          @navigate location
        return

      if position is 1
        next = current.next('li')
        if next.length
          @navigate next.find('a').attr('href')
      else
        prev = current.prev('li')
        if prev.length
          @navigate prev.find('a').attr('href')

      if next
        @scrollToIfNeeded(next, true)
      if prev
        @scrollToIfNeeded(prev, true)

class Navbar extends App.Controller
  elements:
    '.js-tabsHolder': 'tabsHolder'
    '.js-tabsClone': 'clone'
    '.js-tabClone': 'tabClone'
    '.js-tabs': 'tabs'
    '.js-tab': 'tab'
    '.js-dropdown': 'dropdown'
    '.js-toggle': 'dropdownToggle'
    '.js-dropdownItem': 'dropdownItem'

  events:
    'click .js-tab': 'activate'
    'click .js-dropdownItem': 'navigateTo'
    'hide.bs.dropdown': 'onDropdownHide'
    'show.bs.dropdown': 'onDropdownShow'

  constructor: ->
    super

    @bindId = App.OverviewIndexCollection.bind(@render)

    # rerender view, e. g. on language change
    @controllerBind('ui:rerender', =>
      @render(App.OverviewIndexCollection.get())
    )
    if @vertical
      $(window).on 'resize.navbar', @autoFoldTabs

  navigateTo: (event) ->
    location.hash = $(event.currentTarget).attr('data-target')

  onDropdownShow: =>
    @dropdownToggle.addClass('active')

  onDropdownHide: =>
    @dropdownToggle.removeClass('active')

  activate: (event) =>
    @tab.removeClass('active')
    $(event.currentTarget).addClass('active')

  release: =>
    if @vertical
      $(window).off 'resize.navbar', @autoFoldTabs
    App.OverviewIndexCollection.unbindById(@bindId)

  autoFoldTabs: =>
    items = App.OverviewIndexCollection.get()
    if App.UserOverviewSorting.count()
      items.sort(App.UserOverviewSortingOverview.overviewSort)
    else
      items.sort((a, b) -> a.prio - b.prio)

    @html App.view("agent_ticket_view/navbar#{ if @vertical then '_vertical' }")
      items: items
      isAgent: @permissionCheck('ticket.agent')

    while @clone.width() > @tabsHolder.width()
      @tabClone.not('.hide').last().addClass('hide')
      @tab.not('.hide').last().addClass('hide')
      @dropdownItem.filter('.hide').last().removeClass('hide')

    # if all tabs are visible
    # remove dropdown and dropdown button
    if @dropdownItem.not('.hide').length is 0
      @dropdown.remove()
      @dropdownToggle.remove()

  active: (state) =>
    @activeState = state

  update: (params = {}) ->
    for key, value of params
      @[key] = value
    @render(App.OverviewIndexCollection.get())

  render: (data) =>
    return if !data
    content = @el.closest('.content')
    if _.isArray(data) && _.isEmpty(data)
      content.find('.sidebar').addClass('hide')
      content.find('.main').addClass('hide')
      content.find('.js-error').removeClass('hide')
      @renderScreenError(
        el: @el.closest('.content').find('.js-error')
        detail:     __('Currently no overview is assigned to your roles. Please contact your administrator.')
        objectName: 'Ticket'
      )
      return
    content.find('.sidebar').removeClass('hide')
    content.find('.main').removeClass('hide')
    content.find('.js-error').addClass('hide')

    # do not show vertical navigation if only one tab exists
    if @vertical
      if data && data.length <= 1
        @el.addClass('hidden')
      else
        @el.removeClass('hidden')

    # set page title
    if @activeState && @view && !@vertical
      for item in data
        if item.link is @view
          @title item.name, true

    # send first view info
    if !@view && data && data[0] && data[0].link
      App.WebSocket.send(event:'ticket_overview_select', data: { view: data[0].link })

    # redirect to first view
    if @activeState && !@view && !@vertical
      view = data[0].link
      @navigate "ticket/view/#{view}", { hideCurrentLocationFromHistory: true }
      return

    # add new views
    for item in data
      item.target = "#ticket/view/#{item.link}"
      if item.link is @view
        item.active = true
        activeOverview = item
      else
        item.active = false

    # sort by profile preferences
    if App.UserOverviewSorting.count()
      data.sort(App.UserOverviewSortingOverview.overviewSort)
    else
      data.sort((a, b) -> a.prio - b.prio)

    @html App.view("agent_ticket_view/navbar#{ if @vertical then '_vertical' else '' }")
      items: data

    if @vertical
      @autoFoldTabs()

class Table extends App.Controller
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
      ticketListShow.push App.Ticket.find(ticket.id)
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

    @renderPopovers()

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
      ticketListShow.push App.Ticket.find(ticket.id)

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

    @renderPopovers()

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

    new App.OverviewSettings(
      overview_id:     @overview.id
      view_mode:       @view_mode
      container:       @el.closest('.content')
      onCloseCallback: @keyboardOn
    )

class App.OverviewSettings extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  headPrefix: 'Edit'

  content: =>
    @overview = App.Overview.find(@overview_id)
    @head     = @overview.name

    @configure_attributes_article = []
    if @view_mode is 'd'
      @configure_attributes_article.push({
        name:     'view::per_page'
        display:  __('Items per page')
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

    @configure_attributes_article.push({
      name:      "view::#{@view_mode}"
      display:   __('Attributes')
      tag:       'checkboxTicketAttributes'
      default:   @overview.view[@view_mode]
      null:      false
      translate: true
      sortBy:    null
    },
    {
      name:      'order::by'
      display:   __('Sorting by')
      tag:       'selectTicketAttributes'
      default:   @overview.order.by
      null:      false
      translate: true
      sortBy:    null
    },
    {
      name:      'order::direction'
      display:   __('Sorting order')
      tag:       'select'
      default:   @overview.order.direction
      null:      false
      translate: true
      options:
        ASC:  __('ascending')
        DESC: __('descending')
    },
    {
      name:       'group_by'
      display:    __('Grouping by')
      tag:        'select'
      default:    @overview.group_by
      null:       true
      nulloption: true
      translate:  true
      options:    App.Overview.groupByAttributes()
    },
    {
      name:    'group_direction'
      display: __('Grouping order')
      tag:     'select'
      default: @overview.group_direction
      null:    false
      translate: true
      options:
        ASC:   __('ascending')
        DESC:  __('descending')
    },)

    controller = new App.ControllerForm(
      model:     { configure_attributes: @configure_attributes_article }
      autofocus: false
    )
    controller.form

  onClose: =>
    if @onCloseCallback
      @onCloseCallback()

  onSubmit: (e) =>
    params = @formParam(e.target)

    # check if re-fetch is needed
    @reload_needed = false
    if @overview.order.by isnt params.order.by
      @overview.order.by = params.order.by
      @reload_needed = true

    if @overview.order.direction isnt params.order.direction
      @overview.order.direction = params.order.direction
      @reload_needed = true

    if @overview.group_direction isnt params.group_direction
      @overview.group_direction = params.group_direction
      @reload_needed = true

    for key, value of params.view
      @overview.view[key] = value

    @overview.group_by = params.group_by

    @overview.save(
      done: =>

        # fetch overview data again
        if @reload_needed
          App.OverviewListCollection.fetch(@overview.link)
        else
          App.OverviewIndexCollection.trigger()
          App.OverviewListCollection.trigger(@overview.link)

        # close modal
        @close()
    )

class TicketOverviewRouter extends App.ControllerPermanent
  requiredPermission: ['ticket.agent', 'ticket.customer']

  constructor: (params) ->
    super

    # cleanup params
    clean_params =
      view: params.view
      appEl: params.appEl

    App.TaskManager.execute(
      key:        'TicketOverview'
      controller: 'TicketOverview'
      params:     clean_params
      show:       true
      persistent: true
    )

App.Config.set('ticket/view', TicketOverviewRouter, 'Routes')
App.Config.set('ticket/view/:view', TicketOverviewRouter, 'Routes')
App.Config.set('TicketOverview', { controller: 'TicketOverview', permission: ['ticket.agent', 'ticket.customer'] }, 'permanentTask')
App.Config.set('TicketOverview', { prio: 1000, parent: '', name: __('Overviews'), target: '#ticket/view', key: 'TicketOverview', permission: ['ticket.agent', 'ticket.customer'], class: 'overviews' }, 'NavBar')
