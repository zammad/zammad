class App.TicketCustomer extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: 'Change Customer'

  content: ->
    configure_attributes = [
      { name: 'customer_id', display: 'Customer', tag: 'user_autocompletion', null: false, placeholder: 'Enter Person or Organization/Company', minLengt: 2, disableCreateObject: false },
    ]
    controller = new App.ControllerForm(
      model:
        configure_attributes: configure_attributes,
      autofocus: true
    )
    controller.form

  onSubmit: (e) =>
    params = @formParam(e.target)

    ticket = App.Ticket.find(@ticket_id)
    ticket.customer_id = params['customer_id']
    errors = ticket.validate()

    if !_.isEmpty(errors)
      @log 'error', errors
      @formValidate(
        form:   e.target
        errors: errors
      )
      return

    @customer_id = params['customer_id']
    callback = =>

      # close modal
      @close()

      # update ticket
      ticket = App.Ticket.find(@ticket_id)
      ticket.article = undefined
      ticket.updateAttributes(
        customer_id: @customer_id
      )

    # load user if not already exists
    App.User.full(@customer_id, callback)
