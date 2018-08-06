class OwnerFormHandlerDependencies

  # central method, is getting called on every ticket form change
  @run: (params, attribute, attributes, classname, form, ui) ->
    return if 'group_id' not of params || 'owner_id' not of params

    owner_attribute = _.find(attributes, (o) -> o.name == 'owner_id')
    return if !owner_attribute
    return if 'alt_options' not of owner_attribute

    if !params.group_id
      # if no group is chosen, then we use the alt_options to populate the owner_id field
      owner_attribute.options = owner_attribute.alt_options
      delete owner_attribute['relation']
    else
      # if a group is chosen, then populate owner_id using attribute.relation
      owner_attribute.relation = 'User'
      delete owner_attribute['options']

    # replace new option list
    owner_attribute.default = params[owner_attribute.name]
    owner_attribute.newValue = params[owner_attribute.name]
    newElement = ui.formGenItem(owner_attribute, classname, form)
    form.find('select[name="owner_id"]').closest('.form-group').replaceWith(newElement)

App.Config.set('150-ticketFormChanges', OwnerFormHandlerDependencies, 'TicketZoomFormHandler')