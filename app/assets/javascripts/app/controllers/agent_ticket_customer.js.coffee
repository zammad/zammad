class App.TicketCustomer extends App.ControllerModal
  constructor: ->
    super
    @render()

  render: -> 
    configure_attributes = [
#      { name: 'customer_id', display: 'Customer', tag: 'autocompletion', type: 'text', limit: 100, null: false, relation: 'User', class: 'span7', autocapitalize: false, help: 'Select the customer of the Ticket or create one.', link: '<a href="" class="customer_new">&raquo;</a>', callback: @userInfo },
      { name: 'customer_id', display: 'Customer', tag: 'autocompletion', type: 'text', limit: 100, null: false, relation: 'User', class: 'span5', autocapitalize: false, help: 'Select the new customer of the Ticket.', },
    ]

    @html App.view('agent_ticket_customer')()

    new App.ControllerForm(
      el: @el.find('#form-customer'),
      model: {
        configure_attributes: configure_attributes,
        className:            'update',
      },
      autofocus: true,
    )
    @modalShow()

  submit: (e) =>
    e.preventDefault()

    params = @formParam(e.target)

    # update ticket
    ticket = App.Ticket.find(@ticket_id)
    ticket.updateAttributes(
      customer_id: params['customer_id']
    )

    # close modal
    @modalHide()

    # reload zoom view
    @zoom.render()
