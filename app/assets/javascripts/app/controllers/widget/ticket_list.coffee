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

    callbackIconHeader = (headers) ->
      attribute =
        name:        'icon'
        display:     ''
        translation: false
        width:       '28px'
        displayWidth:28
        unresizable: true
      headers.unshift(0)
      headers[0] = attribute
      headers
    callbackIcon = (value, object, attribute, header, refObject) ->
      value = ' '
      attribute.class  = object.iconClass()
      attribute.link   = ''
      attribute.title  = object.iconTitle()
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
