class TicketZoomHookRouter extends App.ControllerPermanent
  requiredPermission: ['ticket.agent', 'ticket.customer']
  constructor: (params) ->
    super

    target_ticket = App.Ticket.findByAttribute('number', params.ticket_number);

    if (target_ticket)
      window.location.replace(target_ticket.uiUrl())
    else
      App.Ajax.request(
        type:  'GET'
        url:   "#{@apiPath}/search"
        data:
          query: ''
          condition: [{ 'ticket.number': { operator: 'is', value: params.ticket_number } }]
          limit: 1
        processData: true
        success: (data, status, xhr) =>
          for item in data.result
            continue if item.type isnt 'Ticket'
            App.Collection.loadAssets(data.assets)
            target_ticket = App.Ticket.findNative(item.id)
            if (target_ticket)
              window.location.replace(target_ticket.uiUrl())
            return
          window.location.replace('#ticket/zoom/0')
        error: =>
          window.location.replace('#ticket/zoom/0')
      )

App.Config.set('ticket/number/:ticket_number', TicketZoomHookRouter, 'Routes')
