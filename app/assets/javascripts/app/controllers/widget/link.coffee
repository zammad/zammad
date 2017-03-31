class App.WidgetLink extends App.Controller
  events:
    'click .js-add': 'add'
    'click .js-delete': 'delete'
    'click .js-delete .icon': 'delete'

  constructor: ->
    super

    # if links are given, do not init fetch
    if @links
      @localLinks = _.clone(@links)
      @render()
      return

    @fetch()

  fetch: =>
    # fetch item on demand
    # get data
    @ajax(
      id:   "links_#{@object.id}_#{@object_type}"
      type: 'GET'
      url:  "#{@apiPath}/links"
      data:
        link_object:       @object_type
        link_object_value: @object.id
      processData: true
      success: (data, status, xhr) =>
        @localLinks = data.links
        App.Collection.loadAssets(data.assets)
        @render()
    )

  reload: (links) =>
    @localLinks = _.clone(links)
    @render()

  render: =>
    return if @lastLocalLinks && _.isEqual(@lastLocalLinks, @localLinks)
    @lastLocalLinks = _.clone(@localLinks)
    list = {}
    for item in @localLinks
      if !list[ item['link_type'] ]
        list[ item['link_type'] ] = []

      if item['link_object'] is 'Ticket'
        ticket = App.Ticket.fullLocal( item['link_object_value'] )
        if ticket.state.name is 'merged'
          ticket.css = 'merged'
        list[ item['link_type'] ].push ticket

    # insert data
    @html App.view('link/info')(
      links: list
    )
    @ticketPopups('left')

  delete: (e) =>
    e.preventDefault()
    link_type   = $(e.currentTarget).data('link-type')
    link_object_source = $(e.currentTarget).data('object')
    link_object_source_value = $(e.currentTarget).data('object-id')
    link_object_target = @object_type
    link_object_target_value = @object.id

    # get data
    @ajax(
      id:   "links_remove_#{@object.id}_#{@object_type}"
      type: 'GET'
      url:  "#{@apiPath}/links/remove"
      data:
        link_type:                link_type
        link_object_source:       link_object_source
        link_object_source_value: link_object_source_value
        link_object_target:       link_object_target
        link_object_target_value: link_object_target_value
      processData: true
      success: (data, status, xhr) =>
        @fetch()
    )

  add: (e) =>
    e.preventDefault()
    new App.LinkAdd(
      link_object:    @object_type
      link_object_id: @object.id
      object:         @object
      parent:         @
      container:      @el.closest('.content')
    )

class App.LinkAdd extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: 'Link'
  shown: false

  constructor: ->
    super
    @ticket = @object
    @fetch()

  fetch: =>
    @ajax(
      id:    'ticket_related'
      type:  'GET'
      url:   "#{@apiPath}/ticket_related/#{@ticket.id}"
      processData: true
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @ticketIdsByCustomer    = data.ticket_ids_by_customer
        @ticketIdsRecentViewed  = data.ticket_ids_recent_viewed
        @render()
    )

  content: =>
    content = $( App.view('link/add')(
      link_object:    @link_object
      link_object_id: @link_object_id
      object:         @object
    ))

    ticketIdsByCustomer = []
    for ticket_id in @ticketIdsByCustomer
      if ticket_id isnt @ticket.id
        ticketIdsByCustomer.push ticket_id
    new App.TicketList(
      tableId:    'ticket-merge-customer-tickets'
      el:         content.find('#ticket-merge-customer-tickets')
      ticket_ids: ticketIdsByCustomer
      radio:      true
    )

    ticketIdsByRecentView = []
    for ticket_id in @ticketIdsRecentViewed
      if ticket_id isnt @ticket.id
        ticketIdsByRecentView.push ticket_id
    new App.TicketList(
      tableId:    'ticket-merge-recent-tickets'
      el:         content.find('#ticket-merge-recent-tickets')
      ticket_ids: ticketIdsByRecentView
      radio:      true
    )

    content.delegate('[name="ticket_number"]', 'focus', (e) ->
      $(e.target).parents().find('[name="radio"]').prop('checked', false)
    )

    content.delegate('[name="radio"]', 'click', (e) ->
      if $(e.target).prop('checked')
        ticket_id = $(e.target).val()
        ticket    = App.Ticket.fullLocal( ticket_id )
        $(e.target).parents().find('[name="ticket_number"]').val(ticket.number)
    )
    content

  onSubmit: (e) =>
    params = @formParam(e.target)

    if !params['ticket_number']
      alert('Ticket# is needed!')
      return
    if !params['link_type']
      alert('Link type is needed!')
      return

    # get data
    @ajax(
      id:    "links_add_#{@object.id}_#{@object_type}"
      type:  'GET'
      url:   "#{@apiPath}/links/add"
      data:
        link_type:                params['link_type']
        link_object_target:       'Ticket'
        link_object_target_value: @object.id
        link_object_source:       'Ticket'
        link_object_source_number: params['ticket_number']
      processData: true
      success: (data, status, xhr) =>
        @close()
        @parent.fetch()
      error: (xhr, statusText, error) =>
        detailsRaw = xhr.responseText
        details = {}
        if !_.isEmpty(detailsRaw)
          details = JSON.parse(detailsRaw)
        @notify(
          type:      'error'
          msg:       App.i18n.translateContent(details.error)
          removeAll: true
        )
    )
