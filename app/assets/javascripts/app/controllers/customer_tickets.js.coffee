$ = jQuery.sub()

class Index extends App.Controller
#  events:
#    'submit form':         'submit',
#    'click .submit':       'submit',
#    'click .cancel':       'cancel',

  constructor: (params) ->
    super

    # check authentication
    return if !@authenticate()

    # set title
    @title 'My Tickets'
#    @fetch(params)
    @navupdate '#customer_tickets'

    @render()

  render: ->

    @html App.view('agent_ticket_view')(
      head: 'My Ticket',
#      form: @formGen( model: { configure_attributes: configure_attributes, className: 'create' } ),
    )

App.Config.set( 'customer_tickets', Index, 'Routes' )

#App.Config.set( 'CustomerTickets', { prio: 1700, parent: '', name: 'My Tickets', target: '#ticket_view/my_tickets', role: ['Customer'] }, 'NavBar' )
