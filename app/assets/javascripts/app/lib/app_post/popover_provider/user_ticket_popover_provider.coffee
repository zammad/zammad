class UserTicket extends App.PopoverProviderAjax
  @templateName = 'user_ticket_list'

  fetch: (event, elem) ->
    @params.parentController.ajax(
      type:  'GET'
      url:   "#{App.Config.get('api_path')}/ticket_customer"
      data:
        customer_id: @buildParams.user_id
      processData: true
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)

        ticketList = { open: data.ticket_ids_open, closed: data.ticket_ids_closed }
        html       = @buildContentFor(elem, { ticketList: ticketList, selector: @buildParams.selector })

        @replaceOnShow(event, html[0].outerHTML)
    )

  build: (buildParams) ->
    return if !@checkPermissions()
    @buildParams = buildParams
    @popovers    = @buildPopovers(ticketList: {}, selector: buildParams.selector)

  buildContentFor: (elem, supplementaryData) ->
    return super if _.isEmpty(supplementaryData.ticketList)

    type = $(elem).filter('[data-type]').data('type')
    ticket_ids = supplementaryData.ticketList[type] || []

    tickets = ticket_ids.map (ticketId) -> App.Ticket.fullLocal(ticketId)
    @buildHtmlContent(
      ticketList: App.view('generic/ticket_list')(
        tickets: tickets
        show_id: true
      )
    )

App.PopoverProvider.registerProvider('UserTicket', UserTicket)
