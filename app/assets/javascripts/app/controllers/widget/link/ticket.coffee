class App.WidgetLink.Ticket extends App.WidgetLink
  @registerPopovers 'Ticket'

  render: =>
    return if @lastLocalLinks && _.isEqual(@lastLocalLinks, @localLinks)
    @lastLocalLinks = _.clone(@localLinks)

    list = {}

    for item in @localLinks
      if !list[ item['link_type'] ]
        list[ item['link_type'] ] = {
          tickets: []
        }

      if item['link_object'] is 'Ticket'
        ticket = App.Ticket.fullLocal( item['link_object_value'] )
        if ticket.state.name is 'merged'
          ticket.css = 'merged'
        list[ item['link_type'] ].tickets.push ticket

    # create ticket lists
    for type of list
      list[type].ticketList = App.view('generic/ticket_list')(
        tickets: list[type].tickets
        object: 'Ticket'
        linkType: type
      ) unless list[type].tickets.length == 0

    # insert data
    @html App.view('link/ticket/list')(
      links: list
    )

    @renderPopovers()

  add: (e) =>
    e.preventDefault()
    new App.TicketLinkAdd(
      link_object:    @object_type
      link_object_id: @object.id
      link_types:     [['normal', 'Normal'], ['child', 'Child'], ['parent', 'Parent']]
      object:         @object
      parent:         @
      container:      @el.closest('.content')
    )
