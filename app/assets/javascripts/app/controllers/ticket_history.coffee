class App.TicketHistory extends App.GenericHistory
  fetch: =>
    @ajax(
      id:    'ticket_history'
      type:  'GET'
      url:   "#{@apiPath}/ticket_history/#{@ticket_id}"
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @items = data.history
        @render()
    )
