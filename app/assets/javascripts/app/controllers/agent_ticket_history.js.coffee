class App.TicketHistory extends App.ControllerModal
  constructor: ->
    super
    @fetch(@ticket_id)

  fetch: (@ticket_id) ->
    # get data
    App.Com.ajax(
      id:    'ticket_history',
      type:  'GET',
      url:   '/ticket_history/' + ticket_id,
      success: (data, status, xhr) =>
        # remember ticket
        @ticket = data.ticket

        # load user collection
        @loadCollection( type: 'User', data: data.users )

        # load ticket collection
        @loadCollection( type: 'Ticket', data: [data.ticket] )

        # load history_type collections
        @loadCollection( type: 'HistoryType', data: data.history_types )

        # load history_object collections
        @loadCollection( type: 'HistoryObject', data: data.history_objects )

        # load history_attributes collections
        @loadCollection( type: 'HistoryAttribute', data: data.history_attributes )

        # load history collections
        App.History.deleteAll()
        @loadCollection( type: 'History', data: data.history )

        # render page
        @render()
    )

  render: ->

    # create table/overview
    table = @table(
      overview_extended: [
        { name: 'history_type', },
        { name: 'history_attribute', },
        { name: 'value_from', },
        { name: 'value_to', },
        { name: 'created_by', class: 'user-data', data: { id: 1 } },
        { name: 'created_at', callback: @humanTime },
      ],
      model: App.History,
      objects: App.History.all(),
    )

    @html App.view('agent_ticket_history')()
    @el.find('.table_history').append(table)

    @modalShow()
    
    @userPopups()
