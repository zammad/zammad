class App.UserTicketPopoverProvider extends App.PopoverProvider
  @templateName = 'user_ticket_list'

  fetch: (buildParams) ->
    @params.parentController.ajax(
      type:  'GET'
      url:   "#{App.Config.get('api_path')}/ticket_customer"
      data:
        customer_id: buildParams.user_id
      processData: true
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)

        ticketsList = { open: data.ticket_ids_open, closed: data.ticket_ids_closed }
        @callback(ticketsList: ticketsList, selector: buildParams.selector)
    )

  build: (buildParams) ->
    return if !@checkPermissions()
    @fetch(buildParams)

  callback: (supplementaryData) ->
    @clear(@popovers)
    @popovers = @buildPopovers(supplementaryData)

  buildTitleFor: (elem) ->
    $(elem).find('[title="*"]').val()

  buildContentFor: (elem, supplementaryData) ->
    type = $(elem).filter('[data-type]').data('type')
    ticket_ids = supplementaryData.ticketsList[type] || []

    tickets = ticket_ids.map (ticketId) -> App.Ticket.fullLocal(ticketId)

    # insert data
    @buildHtmlContent(tickets: tickets)

