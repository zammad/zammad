class App.TicketList extends App.Controller
  @extend App.PopoverProvidable
  @registerPopovers 'Organization', 'User'
  orderBy: null
  orderDirection: null
  pagerEnabled: false
  orderEnabled: false
  pagerAjax:    false

  constructor: ->
    super
    @render()

  show: =>
    if @table
      @table.show()

  hide: =>
    if @table
      @table.hide()

  render: =>

    openTicket = (id,e) =>
      ticket = App.Ticket.findNative(id)
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
      attribute.class  = object.iconClass()
      attribute.link   = ''
      attribute.title  = object.iconTitle()
      value

    callbackIconPriorityHeader = (headers) ->
      attribute =
        name:         'icon_priority'
        display:      ''
        translation:  false
        width:        '22px'
        displayWidth: 22
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

    if App.Config.get('ui_ticket_priority_icons') == true
      callbackHeader = [ callbackIconHeader, callbackIconPriorityHeader ]
      callbackAttributes.icon_priority = [ callbackIconPriority ]

    list = []
    for ticket_id in @ticket_ids
      ticketItem = App.Ticket.fullLocal(ticket_id)
      list.push ticketItem
    @el.html('')
    @table = new App.ControllerTable(
      tableId:  @tableId
      el:       @el
      overview: @columns || [ 'number', 'title', 'customer', 'group', 'created_at' ]
      model:    App.Ticket
      objects:  list
      checkbox: @checkbox
      #bindRow:
      #  events:
      #    'click': openTicket
      orderBy:        @orderBy
      orderDirection: @orderDirection
      callbackHeader: callbackHeader
      callbackAttributes: callbackAttributes
      bindCheckbox: @bindCheckbox
      radio: @radio
      sortClickCallback: @sortClickCallback
      pagerEnabled: @pagerEnabled
      orderEnabled: @orderEnabled
      pagerAjax: @pagerAjax
    )

    @renderPopovers()
