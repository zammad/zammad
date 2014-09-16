class App.TicketCustomer extends App.ControllerModal
  constructor: ->
    super
    configure_attributes = [
      { name: 'customer_id', display: 'Customer', tag: 'autocompletion', type: 'text', limit: 100, null: false, relation: 'User', class: 'span5', autocapitalize: false, help: 'Select the new customer of the Ticket.', source: @apiPath + '/users/search', minLengt: 2 },
    ]

    controller = new App.ControllerForm(
      model: {
        configure_attributes: configure_attributes,
        className:            'update',
      },
      autofocus: true,
    )
    @head   = 'Change Customer'
    @close  = true
    @cancel = true
    @button = true
    @show( controller.form )

  onSubmit: (e) =>
    e.preventDefault()

    params = @formParam(e.target)

    @customer_id = params['customer_id']

    callback = =>

      # close modal
      @hide()

      # update ticket
      @ticket.updateAttributes(
        customer_id: @customer_id
      )

    # load user if not already exists
    App.User.full( @customer_id, callback )
