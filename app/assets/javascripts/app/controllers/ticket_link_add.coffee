class App.TicketLinkAdd extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: 'Link'
  shown: false

  constructor: ->
    super
    @fetch()

  url: ->
    if @object instanceof App.Ticket
      "#{@apiPath}/ticket_related/#{@object.id}"
    else
      @apiPath + '/ticket_recent'

  fetch: =>
    @ajax(
      id:          'ticket_related'
      type:        'GET'
      url:         @url()
      processData: true
      success:     (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)

        @ticketIdsByCustomer    = data.ticket_ids_by_customer
        @ticketIdsRecentViewed  = data.ticket_ids_recent_viewed
        @render()
    )

  content: =>
    content = $( App.view('link/ticket/add')(
      link_object:     @link_object
      link_object_id:  @link_object_id
      link_types:      @link_types
      object:          @object
      hasByCustomer:   (@ticketIdsByCustomer isnt undefined)
      hasRecentViewed: (@ticketIdsRecentViewed isnt undefined)
    ))

    if @ticketIdsByCustomer
      @buildContentTable(content, @ticketIdsByCustomer, 'ticket-merge-customer-tickets')

    if @ticketIdsRecentViewed
      @buildContentTable(content, @ticketIdsRecentViewed, 'ticket-merge-recent-tickets')

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

  buildContentTable: (container, ticket_ids, tableId) ->
    if @object instanceof App.Ticket
      ticket_ids = ticket_ids.filter (elem) => elem != @object.id

    new App.TicketList(
      tableId:    tableId
      el:         container.find("##{tableId}")
      ticket_ids: ticket_ids
      radio:      true
    )


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
      type:  'POST'
      url:   "#{@apiPath}/links/add"
      data: JSON.stringify
        link_type:                params['link_type']
        link_object_target:       @link_object
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
