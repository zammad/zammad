class App.TicketMerge extends App.ControllerModal
  @include App.TicketNumberInput

  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: __('Merge')
  veryLarge: true
  shown: false

  constructor: ->
    super
    @fetch()

  fetch: ->
    @ajax(
      id:    'ticket_related'
      type:  'GET'
      url:   "#{@apiPath}/ticket_related/#{@ticket.id}"
      processData: true
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @ticket_ids_by_customer    = data.ticket_ids_by_customer
        @ticket_ids_recent_viewed  = data.ticket_ids_recent_viewed
        @render()
    )

  onShown: (e) =>
    super
    later = =>
      if @tableCustomerTickets
        @tableCustomerTickets.show()
      if @tableRecentViewedTickets
        @tableRecentViewedTickets.show()
    @delay(later, 300)

  content: =>
    content = $( App.view('agent_ticket_merge')() )

    @tableCustomerTickets = new App.TicketList(
      tableId:    'ticket-merge-customer-tickets'
      el:         content.find('#ticket-merge-customer-tickets')
      ticket_ids: @ticket_ids_by_customer
      radio:      true
    )

    @tableRecentViewedTickets = new App.TicketList(
      tableId:    'ticket-merge-recent-tickets'
      el:         content.find('#ticket-merge-recent-tickets')
      ticket_ids: @ticket_ids_recent_viewed
      radio:      true
    )

    @removeTicketSelectionOnFocus(content, 'target_ticket_number')
    @stripTicketHookOnPaste(content, 'target_ticket_number')
    @updateTicketNumberOnRadioClick(content, 'target_ticket_number')

    content

  onSubmit: (e) =>
    @formDisable(e)
    params = @formParam(e.target)

    if !params.target_ticket_number
      alert(App.i18n.translateInline('%s required!', App.Config.get('ticket_hook')))
      @formEnable(e)
      return

    # merge tickets
    @ajax(
      id:    'ticket_merge'
      type:  'PUT'
      url:   "#{@apiPath}/ticket_merge/#{@ticket.id}/#{params.target_ticket_number}"
      processData: true,
      success: (data, status, xhr) =>

        if data['result'] is 'success'

          # update collection
          App.Collection.load(type: 'Ticket', data: [data.target_ticket])
          App.Collection.load(type: 'Ticket', data: [data.source_ticket])

          # hide dialog
          @close()

          # view ticket
          @log 'notice', 'nav...', App.Ticket.find(data.target_ticket['id'])
          @navigate '#ticket/zoom/' + data.target_ticket['id']

          # notify UI
          @notify
            type:    'success'
            msg:     App.i18n.translateContent('Ticket %s merged.', data.source_ticket['number'])
            timeout: 4000

          App.TaskManager.remove("Ticket-#{data.source_ticket['id']}")

        else

          # notify UI
          @notify
            type:    'error'
            msg:     App.i18n.translateContent(data['message'])
            timeout: 6000
          @formEnable(e)

      error: (data) =>
        details = data.responseJSON || {}
        @notify
          type:    'error'
          msg:     App.i18n.translateContent(details.error_human || details.error || __('The tickets could not be merged.'))
          timeout: 6000
        @formEnable(e)
    )
