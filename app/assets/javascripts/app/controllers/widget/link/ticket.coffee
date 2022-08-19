class App.WidgetLink.Ticket extends App.WidgetLink
  @registerPopovers 'Ticket'

  subscribeTicket: (ticket) =>
    @ticketSubscriberIDs ||= {}
    return if @ticketSubscriberIDs[ticket.id]

    handler = ticket.subscribe(=>
      @render(true)
    )
    @ticketSubscriberIDs[ticket.id] = handler

  unsubscribeTickets: =>
    return if !@ticketSubscriberIDs

    for id, handler of @ticketSubscriberIDs
      ticket = App.Ticket.find(id)
      continue if !ticket
      ticket.unsubscribe(handler)

    @ticketSubscriberIDs = {}

  render: (force = false) =>
    return if !force && @lastLocalLinks && _.isEqual(@lastLocalLinks, @localLinks)
    @lastLocalLinks = _.clone(@localLinks)

    @unsubscribeTickets()

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
        @subscribeTicket(ticket)

    # create ticket lists
    for type of list
      list[type].ticketList = App.view('generic/ticket_list')(
        tickets: list[type].tickets
        object: 'Ticket'
        linkType: type
        editable: @editable
      ) unless list[type].tickets.length == 0

    # insert data
    @html App.view('link/ticket/list')(
      links: list
      editable: @editable
    )

    @renderPopovers()

  add: (e) =>
    e.preventDefault()
    new App.TicketLinkAdd(
      link_object:    @object_type
      link_object_id: @object.id
      link_types:     [['normal', __('Normal')], ['child', __('Child')], ['parent', __('Parent')]]
      object:         @object
      parent:         @
      container:      @el.closest('.content')
    )

  release: =>
    super
    @unsubscribeTickets()
