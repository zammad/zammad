class App.TicketMerge extends App.ControllerModal
  constructor: ->
    super
    @render()

  render: -> 
    @html App.view('agent_ticket_merge')(
#      head: 'New User',
#      form: @formGen( model: App.User, required: 'quick' ),
    )
    @log '123123123'
    @modalShow()

  submit: (e) =>
    e.preventDefault()
    
    params = @formParam(e.target)
    
    # merge tickets
    @ajax = new App.Ajax
    @ajax.ajax(
      type:  'GET',
      url:   '/ticket_merge/' + @ticket_id + '/' + params['master_ticket_number'],
      data:  {
#        view: @view
      }
      processData: true,
      success: (data, status, xhr) =>
      
        if data['result'] is 'success'
          @loadCollection( type: 'Ticket', data: [data.master_ticket] )
          @loadCollection( type: 'Ticket', data: [data.slave_ticket] )

          @modalHide()

          # view ticket
          @log 'nav...', App.Ticket.find( data.master_ticket['id'] )
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
    
