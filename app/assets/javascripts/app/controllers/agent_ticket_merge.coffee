class App.TicketMerge extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: 'Merge'
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

    content.delegate('[name="master_ticket_number"]', 'focus', (e) ->
      $(e.target).parents().find('[name="radio"]').prop('checked', false)
    )

    content.delegate('[name="radio"]', 'click', (e) ->
      if $(e.target).prop('checked')
        ticket_id = $(e.target).val()
        ticket    = App.Ticket.fullLocal(ticket_id)
        $(e.target).parents().find('[name="master_ticket_number"]').val(ticket.number)
    )

    content

  onSubmit: (e) =>
    @formDisable(e)
    params = @formParam(e.target)

    if !params.master_ticket_number
      alert(App.i18n.translateInline('%s required!', 'Ticket#'))
      @formEnable(e)
      return

    # merge tickets
    @ajax(
      id:    'ticket_merge'
      type:  'PUT'
      url:   "#{@apiPath}/ticket_merge/#{@ticket.id}/#{params.master_ticket_number}"
      processData: true,
      success: (data, status, xhr) =>

        if data['result'] is 'success'

          # update collection
          App.Collection.load(type: 'Ticket', data: [data.master_ticket])
          App.Collection.load(type: 'Ticket', data: [data.slave_ticket])

          # hide dialog
          @close()

          # view ticket
          @log 'notice', 'nav...', App.Ticket.find(data.master_ticket['id'])
          @navigate '#ticket/zoom/' + data.master_ticket['id']

          # notify UI
          @notify
            type:    'success'
            msg:     App.i18n.translateContent('Ticket %s merged!', data.slave_ticket['number'])
            timeout: 4000

          App.TaskManager.remove("Ticket-#{data.slave_ticket['id']}")

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
          msg:     App.i18n.translateContent(details.error_human || details.error || 'Unable to merge!')
          timeout: 6000
        @formEnable(e)
    )
