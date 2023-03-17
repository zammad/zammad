class App.TicketCustomer extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: __('Change Customer')

  content: ->
    configure_attributes = [
      { name: 'customer_id', display: __('Customer'), tag: 'user_autocompletion', null: false, placeholder: __('Enter Person or Organization/Company'), minLengt: 2, disableCreateObject: false },
      { name: 'organization_id', display: __('Organization'), tag: 'autocompletion_ajax_customer_organization', multiple: false, null: false, relation: 'Organization', autocapitalize: false, translate: false },
    ]
    @controller = new App.ControllerForm(
      model:
        configure_attributes: configure_attributes,
      autofocus:      true,
      handlersConfig: [App.TicketZoomFormHandlerMultiOrganization],
    )
    @controller.form

  onSubmit: (e) =>
    params = @formParam(e.target)

    ticket                 = App.Ticket.find(@ticket_id)
    ticket.customer_id     = params['customer_id']
    ticket.organization_id = params['organization_id']

    errors = ticket.validate(
      controllerForm: @controller
    )

    if !_.isEmpty(errors)
      @log 'error', errors
      @formValidate(
        form:   e.target
        errors: errors
      )
      return

    @customer_id     = params['customer_id']
    @organization_id = params['organization_id']

    callback = =>

      # close modal
      @close()

      # update ticket
      ticket = App.Ticket.find(@ticket_id)
      ticket.article = undefined
      ticket.updateAttributes(
        customer_id: @customer_id
        organization_id: @organization_id
      )

    # load user if not already exists
    App.User.full(@customer_id, callback)
    if @organization_id
      App.Organization.full(@organization_id, callback)
