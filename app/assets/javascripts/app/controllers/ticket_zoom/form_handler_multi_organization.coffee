# in future this can be hopefully done by core workflow
# but for now as the ticket create form is split in different form objects
# this will be done by a handler
class App.TicketZoomFormHandlerMultiOrganization
  @run: (params, attribute, attributes, classname, form, ui) ->

    # for agents run handler on customer field
    return if attribute.name isnt 'customer_id' && ui.permissionCheck('ticket.agent')

    # for customers there is no customer field so run it on title field
    return if attribute.name isnt 'title' && ui.permissionCheck('ticket.customer') && !ui.permissionCheck('ticket.agent')

    organization_input = form.find('div[data-attribute-name=organization_id] .js-input')
    return if !organization_input

    if ui.permissionCheck('ticket.agent')
      customer = App.User.find(params.customer_id)
    else
      customer = App.Session.get()

    return if not customer?.organization_ids.length

    # Select current or default customer organization (#5347).
    organization_id =
      if params.organization_id and customer.isInOrganization(params.organization_id)
      then params.organization_id
      else customer.organization_id

    return if not organization_id

    customer_organization = App.Organization.find(organization_id)
    return if not customer_organization

    organization_input.get(0).selectValue(customer_organization.id, customer_organization.name)

App.Config.set('200-MultiOrganization', App.TicketZoomFormHandlerMultiOrganization, 'TicketCreateFormHandler')
