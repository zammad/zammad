class App.TicketHistory extends App.GenericHistory
  constructor: ->
    super
    @fetch()

  fetch: ->

    # get data
    @ajax(
      id:    'ticket_history',
      type:  'GET',
      url:   @apiPath + '/ticket_history/' + @ticket_id,
      success: (data, status, xhr) =>

        # load collections
        App.Event.trigger 'loadAssets', data.assets

        # render page
        @render(data.history)
    )
