class App.TicketMerge extends App.ControllerModal
  constructor: ->
    super
    @render()

  render: -> 
    @html App.view('agent_ticket_merge')()
    @modalShow()

  submit: (e) =>
    e.preventDefault()

    params = @formParam(e.target)

    # merge tickets
    App.Com.ajax(
      id:    'ticket_merge',
      type:  'GET',
      url:   '/api/ticket_merge/' + @ticket_id + '/' + params['master_ticket_number'],
      data:  {
#        view: @view
      }
      processData: true,
      success: (data, status, xhr) =>

        if data['result'] is 'success'

          # update collection
          App.Collection.load( type: 'Ticket', data: [data.master_ticket] )
          App.Collection.load( type: 'Ticket', data: [data.slave_ticket] )

          # hide dialog
          @modalHide()

          # view ticket
          @log 'nav...', App.Collection.find( 'Ticket', data.master_ticket['id'] )
          @navigate '#ticket/zoom/' + data.master_ticket['id']

          # notify UI
          @notify
            type:    'success',
            msg:     T( 'Ticket %s merged!', data.slave_ticket['number'] ),
            timeout: 6000,

        else

          # notify UI
          @notify
            type:    'error',
            msg:     T( data['message'] ),
            timeout: 6000,
#      error: =>
    )
    
