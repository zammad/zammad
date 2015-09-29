class App.TicketList extends App.Controller
  constructor: ->
    super

    @render()

  render: =>

    callbackTicketTitleAdd = (value, object, attribute, attributes, refObject) ->
      attribute.title = object.title
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

    list = []
    for ticket_id in @ticket_ids
      ticketItem = App.Ticket.fullLocal( ticket_id )
      list.push ticketItem
    @el.html('')
    new App.ControllerTable(
      el:       @el
      overview: [ 'number', 'title', 'customer', 'group', 'created_at' ]
      model:    App.Ticket
      objects:  list
      callbackHeader: [ callbackIconHeader ]
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
          [ callbackTicketTitleAdd ]
      radio: @radio
    )

    # start user popups
    @userPopups()

    # start organization popups
    @organizationPopups()
