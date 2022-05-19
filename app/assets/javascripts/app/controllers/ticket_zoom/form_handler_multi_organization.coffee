# in future this can be hopefully done by core workflow
# but for now as the ticket create form is split in different form objects
# this will be done by a handler
class App.TicketZoomFormHandlerMultiOrganization
  @run: (params, attribute, attributes, classname, form, ui) ->

    # for agents run handler on customer field
    return if attribute.name isnt 'customer_id' && ui.permissionCheck('ticket.agent')

    # for customers there is no customer field so run it on title field
    return if attribute.name isnt 'title' && ui.permissionCheck('ticket.customer') && !ui.permissionCheck('ticket.agent')

    organization_id = form.find('div[data-attribute-name=organization_id] .js-input')
    return if !organization_id

    if ui.permissionCheck('ticket.agent')
      customer = App.User.find(params.customer_id)
    else
      customer = App.Session.get()

    if customer && customer.organization_ids.length > 0
      ui.show('organization_id')
      ui.mandantory('organization_id')

      if customer.organization_id
        customer_organization = App.Organization.find(customer.organization_id)
        if customer_organization
          organization_id.get(0).selectValue(customer_organization.id, customer_organization.name)
    else
      ui.hide('organization_id', undefined, true)
      ui.optional('organization_id')

App.Config.set('200-MultiOrganization', App.TicketZoomFormHandlerMultiOrganization, 'TicketCreateFormHandler')
